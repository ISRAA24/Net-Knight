const NatRule = require('../models/NATrules');
const firewallAgent = require('../config/firewallAgent');
const logger = require('../utils/logger');
const { validateIpFields, firewallError } = require('../utils/firewall.helpers');
const { logActivity } = require('../utils/activityLogger');


const buildPythonPayload = (data, finalComment) => {
    const payload = { nat_type: data.nat_type, comment: finalComment };

    if (data.nat_type === 'masquerade') {

        if (data.source_ip) payload.source_ip = data.source_ip;
        payload.output_interface = data.output_interface || data.network_interface;

    } else if (data.nat_type === 'source') {
        payload.source_ip = data.source_ip;
        payload.new_source_ip = data.new_source_ip;
        payload.output_interface = data.output_interface || data.network_interface;

    } else if (data.nat_type === 'destination') {
        payload.input_interface = data.input_interface || data.network_interface;
        payload.dest_ip = data.dest_ip;
        payload.int_port = data.int_port;
        payload.protocol = data.protocol || 'tcp';
        payload.ext_port = data.ext_port;
    }
    return payload;
};
// Add a NAT rule (Masquerade, SNAT, DNAT)
// POST /api/firewall/nat
exports.addNatRule = async (req, res) => {
    try {

        const finalComment = `nat_${Date.now()}`;
        const data = req.body;
        const payload = buildPythonPayload(req.body, finalComment);
        let ipsToValidate = [];

        if (data.nat_type === 'masquerade') {

            if (data.source_ip) {
                ipsToValidate.push(['Source IP', data.source_ip]);
            }
        } else if (data.nat_type === 'source') {
            ipsToValidate.push(['Source IP', data.source_ip]);
            ipsToValidate.push(['New Source IP', data.new_source_ip]);
        } else if (data.nat_type === 'destination') {
            if (data.external_ip) ipsToValidate.push(['External IP', data.external_ip]);
            ipsToValidate.push(['Internal IP', data.internal_ip]);
        }

        if (ipsToValidate.length > 0) {
            const ipsCheck = validateIpFields(ipsToValidate);
            if (!ipsCheck.valid) {
                return res.status(400).json({
                    success: false,
                    message: ipsCheck.message
                });
            }
        }

        console.log("🚀 Sending to Firewall Agent:", JSON.stringify(payload, null, 2));

        const firewallResponse = await firewallAgent.post('/api/add_nat', payload);
        console.log("🔥 ERROR FROM PYTHON: ", firewallResponse.data);
        if (firewallResponse.data.status === "error" || !firewallResponse.data.handle) {
            return res.status(400).json({ success: false, message: "Firewall rejected NAT rule", details: firewallResponse.data.output, python_error: firewallResponse.data });
        }


        const newNat = await NatRule.create({
            ...req.body,
            handleId: firewallResponse.data.handle,
            comment: finalComment,
            createdBy: req.user._id
        });


        await logActivity(
            req.user._id,
            req.user.username,
            `Add ${req.body.nat_type.toUpperCase()} NAT`,
            `Handle: ${newNat.handleId}`
        );

        res.status(201).json({ success: true, data: newNat, message: "NAT Rule added successfully" });

    } catch (error) {
        return firewallError(res, error, "Failed to add NAT rule");
    }
};

exports.getNatRules = async (req, res) => {
    try {
        const page = Math.max(1, parseInt(req.query.page) || 1);
        const limit = Math.min(100, parseInt(req.query.limit) || 20);
        const skip = (page - 1) * limit;

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

exports.toggleNatRuleStatus = async (req, res) => {
    try {
        const natrule = await NatRule.findById(req.params.id);
        if (!natrule) return res.status(404).json({ message: 'NAT Rule not found' });

        if (natrule.isActive) {

            const firewallResponse = await firewallAgent.delete('/api/delete_nat', {
                data: {
                    nat_type: natrule.nat_type,
                    handle: natrule.handleId
                }
            });

            if (firewallResponse.data.status !== 'success') {
                return res.status(400).json({
                    success: false,
                    message: 'Firewall failed to remove NAT rule',
                    details: firewallResponse.data
                });
            }

            natrule.isActive = false;
            natrule.handleId = null;
            await natrule.save();
            await logActivity(
                req.user._id,
                req.user.username,
                `Disable ${natrule.nat_type.toUpperCase()} NAT`,
                `NAT rule disabled | comment: ${natrule.comment}`
            );
            return res.json({
                success: true,
                message: 'NAT rule disabled (Removed from Firewall)',
                data: natrule
            });

        } else {

            const payload = buildPythonPayload(natrule, natrule.comment);

            const firewallResponse = await firewallAgent.post('/api/add_nat', payload);

            if (firewallResponse.data.status === 'error' || !firewallResponse.data.handle) {
                return res.status(400).json({
                    success: false,
                    message: 'Firewall failed to re-add NAT rule',
                    details: firewallResponse.data
                });
            }

            natrule.isActive = true;
            natrule.handleId = firewallResponse.data.handle;
            await natrule.save();
            await logActivity(
                req.user._id,
                req.user.username,
                `Enable ${natrule.nat_type.toUpperCase()} NAT`,
                `NAT rule re-enabled | comment: ${natrule.comment}`
            );
            return res.json({
                success: true,
                message: 'NAT rule enabled (Added to Firewall)',
                data: natrule
            });
        }

    } catch (error) {
        return firewallError(res, error);
    }
};



exports.deleteNatRule = async (req, res) => {
    try {
        const rule = await NatRule.findById(req.params.id);
        if (!rule) return res.status(404).json({ message: 'NAT Rule not found' });


        if (rule.isActive && rule.handleId) {
            const firewallResponse = await firewallAgent.delete('/api/delete_nat', {
                data: { nat_type: rule.nat_type, handle: rule.handleId }
            });

            if (firewallResponse.data.status === "error") {
                return res.status(400).json({ success: false, message: "Failed to delete from Firewall", details: firewallResponse.data.output });
            }
        }

        // 2. Delete from DB & Log
        await rule.deleteOne();
        await logActivity(
            req.user._id,
            req.user.username,
            `Delete ${rule.nat_type.toUpperCase()} NAT`,
            `Removed from firewall and DB`);

        res.status(200).json({ success: true, message: 'NAT Rule deleted successfully' });
    } catch (error) {
        return firewallError(res, error);
    }
};