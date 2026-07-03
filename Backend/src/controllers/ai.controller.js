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
// ⚠️ كانت هنا bug: كانت بتقرأ rule.ipDestination بس الحقل في الـ schema اسمه
// destinationIp، فكانت أي رول متعمّلة بـ destination IP بس (من غير source) بترجع
// ip = undefined هنا. اتصلحت.
// ─────────────────────────────────────────────────────────────────────────────
const getRuleIp = (rule) => rule.sourceIp || rule.destinationIp;

// ─────────────────────────────────────────────────────────────────────────────
// 1. Flutter/Python: هل الـ Auto Approve متفعل؟
// GET /api/ai/settings/auto-approve
//
// ⚠️ كانت القيمة دي بترجع من MongoDB بس، من غير ما تتقارن بالقيمة الحقيقية
// الشغالة على firewall agent (Network_Scripts: gateway/approval_gateway.py
// بيحتفظ بمتغير _auto_approve منفصل تمامًا، بيتغيّر بس عن طريق
// POST /config/auto_approve). دلوقتي بنسأل الـ agent نفسه ونزامن Mongo عليه.
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
            // الـ agent مش متاح دلوقتي — نرجع آخر قيمة معروفة بدل ما نكسر الطلب
            logger.error(`Could not reach firewall agent for auto_approve status: ${err.message}`);
        }

        res.status(200).json({ success: true, autoApprove: setting.autoApproveAiRules });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 2. Network_Scripts (approval_gateway.py → node_client.send_alert):
