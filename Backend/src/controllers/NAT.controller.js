const axios = require('axios');
const net = require('net');
const NatRule = require('../models/NATrules');
const Table = require('../models/tables');

const FIREWALL_API_URL = process.env.FIREWALL_API_URL || 'http://127.0.0.1:5000';

// @desc    Add a NAT rule (Masquerade, SNAT, DNAT)
// @route   POST /api/firewall/nat
exports.addNatRule = async (req, res) => {
    try {
        const { 
            type, sourceIp, outputInterface, 
            newSourceIp, protocol, inputInterface, 
            destinationIp, externalPort, internalPort 
        } = req.body;

        // 1. Validate the provided IP addresses
        const ipsToCheck = [
            { name: 'Source IP', value: sourceIp },
            { name: 'New Source IP', value: newSourceIp },
            { name: 'Destination IP', value: destinationIp }
        ];

        for (let ipObj of ipsToCheck) {
            if (ipObj.value && ipObj.value.trim() !== '') {
                const ipPart = ipObj.value.split('/')[0];
                if (!net.isIPv4(ipPart)) {
                    return res.status(400).json({ 
                        success: false, 
                        message: `Invalid IP format for ${ipObj.name}` 
                    });
                }
            }
        }

        // 2. Send the simple payload to the Python script
        const payload = {
            type, sourceIp, outputInterface, 
            newSourceIp, protocol, inputInterface, 
            destinationIp, externalPort, internalPort
        };

        const firewallResponse = await axios.post(`${FIREWALL_API_URL}/api/nat`, payload);

        // 3. Receive the complete data from the Python "contract"
        const { handle_id, family, table_name, chain_name } = firewallResponse.data;

        // 4. Save to MongoDB with all details for future deletion
        const newNatRule = await NatRule.create({
            type,
            handleId: handle_id,
            tableName: table_name,
            chainName: chain_name,
            sourceIp,
            outputInterface,
            newSourceIp,
            inputInterface,
            protocol,
            destinationIp,
            externalPort,
            internalPort,
            createdBy: req.user._id // Ensure the auth middleware attaches the user object
        });

        res.status(201).json({
            success: true,
            message: "NAT rule applied and saved successfully",
            data: newNatRule
        });

    } catch (error) {
        console.error("NAT Error:", error.response ? error.response.data : error.message);
        res.status(500).json({
            success: false,
            message: "Failed to apply NAT rule to the firewall",
            details: error.response ? error.response.data : error.message
        });
    }
};

// @desc    Delete a NAT rule using handle_id
// @route   DELETE /api/firewall/nat/:id
exports.deleteNatRule = async (req, res) => {
    try {
        const rule = await NatRule.findById(req.params.id);
        if (!rule) return res.status(404).json({ message: 'Rule not found in the database' });

        // Send delete request to Python using the saved handle and chain
        await axios.delete(`${FIREWALL_API_URL}/api/rules`, {
            data: {
                family: 'ip',
                table_name: rule.tableName,
                chain_name: rule.chainName,
                handle_id: rule.handleId
            }
        });

        await rule.deleteOne();
        res.status(200).json({ success: true, message: 'NAT rule deleted successfully' });

    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to delete rule from the firewall" });
    }
};