const AIRule  = require('../models/AIRule');
const Threat  = require('../models/Threat');
const Rule    = require('../models/StaticRule');
const logger  = require('../utils/logger');

// ─────────────────────────────────────────────────────────────────────────────
// Stats Cache — بنعمل DB queries كل 30 ثانية بس مش كل ثانية
// ─────────────────────────────────────────────────────────────────────────────
let cachedStats      = null;
let lastStatsFetchAt = 0;
const STATS_TTL_MS   = 30_000; // 30 ثانية

const fetchStats = async () => {
    const now = Date.now();
    if (cachedStats && now - lastStatsFetchAt < STATS_TTL_MS) return cachedStats;

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

    cachedStats = {
        totalThreats,
        blockedAttacks,
        activeRules: activeAiRules + activeStaticRules,
        pendingApprovals
    };
    lastStatsFetchAt = now;
    return cachedStats;
};

// بمسحنا الـ cache لما حاجة تتغير في الـ DB (approve/reject/delete)
exports.invalidateStatsCache = () => {
    cachedStats      = null;
    lastStatsFetchAt = 0;
};

let io = null;

exports.initDashboardSocket = (ioServer) => {
    io = ioServer;

    io.on('connection', async (socket) => {
        logger.info(`[Dashboard] Flutter connected: ${socket.id}`);

        // فور الاتصال نبعتله أحدث stats من غير ما يستنى
        try {
            const stats = await fetchStats();
            socket.emit('dashboard:update', { stats });
        } catch (err) {
            logger.error(`initDashboardSocket initial stats error: ${err.message}`);
        }

        socket.on('disconnect', () => {
            logger.info(`[Dashboard] Flutter disconnected: ${socket.id}`);
        });
    });
};

// بيتبعت من dashboard.controller كل ثانية لما Python يبعت metrics
exports.broadcastMetrics = async (metrics) => {
    if (!io) return;
    try {
        const stats = await fetchStats();
        io.emit('dashboard:update', {
            realtime: metrics, // من Python: cpu, memory, packets, trafficChart
            stats              // من MongoDB: threats, rules, pending
        });
    } catch (err) {
        logger.error(`broadcastMetrics error: ${err.message}`);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// broadcastNotification — بيتبعت من notificationHelper كل ما notification تتخلق
// بيبعت event 'notification:new' لكل الـ Flutter clients المتوصلين
// ─────────────────────────────────────────────────────────────────────────────
exports.broadcastNotification = (notification) => {
    if (!io) return;
    io.emit('notification:new', notification);
};