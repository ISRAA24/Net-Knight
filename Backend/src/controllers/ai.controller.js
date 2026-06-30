const AIRule = require('../models/AIRule');
const StaticRule = require('../models/StaticRule'); // الموديل بتاع Rule Management
const Threat = require('../models/Threat');
const SystemSetting = require('../models/SystemSetting');
const firewallAgent = require('../config/firewallAgent');
const logger = require('../utils/logger');
const { logActivity } = require('../utils/activityLogger');

// ─────────────────────────────────────────────────────────────────────────────
// 1. API لـ Python Agent: بيسأل هل الـ Auto Approve متفعل؟
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
// 2. API لـ Python Agent: بيبعت الرول بعد ما قرر يطبقها أو يستنى
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveAIRule = async (req, res) => {
    try {
        const { sourceIp, action, reason, threatId, status, durationInSeconds } = req.body;
        
        let expirationDate = undefined;
        if (durationInSeconds) {
            expirationDate = new Date(Date.now() + durationInSeconds * 1000); 
        }

        // تتسيف في شاشة الـ AI Rules بس
        const newAIRule = await AIRule.create({ 
            sourceIp, 
            action, 
            reason, 
            threatId, 
            status, // هياخد 'auto-approved' أو 'pending'
            expireAt: expirationDate 
        });

        res.status(201).json({ success: true, message: `Rule recorded as ${status}`, data: newAIRule });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 3. API لـ Flutter: لتغيير حالة زرار Auto Approve
// ─────────────────────────────────────────────────────────────────────────────
exports.toggleAutoApprove = async (req, res) => {
    try {
        const { autoApprove } = req.body;
        let setting = await SystemSetting.findOne();
        if (!setting) setting = new SystemSetting();
        
        setting.autoApproveAiRules = autoApprove;
        await setting.save();

        await logActivity(req.user._id, req.user.username, 'System Setting', 'AI', `Auto Approve changed to ${autoApprove}`);
        res.status(200).json({ success: true, message: `Auto Approve updated`, autoApprove: setting.autoApproveAiRules });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// 4. API لـ Flutter: جلب كل الـ AI Rules لعرضها في الشاشة
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
// 5. API لـ Flutter: الأدمن بيدوس Approve أو Reject
// ─────────────────────────────────────────────────────────────────────────────
exports.reviewAIRule = async (req, res) => {
    try {
        const { ruleId } = req.params;
        const { decision } = req.body; // 'approve' or 'reject'

        const aiRule = await AIRule.findById(ruleId);
        if (!aiRule) return res.status(404).json({ success: false, message: 'Rule not found' });
        if (aiRule.status !== 'pending') return res.status(400).json({ success: false, message: 'Rule already reviewed' });

        if (decision === 'approve') {
            // نبعت للبايثون يطبقها
            const r = await firewallAgent.post('/api/manage_rules', {
                sourceIp: aiRule.sourceIp,
                action: aiRule.action,
                type: 'ai_dynamic'
            });
            
            if (r.data.status === 'error') {
                return res.status(400).json({ success: false, message: r.data.message });
            }

            aiRule.status = 'approved';
            aiRule.reviewedBy = req.user._id;
            await aiRule.save();

        } else if (decision === 'reject') {
            aiRule.status = 'rejected';
            aiRule.reviewedBy = req.user._id;
            await aiRule.save();
        }

        await logActivity(req.user._id, req.user.username, `AI Rule ${decision}`, aiRule.sourceIp, `Admin ${decision}d rule`);
        res.status(200).json({ success: true, message: `Rule ${decision}d successfully` });
    } catch (error) {
        logger.error(`reviewAIRule error: ${error.message}`);
        res.status(500).json({ success: false, message: error.message });
    }
};
// ─────────────────────────────────────────────────────────────────────────────
// 6. API لـ Python Agent: بيبعت التهديدات (Threats) لما يكتشفها
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveThreat = async (req, res) => {
    try {
        // بنستقبل الداتا من سكريبت البايثون
        const { sourceIp, attackType, severity, details } = req.body;
        
        // بنسيفها في الداتابيس
        const newThreat = await Threat.create({ 
            sourceIp, 
            attackType, 
            severity, // 'low', 'medium', 'high', 'critical'
            details 
        });

        // بنسجل اللوج في ملفات السيرفر
        logger.warn(`🚨 New Threat Detected! IP: ${sourceIp}, Type: ${attackType}`);

        res.status(201).json({ success: true, message: 'Threat recorded successfully', data: newThreat });
    } catch (error) {
        logger.error(`receiveThreat error: ${error.message}`);
        res.status(500).json({ success: false, message: error.message });
    }
};
// ─────────────────────────────────────────────────────────────────────────────
// 7. API لـ Flutter: جلب كل التهديدات (Threats) لعرضها في الشاشة
// ─────────────────────────────────────────────────────────────────────────────
exports.getAllThreats = async (req, res) => {
    try {
        // بنجيب كل التهديدات ونرتبها من الأحدث للأقدم
        const threats = await Threat.find().sort({ createdAt: -1 });

        res.status(200).json({ success: true, count: threats.length, data: threats });
    } catch (error) {
        logger.error(`getAllThreats error: ${error.message}`);
        res.status(500).json({ success: false, message: error.message });
    }
};