const AIRule       = require('../models/AIRule');
const Threat       = require('../models/Threat');
const SystemSetting = require('../models/SystemSetting');
const firewallAgent = require('../config/firewallAgent');
const logger        = require('../utils/logger');
const { firewallError } = require('../utils/firewall.helpers');
const { logActivity }   = require('../utils/activityLogger');
const { invalidateStatsCache } = require('../sockets/dashboard.socket');
// ─────────────────────────────────────────────────────────────────────────────
// helper: يجيب الـ IP المخزن في الرول (source أو destination)
// ─────────────────────────────────────────────────────────────────────────────
const getRuleIp = (rule) => rule.sourceIp || rule.ipDestination;

// ─────────────────────────────────────────────────────────────────────────────
// 1. Python Agent: هل الـ Auto Approve متفعل؟
// GET /api/ai/settings/auto-approve
// ─────────────────────────────────────────────────────────────────────────────
exports.getAutoApproveStatus = async (req, res) => {
    try {
        let setting = await SystemSetting.findOne();
        if (!setting) setting = await SystemSetting.create({ autoApproveAiRules: false });
        res.status(200).json({ success: true, autoApprove: setting.autoApproveAiRules });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 2. Python Agent: بعت الرول بعد ما قرر يطبقها أو يستنى
// POST /api/ai/rules
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveAIRule = async (req, res) => {
    try {
        const {
            sourceIp, ipDestination, action, reason, threatId, status,
            durationInSeconds, ruleName,
            family, tableName, chainName, handleId, setName
        } = req.body;

        // واحد من الـ IP fields مطلوب على الأقل
        if (!sourceIp && !ipDestination) {
            return res.status(400).json({
                success: false,
                message: 'Either sourceIp or ipDestination is required.'
            });
        }

        let expireAt;
        if (durationInSeconds) {
            expireAt = new Date(Date.now() + durationInSeconds * 1000);
        }

        const newAIRule = await AIRule.create({
            ruleName,
            sourceIp:      sourceIp      || null,
            ipDestination: ipDestination || null,
            action,
            reason,
            threatId,
            status,
            family:    family    || 'ip',
            tableName: tableName || null,
            chainName: chainName || null,
            handleId:  handleId  || null,
            setName:   setName   || null,
            timeout:   durationInSeconds || null,  // نحتفظ بالمدة عشان التوجل
            expireAt
        });

        res.status(201).json({
            success: true,
            message: `Rule recorded as ${status}`,
            data: newAIRule
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 3. Flutter: تغيير حالة زرار Auto Approve
// PUT /api/ai/settings/auto-approve
// ─────────────────────────────────────────────────────────────────────────────
exports.toggleAutoApprove = async (req, res) => {
    try {
        const { autoApprove } = req.body;
        let setting = await SystemSetting.findOne();
        if (!setting) setting = new SystemSetting();

        setting.autoApproveAiRules = autoApprove;
        await setting.save();

        await logActivity(
            req.user._id, req.user.username,
            'System Setting', 'AI Auto Approve',
            `Auto Approve changed to ${autoApprove}`
        );

        res.status(200).json({
            success: true,
            message: 'Auto Approve updated',
            autoApprove: setting.autoApproveAiRules
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 4. Flutter: جلب كل الـ AI Rules
// GET /api/ai/rules
// ─────────────────────────────────────────────────────────────────────────────
exports.getAIRules = async (req, res) => {
    try {
        const rules = await AIRule.find().sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: rules });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 5. Flutter: الأدمن يعمل Approve أو Reject لرول pending
// PUT /api/ai/rules/:ruleId/review
//
// approve → بيبعت للـ Python Agent يطبق الرول في الفايروول
// reject  → بتفضل في الـ DB بس كـ rejected، مش بتتطبق
// ─────────────────────────────────────────────────────────────────────────────
exports.reviewAIRule = async (req, res) => {
    try {
        const { ruleId }   = req.params;
        const { decision } = req.body; // 'approve' or 'reject'

        const aiRule = await AIRule.findById(ruleId);
        if (!aiRule)
            return res.status(404).json({ success: false, message: 'Rule not found' });
        if (aiRule.status !== 'pending')
            return res.status(400).json({ success: false, message: 'Rule already reviewed' });

        if (decision === 'approve') {
            // بنبعت للـ Python Agent يطبق الرول في الفايروول
            const r = await firewallAgent.post('/api/manage_rules', {
                sourceIp:   aiRule.sourceIp,
                ipDest:     aiRule.ipDestination,
                action:     aiRule.action,
                family:     aiRule.family    || 'ip',
                table_name: aiRule.tableName,
                chain_name: aiRule.chainName,
                set_name:   aiRule.setName,
                type:       'ai_dynamic'
            });

            if (r.data.status === 'error') {
                return res.status(400).json({ success: false, message: r.data.message });
            }

            aiRule.status     = 'approved';
            aiRule.reviewedBy = req.user._id;
            aiRule.isActive   = true;

            // لو الـ Agent رجع handle (non-set rule) نخزنه
            if (r.data.handle) aiRule.handleId = r.data.handle;

        } else if (decision === 'reject') {
            // مش بتتطبق — بتفضل في الـ DB كـ rejected بس
            aiRule.status     = 'rejected';
            aiRule.reviewedBy = req.user._id;
            aiRule.isActive   = false; // rejected rules مش شغالة في الفايروول
        }

        await aiRule.save();

        invalidateStatsCache(); 

        await logActivity(
            req.user._id, req.user.username,
            `AI Rule ${decision}`,
            getRuleIp(aiRule) || String(aiRule._id),
            `Admin ${decision}d rule | action: ${aiRule.action}`
        );

        res.status(200).json({ success: true, message: `Rule ${decision}d successfully`, data: aiRule });
    } catch (error) {
        logger.error(`reviewAIRule error: ${error.message}`);
        return firewallError(res, error);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 6. Python Agent: بعت تهديد (Threat) جديد
// POST /api/ai/threats
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveThreat = async (req, res) => {
    try {
        const { sourceIp, attackType, severity, details } = req.body;

        const newThreat = await Threat.create({ sourceIp, attackType, severity, details });
        logger.warn(`🚨 New Threat Detected! IP: ${sourceIp}, Type: ${attackType}`);

        res.status(201).json({ success: true, message: 'Threat recorded successfully', data: newThreat });
    } catch (error) {
        logger.error(`receiveThreat error: ${error.message}`);
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 7. Flutter: جلب كل التهديدات (Threats)
// GET /api/ai/threats
// ─────────────────────────────────────────────────────────────────────────────
exports.getAllThreats = async (req, res) => {
    try {
        const threats = await Threat.find().sort({ createdAt: -1 });
        res.status(200).json({ success: true, count: threats.length, data: threats });
    } catch (error) {
        logger.error(`getAllThreats error: ${error.message}`);
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 8. Flutter: حذف AI Rule
// DELETE /api/ai/rules/:id
// ─────────────────────────────────────────────────────────────────────────────
exports.deleteAIRule = async (req, res) => {
    try {
        const rule = await AIRule.findById(req.params.id);
        if (!rule) return res.status(404).json({ success: false, message: 'AI Rule not found' });

        const ip         = getRuleIp(rule);
        const isApplied  = ['approved', 'auto-approved'].includes(rule.status);

        // بنكلم الفايروول بس لو الرول كانت approved/auto-approved وشغالة فعلاً
        if (isApplied && rule.isActive) {

            if (rule.setName) {
                // ① Set-based: نمسح الـ IP element من الـ Set
                const firewallResponse = await firewallAgent.delete('/api/delete_element', {
                    data: {
                        family:     rule.family    || 'ip',
                        table_name: rule.tableName,
                        set_name:   rule.setName,
                        ip
                    }
                });

                if (firewallResponse.data.status !== 'success') {
                    return res.status(400).json({
                        success: false,
                        message: 'Firewall failed to remove element from set',
                        details: firewallResponse.data
                    });
                }

            } else if (rule.handleId) {
                
                const firewallResponse = await firewallAgent.delete('/api/delete_rule', {
                    data: {
                        family: rule.family    || 'ip',
                        table:  rule.tableName,
                        chain:  rule.chainName,
                        handle: rule.handleId
                    }
                });

                if (firewallResponse.data.status !== 'success') {
                    return res.status(400).json({
                        success: false,
                        message: 'Firewall failed to delete AI rule',
                        details: firewallResponse.data
                    });
                }
            }
          
        }

        await rule.deleteOne();
        
        invalidateStatsCache(); 

        await logActivity(
            req.user._id,
            req.user.username,
            'Delete AI Rule',
            ip || String(rule._id),
            `Deleted AI rule | action: ${rule.action} | status was: ${rule.status}`
        );

        return res.status(200).json({ success: true, message: 'AI Rule deleted successfully' });
    } catch (error) {
        return firewallError(res, error);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 9. Flutter: تفعيل / تعطيل AI Rule  (Toggle isActive)
// PATCH /api/ai/rules/:id/toggle
// ─────────────────────────────────────────────────────────────────────────────
exports.toggleAIRuleStatus = async (req, res) => {
    try {
        const rule = await AIRule.findById(req.params.id);
        if (!rule) return res.status(404).json({ success: false, message: 'AI Rule not found' });

        
        if (!['approved', 'auto-approved'].includes(rule.status)) {
            return res.status(400).json({
                success: false,
                message: `Cannot toggle an AI rule with status "${rule.status}". Only approved or auto-approved rules can be toggled.`
            });
        }

        const ip = getRuleIp(rule);

        // ────────────────────────────────────────────────
        //  Disable: نشيل الرول من الفايروول مؤقتاً
        // ────────────────────────────────────────────────
        if (rule.isActive) {

            if (rule.setName) {
                // Set-based disable
                const firewallResponse = await firewallAgent.delete('/api/delete_element', {
                    data: {
                        family:     rule.family    || 'ip',
                        table_name: rule.tableName,
                        set_name:   rule.setName,
                        ip
                    }
                });

                if (firewallResponse.data.status !== 'success') {
                    return res.status(400).json({
                        success: false,
                        message: 'Firewall failed to remove element from set',
                        details: firewallResponse.data
                    });
                }

            } else if (rule.handleId) {
                // Handle-based disable: زي الـ Static Rules
                const firewallResponse = await firewallAgent.delete('/api/delete_rule', {
                    data: {
                        family: rule.family    || 'ip',
                        table:  rule.tableName,
                        chain:  rule.chainName,
                        handle: rule.handleId
                    }
                });

                if (firewallResponse.data.status !== 'success') {
                    return res.status(400).json({
                        success: false,
                        message: 'Firewall failed to disable AI rule',
                        details: firewallResponse.data
                    });
                }
                
                rule.handleId = null;

            } else {
                
                return res.status(400).json({
                    success: false,
                    message: 'Cannot disable rule: no handle ID or set name found. The rule may not be tracked in the firewall.'
                });
            }

            rule.isActive = false;
            await rule.save();

            await logActivity(
                req.user._id, req.user.username,
                'Toggle AI Rule',
                ip || String(rule._id),
                'AI Rule disabled (removed from firewall)'
            );

            return res.json({
                success: true,
                message: 'AI Rule disabled (Removed from Firewall)',
                data: rule
            });

        
        } else {

            if (rule.setName) {
                
                const firewallResponse = await firewallAgent.post('/api/add_element', {
                    family:     rule.family    || 'ip',
                    table_name: rule.tableName,
                    set_name:   rule.setName,
                    ip,
                    timeout:    rule.timeout || null
                });

                if (firewallResponse.data.status !== 'success') {
                    return res.status(400).json({
                        success: false,
                        message: 'Firewall failed to re-add element to set',
                        details: firewallResponse.data
                    });
                }

            } else {
                
                const firewallResponse = await firewallAgent.post('/api/add_rule', {
                    family:     rule.family    || 'ip',
                    table_name: rule.tableName,
                    chain_name: rule.chainName,
                    ip_src:     rule.sourceIp      || '',
                    ip_dest:    rule.ipDestination || '',
                    action:     rule.action
                });

                if (!firewallResponse.data.handle) {
                    return res.status(400).json({
                        success: false,
                        message: 'Firewall failed to re-add AI rule',
                        details: firewallResponse.data
                    });
                }

            
                rule.handleId = firewallResponse.data.handle;
            }

            rule.isActive = true;
            await rule.save();

            await logActivity(
                req.user._id, req.user.username,
                'Toggle AI Rule',
                ip || String(rule._id),
                'AI Rule enabled (added back to firewall)'
            );

            return res.json({
                success: true,
                message: 'AI Rule enabled (Added to Firewall)',
                data: rule
            });
        }

    } catch (error) {
        return firewallError(res, error);
    }
};