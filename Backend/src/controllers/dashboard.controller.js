const { broadcastMetrics } = require('../sockets/dashboard.socket');
const AIRule  = require('../models/AIRule');
const Threat  = require('../models/Threat');
const Rule    = require('../models/StaticRule');
const logger  = require('../utils/logger');
const { createNotification } = require('../utils/notificationHelper');
// ─────────────────────────────────────────────────────────────────────────────
// POST /api/dashboard/metrics  ← Python بيكلم الـ endpoint ده كل ثانية
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveMetrics = async (req, res) => {
    try {
        const { cpu_usage, memory_usage, packets_per_second, active_connections, traffic_chart } = req.body;

        if (cpu_usage === undefined || memory_usage === undefined) {
            return res.status(400).json({ success: false, message: 'cpu_usage and memory_usage are required' });
        }

        
        broadcastMetrics({ packetsPerSecond: packets_per_second, activeConnections: active_connections, cpuUsage: cpu_usage, memoryUsage: memory_usage, trafficChart: traffic_chart })
            .catch(err => logger.error(`broadcastMetrics failed: ${err.message}`));

        
        return res.status(200).json({ success: true });

    } catch (error) {
        logger.error(`receiveMetrics error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/dashboard/stats  ← Flutter بيكلمها مرة واحدة وقت فتح الداشبورد
// ─────────────────────────────────────────────────────────────────────────────
exports.getStats = async (req, res) => {
    try {
        const [
            totalThreats,
            blockedAttacks,
            activeAiRules,
            activeStaticRules,
            pendingApprovals
        ] = await Promise.all([
            Threat.countDocuments(),
            AIRule.countDocuments({ status: { $in: ['approved', 'auto-approved'] } }),
            AIRule.countDocuments({ status: { $in: ['approved', 'auto-approved'] }, isActive: true }),
            Rule.countDocuments({ isActive: true }),
            AIRule.countDocuments({ status: 'pending' })
        ]);

        return res.status(200).json({
            success: true,
            data: {
                totalThreats,
                blockedAttacks,
                activeRules: activeAiRules + activeStaticRules,
                pendingApprovals
            }
        });
    } catch (error) {
        logger.error(`getStats error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/dashboard/traffic-spike 
//
// ─────────────────────────────────────────────────────────────────────────────
// POST /api/netknight/bandwidth-alert  
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
// [Legacy] POST /api/dashboard/traffic-spike
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveTrafficSpike = async (req, res) => {
    try {
        const {
            interface: iface,
            direction,
            currentBandwidth,
            threshold,
            unit = 'Gbps',
            message
        } = req.body;
 
        if (!iface || !direction) {
            return res.status(400).json({ success: false, message: 'interface and direction are required' });
        }
 
        const notifMessage = message
            || `${direction.charAt(0).toUpperCase() + direction.slice(1)} traffic on ${iface} exceeded ${threshold} ${unit} — monitoring in progress`;
 
        await createNotification({
            type:     'traffic_spike',
            title:    'Unusual traffic spike',
            message:  notifMessage,
            severity: 'warning',
            tag:      'Warning',
            metadata: { interface: iface, direction, currentBandwidth, threshold, unit }
        });
 
        return res.status(200).json({ success: true, message: 'Traffic spike recorded' });
    } catch (error) {
        logger.error(`receiveTrafficSpike error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};