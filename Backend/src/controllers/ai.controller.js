const AIRule       = require('../models/AIRule');
const Threat       = require('../models/Threat');
const SystemSetting = require('../models/SystemSettings');
const firewallAgent = require('../config/firewallAgent');
const logger        = require('../utils/logger');
const { firewallError } = require('../utils/firewall.helpers');
const { logActivity }   = require('../utils/activityLogger');
const { invalidateStatsCache } = require('../sockets/dashboard.socket');
const { createNotification } = require('../utils/notificationHelper');

// ─────────────────────────────────────────────────────────────────────────────
// helper: يجيب الـ IP المخزن في الرول (source أو destination)
// ─────────────────────────────────────────────────────────────────────────────
const getRuleIp = (rule) => rule.sourceIp || rule.destinationIp;

// ─────────────────────────────────────────────────────────────────────────────
// helper: بتمسح رول من الفايروول (عن طريق deletions الجاهزة أو fallback بالـ handle/set)
// بترجع true لو تقدر تكمل تمسح من الداتابيس، و false لو لازم تحاول تاني بعدين
// (نفس منطق deleteAIRule/toggleAIRuleStatus بالظبط عشان السلوك يفضل متسق)
// ─────────────────────────────────────────────────────────────────────────────
const removeRuleFromFirewall = async (rule) => {
    const ip = getRuleIp(rule);

    if (rule.deletions && rule.deletions.length > 0) {
        for (const delPayload of rule.deletions) {
            const { label, ...cleanPayload } = delPayload;
            try {
                const firewallResponse = await firewallAgent.post('/rules/delete', cleanPayload);
                if (!firewallResponse.data?.ok) {
                    logger.error(`Firewall agent failed to delete rule part [${label || 'unknown'}] for expired rule ${rule._id}`);
                }
            } catch (err) {
                logger.error(`Firewall agent error deleting rule part [${label || 'unknown'}] for expired rule ${rule._id}: ${err.message}`);
            }
        }
        // زي سلوك deleteAIRule بالظبط: بنكمل ونمسح من الداتابيس حتى لو جزء من الـ deletions فشل
        return true;
    }

    // Fallback للـ Rules القديمة اللي معندهاش حقل deletions
    let deletion = null;
    if (rule.setName) {
        deletion = { mode: 'set_element', family: rule.family || 'inet', table: rule.tableName, set: rule.setName, ip };
        if (rule.port) deletion.port = rule.port;
    } else if (rule.handleId) {
        deletion = { mode: 'handle', family: rule.family || 'inet', table: rule.tableName, chain: rule.chainName, handle: rule.handleId };
    }

    if (!deletion) return true; // مفيش حاجة متطبقة في الفايروول أصلا (رول pending/rejected مثلا)

    try {
        const firewallResponse = await firewallAgent.post('/rules/delete', deletion);
        if (!firewallResponse.data?.ok) {
            logger.error(`Firewall agent failed to delete expired rule ${rule._id}`);
            return false; // هنسيب الرول في الداتابيس عشان الـ job يحاول تاني الدورة الجاية
        }
        return true;
    } catch (err) {
        logger.error(`Firewall agent error deleting expired rule ${rule._id}: ${err.message}`);
        return false;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 1. Flutter/Python: هل الـ Auto Approve متفعل؟
// GET /api/ai/settings/auto-approve
// ─────────────────────────────────────────────────────────────────────────────
exports.getAutoApproveStatus = async (req, res) => {
    try {
        let setting = await SystemSetting.findOne();
        if (!setting) setting = await SystemSetting.create({ autoApproveAiRules: false });

        try {
            const live = await firewallAgent.get('/config/auto_approve');
            if (typeof live.data?.auto_approve === 'boolean' &&
                live.data.auto_approve !== setting.autoApproveAiRules) {
                setting.autoApproveAiRules = live.data.auto_approve;
                await setting.save();
            }
        } catch (err) {
            logger.error(`Could not reach firewall agent for auto_approve status: ${err.message}`);
        }

        res.status(200).json({ success: true, autoApprove: setting.autoApproveAiRules });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 2. Network_Scripts (approval_gateway.py → node_client.send_alert):
// POST /api/netknight/alerts
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveAlert = async (req, res) => {
    try {
        const {
            request_id: requestId,
            description,
            explanation,
            explanation_details: explanationDetails,
            attack_type: attackType,
            confidence,
            severity,
            action,
            rule
        } = req.body;

        if (!requestId || !rule || (!rule.src_ip && !rule.dest_ip)) {
            return res.status(400).json({
                success: false,
                message: 'request_id and rule.src_ip/rule.dest_ip are required.'
            });
        }

        // 👈 التعديل هنا: بنشيك لو فيه deletions جاية من بايثون يبقى الرول اتطبقت
        const isApplied = rule.deletions && rule.deletions.length > 0;
        const status    = isApplied ? 'auto-approved' : 'pending';
        const ip         = rule.src_ip || rule.dest_ip;
        const expireAt   = rule.timeout ? new Date(Date.now() + rule.timeout * 1000) : null;

        // 👈 نطبّع الـ severity (lowercase + trim) عشان لو جاية من بايثون بحروف كابيتال
        // أو فيها مسافات زيادة، ماتفضلش دايما توقع على الـ default 'medium'
        const normalizedSeverity = typeof severity === 'string' ? severity.trim().toLowerCase() : null;
        const validSeverity = ['low', 'medium', 'high', 'critical'].includes(normalizedSeverity)
            ? normalizedSeverity
            : null;

        // 1) نسجل التهديد (Threat)
        const newThreat = await Threat.create({
            sourceIp:   ip,
            attackType: attackType || 'unknown',
            severity:   validSeverity || 'medium',
            confidence: confidence ?? null,
            details:    description || explanation || ''
        });

        // 2) نسجل قاعدة الـ AI (AIRule)
        const newAIRule = await AIRule.create({
            requestId,
            ruleName:    `AI_${attackType || 'rule'}_${ip}`,
            sourceIp:    rule.src_ip  || null,
            destinationIp: rule.dest_ip || null,
            port:        rule.port ?? null,
            action:      action || 'unknown',
            description: description || '',
            explanation: explanation || '',
            explanationDetails: explanationDetails || {},
            attackType:  attackType || null,
            confidence:  confidence ?? null,
            severity:    validSeverity,
            rateLimit:   rule.rate_limit || null,
            family:      rule.family || 'inet',
            tableName:   rule.table  || null,
            chainName:   rule.chain  || null,
            setName:     rule.set    || null,
            handleId:    rule.handle_id || null,
            deletions:   rule.deletions || [], // 👈 خزنّا مصفوفة المسح الجاهزة
            timeout:     rule.timeout   || null,
            expireAt,
            status,
            isActive:    isApplied,
            threatId:    newThreat._id
        });

        // 3) Notifications
        if (status === 'pending') {
            await createNotification({
                type:     'ai_rule_pending',
                title:    'AI rule pending review',
                message:  `Rule generated — suspicious activity from ${ip}, awaiting your approval`,
                severity: 'warning',
                tag:      'Review needed',
                relatedId:    newAIRule._id,
                relatedModel: 'AIRule',
                metadata: { ip, action, attackType, confidence }
            });
        } else {
            const tag = validSeverity ? validSeverity.charAt(0).toUpperCase() + validSeverity.slice(1) : 'Warning';
            const notifSeverity = ['critical', 'high'].includes(validSeverity) ? validSeverity : 'warning';
            await createNotification({
                type:     'threat_alert',
                title:    'Threat mitigated automatically',
                message:  description || `${attackType || 'Threat'} from ${ip} — auto-mitigated`,
                severity: notifSeverity,
                tag,
                relatedId:    newAIRule._id,
                relatedModel: 'AIRule',
                metadata: { ip, action, attackType, confidence }
            });
        }

        invalidateStatsCache();

        return res.status(201).json({
            success: true,
            message: `Alert recorded as ${status}`,
            data: newAIRule
        });
    } catch (error) {
        logger.error(`receiveAlert error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// [Legacy / يدوي فقط] POST /api/ai/rules
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveAIRule = async (req, res) => {
    try {
        const {
            sourceIp, destinationIp, action, reason, threatId, status,
            durationInSeconds, ruleName,
            family, tableName, chainName, handleId, setName
        } = req.body;

        if (!sourceIp && !destinationIp) {
            return res.status(400).json({ success: false, message: 'Either sourceIp or destinationIp is required.' });
        }

        let expireAt;
        if (durationInSeconds) {
            expireAt = new Date(Date.now() + durationInSeconds * 1000);
        }

        const newAIRule = await AIRule.create({
            ruleName,
            sourceIp:      sourceIp      || null,
            destinationIp: destinationIp || null,
            action,
            explanation: reason || '',
            threatId:    threatId || null,
            status,
            family:    family    || 'inet',
            tableName: tableName || null,
            chainName: chainName || null,
            handleId:  handleId  || null,
            setName:   setName   || null,
            timeout:   durationInSeconds || null,
            expireAt
        });

        if (status === 'pending') {
            const ip = sourceIp || destinationIp;
            await createNotification({
                type:     'ai_rule_pending',
                title:    'AI rule pending review',
                message:  `Rule generated — suspicious activity from ${ip}, awaiting your approval`,
                severity: 'warning',
                tag:      'Review needed',
                relatedId:    newAIRule._id,
                relatedModel: 'AIRule',
                metadata: { ip, action, reason: reason || '' }
            });
            invalidateStatsCache();
        }

        res.status(201).json({ success: true, message: `Rule recorded as ${status}`, data: newAIRule });
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
        if (typeof autoApprove !== 'boolean') {
            return res.status(400).json({ success: false, message: 'autoApprove must be a boolean.' });
        }

        await firewallAgent.post('/config/auto_approve', { value: autoApprove });

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
        logger.error(`toggleAutoApprove error: ${error.message}`);
        return firewallError(res, error);
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
// ─────────────────────────────────────────────────────────────────────────────
exports.reviewAIRule = async (req, res) => {
    try {
        const { ruleId }   = req.params;
        const { decision } = req.body; 

        if (!['approve', 'reject'].includes(decision)) {
            return res.status(400).json({ success: false, message: "decision must be 'approve' or 'reject'." });
        }

        const aiRule = await AIRule.findById(ruleId);
        if (!aiRule)
            return res.status(404).json({ success: false, message: 'Rule not found' });
        if (aiRule.status !== 'pending')
            return res.status(400).json({ success: false, message: 'Rule already reviewed' });
        if (!aiRule.requestId) {
            return res.status(400).json({
                success: false,
                message: 'This rule has no request_id from the firewall agent — it cannot be approved/rejected remotely.'
            });
        }

        if (decision === 'approve') {
            const r = await firewallAgent.post('/decisions/approve', { request_id: aiRule.requestId });
            const payload = r.data; 

            aiRule.status     = 'approved';
            aiRule.reviewedBy = req.user._id;
            aiRule.isActive   = true;

            // 👈 التعديل هنا: تخزين الـ deletions بعد ما البايثون طبق القاعدة
            if (payload?.rule?.deletions) aiRule.deletions = payload.rule.deletions;
            if (payload?.rule?.handle_id) aiRule.handleId  = payload.rule.handle_id;
            if (payload?.rule?.chain)     aiRule.chainName = payload.rule.chain;
            if (payload?.rule?.set)       aiRule.setName   = payload.rule.set;
            if (payload?.rule?.timeout) {
                aiRule.timeout  = payload.rule.timeout;
                aiRule.expireAt = new Date(Date.now() + payload.rule.timeout * 1000);
            }

        } else {
            await firewallAgent.post('/decisions/reject', { request_id: aiRule.requestId });
            aiRule.status     = 'rejected';
            aiRule.reviewedBy = req.user._id;
            aiRule.isActive   = false;
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
        if (error.response?.status === 404) {
            return res.status(409).json({
                success: false,
                message: 'The firewall agent no longer has this pending request. The rule was not applied.'
            });
        }
        return firewallError(res, error);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 6. [Legacy / يدوي فقط] POST /api/ai/threats
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveThreat = async (req, res) => {
    try {
        const { sourceIp, attackType, severity, confidence, details } = req.body;

        const newThreat = await Threat.create({
            sourceIp, attackType, severity, confidence: confidence || null, details
        });

        logger.warn(`🚨 Threat Detected! IP: ${sourceIp} | Type: ${attackType} | Severity: ${severity}`);

        const tag = severity ? severity.charAt(0).toUpperCase() + severity.slice(1) : 'Warning';
        const notifSeverity = ['critical', 'high'].includes(severity) ? severity : 'warning';
        const confidenceText = confidence ? ` — confidence: ${confidence}%` : '';

        await createNotification({
            type:     'threat_alert',
            title:    'Threat alert detected',
            message:  `${attackType} from ${sourceIp}${confidenceText}`,
            severity: notifSeverity,
            tag,
            relatedId:    newThreat._id,
            relatedModel: 'Threat',
            metadata: { sourceIp, attackType, severity, confidence, details }
        });

        invalidateStatsCache();
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

        const ip        = getRuleIp(rule);
        const isApplied = ['approved', 'auto-approved'].includes(rule.status) && rule.isActive;

        if (isApplied) {
            // 👈 التعديل هنا: المسح هيتم عن طريق الـ deletions اللي جاية جاهزة
            if (rule.deletions && rule.deletions.length > 0) {
                for (const delPayload of rule.deletions) {
                    const { label, ...cleanPayload } = delPayload; // شيلنا label عشان الـ agent مش محتاجه
                    const firewallResponse = await firewallAgent.post('/rules/delete', cleanPayload);
                    if (!firewallResponse.data?.ok) {
                        logger.error(`Firewall agent failed to delete rule part [${label || 'unknown'}]`);
                    }
                }
            } else {
                // Fallback للـ Rules القديمة اللي معندهاش حقل deletions
                let deletion = null;
                if (rule.setName) {
                    deletion = { mode: 'set_element', family: rule.family || 'inet', table: rule.tableName, set: rule.setName, ip };
                    if (rule.port) deletion.port = rule.port;
                } else if (rule.handleId) {
                    deletion = { mode: 'handle', family: rule.family || 'inet', table: rule.tableName, chain: rule.chainName, handle: rule.handleId };
                }

                if (deletion) {
                    const firewallResponse = await firewallAgent.post('/rules/delete', deletion);
                    if (!firewallResponse.data?.ok) {
                        return res.status(400).json({
                            success: false,
                            message: 'Firewall agent failed to delete the rule',
                            details: firewallResponse.data
                        });
                    }
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
        if (error.response?.status === 400) {
            return res.status(400).json({
                success: false,
                message: 'Firewall agent rejected the deletion request',
                details: error.response.data
            });
        }
        return firewallError(res, error);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 9. Flutter: تفعيل / تعطيل AI Rule (Toggle isActive)
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

        if (rule.isActive) {
            // 👈 نفس تعديل الحذف بنستخدمه هنا لتعطيل القاعدة
            if (rule.deletions && rule.deletions.length > 0) {
                for (const delPayload of rule.deletions) {
                    const { label, ...cleanPayload } = delPayload;
                    const firewallResponse = await firewallAgent.post('/rules/delete', cleanPayload);
                    if (!firewallResponse.data?.ok) {
                        return res.status(400).json({
                            success: false,
                            message: `Firewall failed to disable AI rule part [${label}]`,
                            details: firewallResponse.data
                        });
                    }
                }
            } else {
                // Fallback للـ Rules القديمة
                let deletion = null;
                if (rule.setName) {
                    deletion = { mode: 'set_element', family: rule.family || 'inet', table: rule.tableName, set: rule.setName, ip };
                    if (rule.port) deletion.port = rule.port;
                } else if (rule.handleId) {
                    deletion = { mode: 'handle', family: rule.family || 'inet', table: rule.tableName, chain: rule.chainName, handle: rule.handleId };
                } else {
                    return res.status(400).json({
                        success: false,
                        message: 'Cannot disable rule: no handle ID or set name found. The rule may not be tracked in the firewall.'
                    });
                }

                const firewallResponse = await firewallAgent.post('/rules/delete', deletion);
                if (!firewallResponse.data?.ok) {
                    return res.status(400).json({
                        success: false,
                        message: 'Firewall failed to disable AI rule',
                        details: firewallResponse.data
                    });
                }
            }

            rule.isActive = false;
            rule.handleId = null;
            rule.deletions = []; // 👈 فرغنا المصفوفة لإن الـ handles خلاص اتمسحت من النيتورك
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
        }

        // Re-enable: غير مدعومة من firewall agent الحالي
        return res.status(501).json({
            success: false,
            message: 'Re-enabling a disabled AI rule is not supported by the firewall agent yet. Delete this rule instead.'
        });

    } catch (error) {
        return firewallError(res, error);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 10. POST /api/netknight/bandwidth-alert 
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveBandwidthAlert = async (req, res) => {
    try {
        const { message, usage_percent: usagePercent } = req.body;

        if (usagePercent === undefined) {
            return res.status(400).json({ success: false, message: 'usage_percent is required' });
        }

        await createNotification({
            type:     'traffic_spike',
            title:    'Unusual traffic spike',
            message:  message || `Bandwidth usage exceeded threshold (${usagePercent}%)`,
            severity: 'warning',
            tag:      'Warning',
            metadata: { usagePercent }
        });

        return res.status(200).json({ success: true, message: 'Bandwidth alert recorded' });
    } catch (error) {
        logger.error(`receiveBandwidthAlert error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 11. 🕒 Auto-Expire Job: بتدور على كل الـ AI Rules اللي خلص التايم اوت بتاعها
// (expireAt <= دلوقتي) وتمسحها من الفايروول ومن الداتابيس تلقائي
// مفيش route لها — بتتشغل لوحدها من الـ scheduler تحت
// ─────────────────────────────────────────────────────────────────────────────
exports.expireTimedOutRules = async () => {
    try {
        const now = new Date();
        const expiredRules = await AIRule.find({
            isActive: true,
            expireAt: { $ne: null, $lte: now }
        });

        if (expiredRules.length === 0) return;

        logger.info(`⏱️ Found ${expiredRules.length} expired AI rule(s) — cleaning up...`);

        for (const rule of expiredRules) {
            const ip = getRuleIp(rule);

            try {
                const removedFromFirewall = await removeRuleFromFirewall(rule);

                if (!removedFromFirewall) {
                    // هنسيب الرول زي ما هي في الداتابيس عشان الـ job ياخد فرصة تاني يمسحها من الفايروول
                    // في الدورة الجاية، بدل ما نخليها "يتيمة" (متمسوحة من DB بس لسه شغالة في الفايروول)
                    logger.error(`Skipping DB cleanup for expired rule ${rule._id} (${ip || 'no ip'}) — firewall deletion failed, will retry next cycle.`);
                    continue;
                }

                await rule.deleteOne();


                logger.info(`✅ Expired AI rule removed (firewall + DB): ${rule._id} (${ip || 'no ip'})`);
            } catch (err) {
                logger.error(`Error while expiring AI rule ${rule._id}: ${err.message}`);
            }
        }

        invalidateStatsCache();
    } catch (error) {
        logger.error(`expireTimedOutRules error: ${error.message}`);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 🔁 تشغيل الفحص الدوري: كل دقيقة بنشيك هل فيه رولز خلصت التايم اوت بتاعها
// (بيشتغل تلقائي أول ما السيرفر يرفع الـ controller ده، مفيش داعي لأي setup إضافي)
// ─────────────────────────────────────────────────────────────────────────────
const EXPIRY_CHECK_INTERVAL_MS = 60 * 1000; // كل دقيقة، غيّرها لو محتاج تايمنج مختلف
setInterval(() => {
    exports.expireTimedOutRules();
}, EXPIRY_CHECK_INTERVAL_MS);