const express = require('express');
const router = express.Router();
const {
    getAutoApproveStatus,
    receiveAIRule,
    toggleAutoApprove,
    getAIRules,
    reviewAIRule,
    getAllThreats,
    receiveThreat,
    deleteAIRule,
    toggleAIRuleStatus,
    receiveAlert,
    receiveBandwidthAlert
} = require('../controllers/ai.controller');
const { protect, authorize } = require('../middleware/auth.middleware');

// ─────────────────────────────────────────────────────────────────────────────
// 🔴  مسارات الـ Python Agent (بدون auth — بتشتغل عبر نفق Tailscale محلي)
// ─────────────────────────────────────────────────────────────────────────────
router.get('/settings/auto-approve', getAutoApproveStatus);
router.post('/rules', receiveAIRule);
router.post('/threats', receiveThreat);

// ─────────────────────────────────────────────────────────────────────────────
// 🔵  مسارات الـ Flutter (بتطلب JWT Token)
// ─────────────────────────────────────────────────────────────────────────────

// Auto Approve setting
router.put('/settings/auto-approve', protect, authorize('super_admin', 'admin'), toggleAutoApprove);

// AI Rules — CRUD + Review + Toggle
router.get('/rules', protect, getAIRules);
router.put('/rules/:ruleId/review', protect, authorize('super_admin', 'admin'), reviewAIRule);
router.delete('/rules/:id', protect, authorize('super_admin', 'admin'), deleteAIRule);
router.patch('/rules/:id/toggle', protect, authorize('super_admin', 'admin'), toggleAIRuleStatus);
router.post('/netknight/alerts', receiveAlert);
router.post('/netknight/bandwidth-alert', receiveBandwidthAlert);

// Threats
router.get('/threats', protect, getAllThreats);

module.exports = router;