//    بتبعت "alert" واحد موحّد (كشف + قرار المعالجة مع بعض) سواء اتطبقت فورًا
//    (auto_approve=True) أو لسه pending (auto_approve=False).
//
// POST /api/netknight/alerts   ← ده المسار الحقيقي (node_client.ALERTS_ENDPOINT)
//                                 اتحط في src/routes/netknight.routes.js
//
// شكل الـ body الحقيقي (approval_gateway._build_alert_payload):
// {
//   request_id, description, explanation, explanation_details,
//   attack_type, confidence, severity, action, time,
//   rule: {
//     family, table, chain, set, src_ip, dest_ip, port,
//     timeout, rate_limit,
//     handle_id?, deletion?   ← موجودين بس لو اتطبقت فعلاً (auto-approved)
//   }
// }
//
// ده بيحل محل الـ endpoint القديم غلط (/api/ai/rules) اللي مكنش بيتنادى خالص
// من Network_Scripts، وكان شكل الـ body بتاعه مختلف تمامًا (flat fields:
// sourceIp/ipDestination) عن اللي الـ Python فعليًا بيبعته (rule.src_ip/dest_ip
// جوّه object متداخل).
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

        // وجود deletion/handle_id هو الدليل الوحيد إن Network_Scripts طبّق القاعدة
        // فعلاً على الفور (auto_approve=True وقت القرار) — راجع include_handle في
        // approval_gateway._build_alert_payload.
        const isApplied = !!(rule.deletion || rule.handle_id);
        const status    = isApplied ? 'auto-approved' : 'pending';
        const ip         = rule.src_ip || rule.dest_ip;
        const expireAt   = rule.timeout ? new Date(Date.now() + rule.timeout * 1000) : null;

        // 1) نسجل التهديد (Threat) — Network_Scripts معندوش endpoint منفصل للتهديد
        //    (receiveThreat/POST /api/ai/threats القديم مش بينادَى خالص)، فبنستنتج
        //    الـ Threat من نفس الـ alert عشان "Total Threats" في الداشبورد يفضل معناها له.
        const newThreat = await Threat.create({
            sourceIp:   ip,
            attackType: attackType || 'unknown',
            severity:   ['low', 'medium', 'high', 'critical'].includes(severity) ? severity : 'medium',
            confidence: confidence ?? null,
            details:    description || explanation || ''
        });

        // 2) نسجل قاعدة الـ AI (AIRule) مرتبطة بالـ Threat
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
            severity:    ['low', 'medium', 'high', 'critical'].includes(severity) ? severity : null,
            rateLimit:   rule.rate_limit || null,
            family:      rule.family || 'inet',
            tableName:   rule.table  || null,
            chainName:   rule.chain  || null,
            setName:     rule.set    || null,
            handleId:    rule.handle_id || null,
            timeout:     rule.timeout   || null,
            expireAt,
            status,
            isActive:    isApplied,
            threatId:    newThreat._id
        });

        // 3) Notification حسب الحالة
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
            const tag = severity ? severity.charAt(0).toUpperCase() + severity.slice(1) : 'Warning';
            const notifSeverity = ['critical', 'high'].includes(severity) ? severity : 'warning';
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
// ⚠️ Network_Scripts النهارده بيبعت على /api/netknight/alerts (receiveAlert فوق)
// مش هنا. سايبين الـ endpoint ده شغال بس لإدخال يدوي/اختبار، مش ده اللي
// الـ Python agent بينادّيه فعليًا.
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveAIRule = async (req, res) => {
    try {
        const {
            sourceIp, destinationIp, action, reason, threatId, status,
            durationInSeconds, ruleName,
            family, tableName, chainName, handleId, setName
        } = req.body;

        if (!sourceIp && !destinationIp) {
            return res.status(400).json({
                success: false,
                message: 'Either sourceIp or destinationIp is required.'
            });
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
//
// ⚠️ كانت بتحدّث Mongo بس من غير ما تبلّغ firewall agent، فالإعداد الحقيقي
// الشغال جوّه approval_gateway.py (متغير _auto_approve) كان بيفضل زي ما هو
// (False دايمًا افتراضيًا) بغض النظر عن اللي الأدمن ضغط عليه في الفلاتر.
// دلوقتي بنبعت للـ agent الأول (POST /config/auto_approve) وبعدين نحدّث Mongo.
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
//
// ⚠️ كان بينادي /api/manage_rules اللي مش موجود خالص في enforcement_api.py.
// الـ Python agent الحقيقي عنده POST /decisions/approve و POST /decisions/reject
// وبس، وبياخدوا request_id (مش تفاصيل الرول تاني)، لإن approval_gateway.py
// بيحتفظ بالحالة كاملة (_pending dict) عنده هو، وبيرجع نفس شكل الـ alert
// (فيه rule.handle_id) كـ رد مباشر على approve.
//
// ⚠️ الطلبات الـ pending عند Network_Scripts ليها TTL (PENDING_REQUEST_TTL_SEC
// = 24 ساعة) ومحفوظة في الذاكرة بس (مش persisted) — لو الـ agent اترستارت أو
// عدّت 24 ساعة، الـ request_id هيبقى "منتهي" والـ approve/reject هيرجع 404.
// ─────────────────────────────────────────────────────────────────────────────
exports.reviewAIRule = async (req, res) => {
    try {
        const { ruleId }   = req.params;
        const { decision } = req.body; // 'approve' or 'reject'

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
                message: 'This rule has no request_id from the firewall agent — it cannot be approved/rejected remotely (probably created manually).'
            });
        }

        if (decision === 'approve') {
            const r = await firewallAgent.post('/decisions/approve', { request_id: aiRule.requestId });
            const payload = r.data; // نفس شكل الـ alert لكن معاه rule.handle_id دلوقتي

            aiRule.status     = 'approved';
            aiRule.reviewedBy = req.user._id;
            aiRule.isActive   = true;

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
        // enforcement_api.py بيرجع 404 لو الـ request_id مش موجود/منتهي عند الـ agent
        if (error.response?.status === 404) {
            return res.status(409).json({
                success: false,
                message: 'The firewall agent no longer has this pending request (it may have expired or the agent restarted). The rule was not applied.'
            });
        }
        return firewallError(res, error);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 6. [Legacy / يدوي فقط] POST /api/ai/threats
// ⚠️ Network_Scripts معندوش أي استدعاء لهذا الـ endpoint — الـ Threat بيتسجل
// دلوقتي تلقائيًا جوه receiveAlert (فوق) مع كل alert. سايبينه شغال للإدخال
// اليدوي/الاختبار بس.
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveThreat = async (req, res) => {
    try {
        const { sourceIp, attackType, severity, confidence, details } = req.body;

        const newThreat = await Threat.create({
            sourceIp,
            attackType,
            severity,
            confidence: confidence || null,
            details
        });

        logger.warn(`🚨 Threat Detected! IP: ${sourceIp} | Type: ${attackType} | Severity: ${severity}`);

        const tag = severity
            ? severity.charAt(0).toUpperCase() + severity.slice(1)
            : 'Warning';

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
//
// ⚠️ كان بينادي /api/delete_element و /api/delete_rule بالـ DELETE method —
// المسارين دول مش موجودين في enforcement_api.py خالص. الـ Python agent عنده
// مسار واحد بس للحذف: POST /rules/delete، بياخد { mode, family, table, chain,
// handle } (mode="handle") أو { mode, family, table, set, ip, port }
// (mode="set_element") — POST مش DELETE، وشكل التفاصيل مختلف شوية عن اللي
// كنا باعتينه.
// ─────────────────────────────────────────────────────────────────────────────
exports.deleteAIRule = async (req, res) => {
    try {
        const rule = await AIRule.findById(req.params.id);
        if (!rule) return res.status(404).json({ success: false, message: 'AI Rule not found' });

        const ip        = getRuleIp(rule);
        const isApplied = ['approved', 'auto-approved'].includes(rule.status) && rule.isActive;

        if (isApplied) {
            let deletion = null;

            if (rule.setName) {
                deletion = {
                    mode:   'set_element',
                    family: rule.family || 'inet',
                    table:  rule.tableName,
                    set:    rule.setName,
                    ip
                };
                if (rule.port) deletion.port = rule.port;
            } else if (rule.handleId) {
                deletion = {
                    mode:   'handle',
                    family: rule.family || 'inet',
                    table:  rule.tableName,
                    chain:  rule.chainName,
                    handle: rule.handleId
                };
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
//
// ⚠️ تعارض معماري حقيقي: enforcement_api.py الحالي معندوش أي endpoint بيضيف
// رول اتشالت قبل كده تاني (مفيش /rules/add أو حاجة شبهها — بس /rules/delete،
// /decisions/approve|reject، و /config/auto_approve). يعني:
//   • Disable ممكنة فعلاً (بنستخدم نفس /rules/delete بتاع الحذف، بس من غير
//     ما نمسح الـ document من الـ DB).
//   • Enable (رجّع الرول تاني بعد التعطيل) مش ممكنة حاليًا بالـ agent ده —
//     هترجع 501 وواضح ليه، لحد ما يتضاف endpoint مناظر في Network_Scripts.
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
            let deletion = null;

            if (rule.setName) {
                deletion = {
                    mode:   'set_element',
                    family: rule.family || 'inet',
                    table:  rule.tableName,
                    set:    rule.setName,
                    ip
                };
                if (rule.port) deletion.port = rule.port;
            } else if (rule.handleId) {
                deletion = {
                    mode:   'handle',
                    family: rule.family || 'inet',
                    table:  rule.tableName,
                    chain:  rule.chainName,
                    handle: rule.handleId
                };
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

            rule.isActive = false;
            rule.handleId = null;
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

        // Re-enable: مش مدعومة من firewall agent الحالي (شوفي الملاحظة فوق).
        return res.status(501).json({
            success: false,
            message: 'Re-enabling a disabled AI rule is not supported by the firewall agent yet (no rule-creation endpoint in Network_Scripts). Delete this rule instead, or ask the agent side to add one.'
        });

    } catch (error) {
        return firewallError(res, error);
    }
};