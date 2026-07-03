const { broadcastMetrics } = require('../sockets/dashboard.socket');
const AIRule  = require('../models/AIRule');
const Threat  = require('../models/Threat');
const Rule    = require('../models/StaticRule');
const logger  = require('../utils/logger');
const { createNotification } = require('../utils/notificationHelper');
// ─────────────────────────────────────────────────────────────────────────────
// POST /api/dashboard/metrics  ← Python بيكلم الـ endpoint ده كل ثانية
//
// الـ body اللي Python بيبعته:
// {
//   "packetsPerSecond": 11456,
//   "activeConnections": 1449,
//   "cpuUsage": 67.5,
//   "memoryUsage": 71.2,
//   "trafficChart": {
//     "HTTP":  { "inbound": 2500, "outbound": 1800 },
//     "HTTPS": { "inbound": 4200, "outbound": 3100 },
//     "DNS":   { "inbound": 800,  "outbound": 750  },
//     "SSH":   { "inbound": 120,  "outbound": 95   }
//     ... (أي عدد من البروتوكولات)
//   }
// }
//
// Node.js بياخد الـ metrics دي، بيضيف الـ stats من MongoDB،
// وبيعمل broadcast لكل الـ Flutter clients المتوصلين عبر Socket.IO
// ─────────────────────────────────────────────────────────────────────────────
exports.receiveMetrics = async (req, res) => {
    try {
        const { packetsPerSecond, activeConnections, cpuUsage, memoryUsage, trafficChart } = req.body;

        if (cpuUsage === undefined || memoryUsage === undefined) {
            return res.status(400).json({ success: false, message: 'cpuUsage and memoryUsage are required' });
        }

        // broadcast للـ Flutter clients (non-blocking — مش محتاجين نستنى)
        broadcastMetrics({ packetsPerSecond, activeConnections, cpuUsage, memoryUsage, trafficChart })
            .catch(err => logger.error(`broadcastMetrics failed: ${err.message}`));

        // نرد على Python بسرعة
        return res.status(200).json({ success: true });

    } catch (error) {
        logger.error(`receiveMetrics error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/dashboard/stats  ← Flutter بيكلمها مرة واحدة وقت فتح الداشبورد
//
// بترجع الـ stats بدون realtime metrics
// (الـ realtime بييجي بعدين عبر Socket.IO)
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
// POST /api/dashboard/traffic-spike  ← Python بيكلمها لما يكشف spike غير طبيعي
//
// Body من Python:
// {
//   "interface":        "eth0",
//   "direction":        "inbound",       // inbound | outbound
//   "currentBandwidth": 2.3,             // القيمة الحالية
//   "threshold":        2.0,             // الـ threshold اللي اتعدى
//   "unit":             "Gbps",          // الوحدة
//   "message":          "..."            // اختياري - لو Python عايد يبعت message جاهزة
// }
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