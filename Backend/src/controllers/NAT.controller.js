const NatRule = require('../models/NATrules');
const firewallAgent = require('../services/firewallAgent');
const logger = require('../utils/logger');
const { validateIpFields, firewallError } = require('../utils/firewall.helpers');


// Add a NAT rule (Masquerade, SNAT, DNAT)
// POST /api/firewall/nat
exports.addNatRule = async (req, res) => {
    try {
        const {
            type, sourceIp, outputInterface,
            newSourceIp, protocol, inputInterface,
            destinationIp, externalPort, internalPort
        } = req.body;

        // 1. Validate the provided IP addresses
        const ipsCheck = validateIpFields([
            ['Source IP', sourceIp],
            ['New Source IP', newSourceIp],
            ['Destination IP', destinationIp]
        ]);

        if (!ipsCheck.valid) {
            return res.status(400).json({
                success: false,
                message: ipsCheck.message
            });
        }


        // 2. Send the simple payload to the Python script
        const payload = {
            type,
            sourceIp,
            outputInterface,
            newSourceIp,
            protocol,
            inputInterface,
            destinationIp,
            externalPort,
            internalPort
        };

        const firewallResponse = await firewallAgent.post('/api/nat', payload);
        //ask esraa about family field
        // 3. Receive the complete data from the Python "contract"
        const { handle_id, family, table_name, chain_name } = firewallResponse.data;

        // 4. Save to MongoDB with all details for future deletion
        const newNatRule = await NatRule.create({
            type,
            handleId: handle_id,
            tableName: table_name,
            chainName: chain_name,
            sourceIp: sourceIp,
            outputInterface: outputInterface,
            newSourceIp: newSourceIp,
            inputInterface: inputInterface,
            protocol: protocol,
            destinationIp: destinationIp,
            externalPort: externalPort,
            internalPort: internalPort,
            createdBy: req.user._id // Ensure the auth middleware attaches the user object
        });

        return res.status(201).json({
            success: true,
            message: "NAT rule applied and saved successfully",
            data: newNatRule
        });

    } catch (error) {
       return firewallError(res, error, "Failed to add NAT rule");
    }
};
//GET /api/firewall/nat
exports.getNatRules = async (req, res) => {
    try {
        const page  = Math.max(1, parseInt(req.query.page)  || 1);
        const limit = Math.min(100, parseInt(req.query.limit) || 20);
        const skip  = (page - 1) * limit;

        const [rules, total] = await Promise.all([
            NatRule.find().sort({ createdAt: -1 }).skip(skip).limit(limit),
            NatRule.countDocuments()
        ]);

        return res.status(200).json({
            success: true, total, page,
            totalPages: Math.ceil(total / limit),
            data: rules
        });
    } catch (error) {
        logger.error(`getNatRules error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};


//    DELETE /api/firewall/nat/:id
exports.deleteNatRule = async (req, res) => {
    try {
        const rule = await NatRule.findById(req.params.id);
        if (!rule) return res.status(404).json({ message: 'Rule not found in the database' });

        // Send delete request to Python using the saved handle and chain
        await firewallAgent.delete('/api/rules', {
            data: {
                family: 'ip',
                table_name: rule.tableName,
                chain_name: rule.chainName,
                handle_id: rule.handleId
            }
        });

        await rule.deleteOne();
        return res.status(200).json({ success: true, message: 'NAT rule deleted successfully' });

    } catch (error) {
        return firewallError(res, error);
    }
};