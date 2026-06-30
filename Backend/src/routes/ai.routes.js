const express = require('express');
const router = express.Router();
const { 
    getAutoApproveStatus, receiveAIRule, 
    toggleAutoApprove, getAIRules, reviewAIRule,
    getAllThreats, receiveThreat 
} = require('../controllers/ai.controller');
const { protect, authorize } = require('../middleware/auth.middleware');

// 🔴 مسارات البايثون (لا تتطلب حماية حالياً لأنها تتم عبر نفق محلي/Tailscale)
router.get('/settings/auto-approve', getAutoApproveStatus);
router.post('/rules', receiveAIRule);
router.post('/threats', receiveThreat);

// 🔵 مسارات الفلاتر (تتطلب حماية بالـ Token)
router.put('/settings/auto-approve', protect, authorize('super_admin', 'admin'), toggleAutoApprove);
router.get('/rules', protect, getAIRules);
router.put('/rules/:ruleId/review', protect, authorize('super_admin', 'admin'), reviewAIRule);
router.get('/threats', protect, getAllThreats);

module.exports = router;