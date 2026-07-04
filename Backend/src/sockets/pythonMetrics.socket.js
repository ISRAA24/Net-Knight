const WebSocket = require('ws');
const logger = require('../utils/logger');
const { broadcastMetrics } = require('./dashboard.socket');

// ─────────────────────────────────────────────────────────────────────────────
// gateway/ws_monitor.py في Network_Scripts بيتصل كـ WebSocket **client خام**
// (مكتبة `websockets` بايثون — بروتوكول RFC6455 عادي) على settings.WS_NODE_URL
// (لازم تتظبط على ws://<node-host>:<PORT>/netknight/monitor).
//
// ⚠️ ده مختلف تمامًا عن Socket.IO (اللي إحنا شغالين بيه في dashboard.socket.js
// للـ Flutter clients). Socket.IO مش بروتوكول WebSocket خام — عنده الـ handshake
// وتنسيق الرسائل بتاعته (Engine.IO)، فـ client بروتوكول WS عادي زي بايثون هنا
// **مش هيقدر يتصل بيه خالص** مهما كان المسار. عشان كده محتاجين سيرفر WebSocket
// خام منفصل (المكتبة `ws`) على مسار مختلف (/netknight/monitor)، شغال على نفس
// الـ http.Server بتاع Node، وبعدين إحنا اللي نـ broadcast للـ Flutter عن طريق
// Socket.IO زي ما هو.
//
// شكل الرسالة الحقيقي اللي بايثون بيبعته كل ثانية (ws_monitor.py: _push_once):
// {
//   "inbound":  { "tls":n, "http":n, "ftp":n, "ssh":n, "tcp":n, "udp":n,
//                 "icmp":n, "dns":n, "dhcp":n, "other":n },
//   "outbound": { ...نفس المفاتيح... },
//   "cpu_usage": number, "memory_usage": number,
//   "packets_per_second": number, "active_connections": number,
//   "timestamp": number
// }
//
// ده مختلف تمامًا عن اللي POST /api/dashboard/metrics (الـ HTTP endpoint القديم)
// كان مستني: { packetsPerSecond, activeConnections, cpuUsage, memoryUsage,
// trafficChart: { HTTP: {inbound,outbound}, ... } } — camelCase، وترتيب تعشيش
// معكوس (بروتوكول هو المفتاح الأساسي مش اتجاه الحركة). Python فعليًا مبيستخدمش
// الـ HTTP endpoint ده خالص (مفيش أي استدعاء له في الكود كله) — كل الميتركس
// الحية بتعدي من هنا بس.
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
    const wss = new WebSocket.Server({ server: httpServer, path: METRICS_WS_PATH });

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