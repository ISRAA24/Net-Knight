const NatRule = require('../models/NATrules');
const firewallAgent = require('../config/firewallAgent');
const logger = require('../utils/logger');
const { validateIpFields, firewallError } = require('../utils/firewall.helpers');
const { logActivity } = require('../utils/activityLogger');

// Helper function to build Python payload
const buildPythonPayload = (data, finalComment) => {
    const payload = { nat_type: data.nat_type, comment: finalComment };

    if (data.nat_type === 'masquerade') {
        // كده النود هياخد الـ source_ip والـ output_interface زي ما هما مبعوتين
        if (data.source_ip) payload.source_ip = data.source_ip;
        payload.output_interface = data.output_interface || data.network_interface; 
        
    } else if (data.nat_type === 'source') {
        payload.source_ip = data.source_ip;
        payload.new_source_ip = data.new_source_ip;
        payload.output_interface = data.output_interface || data.network_interface;
        
    } else if (data.nat_type === 'destination') {
        payload.input_interface = data.input_interface || data.network_interface;
        payload.dest_ip = data.dest_ip; // Internal IP in UI is dest_ip
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
        // 1. Validate the provided IP addresses
       let ipsToValidate = [];

        if (data.nat_type === 'masquerade') {
            // لو باعت source_ip، افحصه
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
        // 🔍 حطي السطر ده في ملف src/controllers/NAT.controller.js قبل الـ post
console.log("🚀 Sending to Firewall Agent:", JSON.stringify(payload, null, 2));

        const firewallResponse = await firewallAgent.post('/api/add_nat', payload);
        console.log("🔥 ERROR FROM PYTHON: ", firewallResponse.data);
        if (firewallResponse.data.status === "error" || !firewallResponse.data.handle) {
            return res.status(400).json({ success: false, message: "Firewall rejected NAT rule", details: firewallResponse.data.output ,python_error: firewallResponse.data });
        }

        // 2. Save to DB
        const newNat = await NatRule.create({
            ...req.body,
            handleId: firewallResponse.data.handle,
            comment: finalComment,
            createdBy: req.user._id
        });

        // 3. Log Activity
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
//GET /api/firewall/nat
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
            // ── Disable: remove from firewall ──────────────────────────────
            const firewallResponse = await firewallAgent.delete('/api/delete_nat', {
                data: {                          // axios.delete needs `data` key
                    nat_type: natrule.nat_type,
                    handle  : natrule.handleId
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

            return res.json({
                success: true,
                message: 'NAT rule disabled (Removed from Firewall)',
                data   : natrule
            });

        } else {
            // ── Enable: re-add to firewall using stored fields ─────────────
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

            return res.json({
                success: true,
                message: 'NAT rule enabled (Added to Firewall)',
                data   : natrule
            });
        }

    } catch (error) {
        return firewallError(res, error);
    }
};


//    DELETE /api/firewall/nat/:id
exports.deleteNatRule = async (req, res) => {
    try {
        const rule = await NatRule.findById(req.params.id);
        if (!rule) return res.status(404).json({ message: 'NAT Rule not found' });

        // 1. Delete from Firewall (Requires nat_type and handle according to firewall.py)
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

exports.editNatRule = async (req, res) => {
    try {
        const rule = await NatRule.findById(req.params.id);
        if (!rule) return res.status(404).json({ message: 'NAT Rule not found' });

        const updatedData = { ...rule.toObject(), ...req.body }; // دمج الداتا القديمة مع التعديلات
        
        // 1. امسح الرول القديمة من اللينكس
        if (rule.isActive && rule.handleId) {
            await firewallAgent.delete('/api/delete_nat', {
                data: { nat_type: rule.nat_type, handle: rule.handleId }
            });
        }

        // 2. جهز الداتا الجديدة وابعتها للينكس كأنها رول جديدة
        const payload = buildPythonPayload(updatedData, rule.comment); // هنحافظ على نفس الكومنت القديم
        const firewallResponse = await firewallAgent.post('/api/add_nat', payload);

        if (firewallResponse.data.status === "error" || !firewallResponse.data.handle) {
            return res.status(400).json({ success: false, message: "Failed to apply edited rule to Firewall", details: firewallResponse.data.output });
        }

        // 3. تحديث الداتابيس بالبيانات الجديدة والـ Handle الجديد
        const updatedRule = await NatRule.findByIdAndUpdate(req.params.id, {
            ...req.body,
            handleId: firewallResponse.data.handle,
            isActive: true
        }, { new: true });

        // 4. Log Activity
       await logActivity(
        req.user._id, 
        req.user.username, 
        `Edit ${updatedRule.nat_type.toUpperCase()} NAT`,
        `Handle updated to ${updatedRule.handleId}`
    );

        res.status(200).json({ success: true, data: updatedRule, message: 'NAT Rule updated successfully' });
    } catch (error) {
        return firewallError(res, error);
    }
};
