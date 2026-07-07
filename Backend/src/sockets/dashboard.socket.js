const AIRule = require('../models/AIRule');
const Threat = require('../models/Threat');
const Rule = require('../models/StaticRule');
const logger = require('../utils/logger');


let cachedStats = null;
let lastStatsFetchAt = 0;
const STATS_TTL_MS = 30_000;

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


exports.invalidateStatsCache = () => {
    cachedStats = null;
    lastStatsFetchAt = 0;
};

let io = null;

exports.initDashboardSocket = (ioServer) => {
    io = ioServer;

    io.on('connection', async (socket) => {
        logger.info(`[Dashboard] Flutter connected: ${socket.id}`);


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


exports.broadcastMetrics = async (metrics) => {
    if (!io) return;
    try {
        const stats = await fetchStats();
        io.emit('dashboard:update', {
            realtime: metrics,
            stats
        });
    } catch (err) {
        logger.error(`broadcastMetrics error: ${err.message}`);
    }
};


exports.broadcastNotification = (notification) => {
    if (!io) return;
    io.emit('notification:new', notification);
};