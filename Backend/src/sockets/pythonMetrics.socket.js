const WebSocket = require('ws');
const logger = require('../utils/logger');
const { broadcastMetrics } = require('./dashboard.socket');


// ─────────────────────────────────────────────────────────────────────────────

const METRICS_WS_PATH = '/netknight/monitor';
const PROTOCOL_BUCKETS = ['tls', 'http', 'ftp', 'ssh', 'tcp', 'udp', 'icmp', 'dns', 'dhcp', 'other'];

function transformPythonMetrics(msg) {
    const trafficChart = {};
    for (const bucket of PROTOCOL_BUCKETS) {
        trafficChart[bucket.toUpperCase()] = {
            inbound:  (msg.inbound  && msg.inbound[bucket])  || 0,
            outbound: (msg.outbound && msg.outbound[bucket]) || 0
        };
    }
    return {
        packetsPerSecond:  msg.packets_per_second ?? 0,
        activeConnections: msg.active_connections ?? 0,
        cpuUsage:          msg.cpu_usage ?? 0,
        memoryUsage:       msg.memory_usage ?? 0,
        trafficChart
    };
}

exports.initPythonMetricsSocket = (httpServer) => {
    
    const wss = new WebSocket.Server({ noServer: true });

    httpServer.on('upgrade', (req, socket, head) => {
        const { pathname } = new URL(req.url, `http://${req.headers.host}`);
        if (pathname !== METRICS_WS_PATH) return; // مش بتاعنا — سيبيه لـ Socket.IO

        wss.handleUpgrade(req, socket, head, (ws) => {
            wss.emit('connection', ws, req);
        });
    });

    wss.on('connection', (ws, req) => {
        logger.info(`[PythonMetrics] Firewall agent connected over WS (${req.socket.remoteAddress})`);

        ws.on('message', (data) => {
            let msg;
            try {
                msg = JSON.parse(data.toString());
            } catch (err) {
                logger.error(`[PythonMetrics] invalid JSON from agent: ${err.message}`);
                return;
            }

            try {
                const metrics = transformPythonMetrics(msg);
                broadcastMetrics(metrics).catch((err) =>
                    logger.error(`[PythonMetrics] broadcastMetrics failed: ${err.message}`)
                );
            } catch (err) {
                logger.error(`[PythonMetrics] transform error: ${err.message}`);
            }
        });

        ws.on('close', () => {
            logger.info('[PythonMetrics] Firewall agent WS disconnected');
        });

        ws.on('error', (err) => {
            logger.error(`[PythonMetrics] WS error: ${err.message}`);
        });
    });

    logger.info(`[PythonMetrics] WebSocket listener ready at ${METRICS_WS_PATH}`);
    return wss;
};

exports.METRICS_WS_PATH = METRICS_WS_PATH;
exports.transformPythonMetrics = transformPythonMetrics;