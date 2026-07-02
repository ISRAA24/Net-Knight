const express = require('express');
const router  = express.Router();
const { receiveMetrics, getStats } = require('../controllers/dashboard.controller');
const { protect } = require('../middleware/auth.middleware');

// 🔴 Python Agent — بدون auth (Tailscale محلي)
router.post('/metrics', receiveMetrics);

// 🔵 Flutter — بتطلب JWT
router.get('/stats', protect, getStats);

module.exports = router;