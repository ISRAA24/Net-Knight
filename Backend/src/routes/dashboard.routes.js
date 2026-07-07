const express = require('express');
const router  = express.Router();
const { receiveMetrics, getStats, receiveTrafficSpike } = require('../controllers/dashboard.controller');
const { protect } = require('../middleware/auth.middleware');


router.post('/metrics', receiveMetrics);
router.post('/traffic-spike', receiveTrafficSpike);
router.get('/stats', protect, getStats);

module.exports = router;