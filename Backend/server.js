require('dotenv').config();

// ── Startup environment guards ──────────────────────────────────────────────
const REQUIRED_ENV = ['MONGO_URI', 'JWT_SECRET', 'EMAIL_USER', 'EMAIL_PASS'];
const missing = REQUIRED_ENV.filter((k) => !process.env[k]);
if (missing.length) {
    console.error(`FATAL: Missing required environment variables: ${missing.join(', ')}`);
    process.exit(1);
}
const http = require('http');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const {Server} = require('socket.io');

const connectDB = require('./src/config/db');
const authRoutes = require('./src/routes/auth.routes');
const userRoutes = require('./src/routes/user.routes');
const firewallRoutes = require('./src/routes/firewall.routes');
const aiRoutes = require('./src/routes/ai.routes');
const dashboardRoutes     = require('./src/routes/dashboard.routes');
const notificationRoutes = require('./src/routes/notification.routes');
const { errorHandler } = require('./src/middleware/error.middleware');
const logger = require('./src/utils/logger');
const cookieParser = require('cookie-parser');
const { initDashboardSocket } = require('./src/sockets/dashboard.socket');
const { WebSocketServer } = require('ws');
connectDB();

const app = express();
app.set('trust proxy', 1);
app.use(cookieParser());

const corsOptions = {
    origin: (origin, cb) => {
        return cb(null, true);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
};

app.use(cors(corsOptions));
app.options(/(.*)/, cors(corsOptions));
// ── Security middleware ──────────────────────────────────────────────────────
app.use(helmet({
    contentSecurityPolicy: false, 
}));
app.use(express.json({ limit: '10kb' }));

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/staticfirewall', firewallRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/notifications',   notificationRoutes);
app.use(errorHandler);

// ── HTTP Server + Socket.IO ──────────────────────────────────────────────────
// لازم نعمل http.createServer عشان Socket.IO يشتغل على نفس الـ port
const server = http.createServer(app);
 
const io = new Server(server, {
    cors: {
        origin: '*', // Flutter بيتوصل من أي مكان
        methods: ['GET', 'POST']
    }
});

const wss = new WebSocketServer({ noServer: true });

server.on('upgrade', (request, socket, head) => {
    const pathname = request.url;
    // لو الطلب جاي من بايثون للـ monitor
    if (pathname === '/netknight/monitor') {
        wss.handleUpgrade(request, socket, head, (ws) => {
            wss.emit('connection', ws, request);
        });
    }
});

wss.on('connection', (ws) => {
    logger.info('Python Agent connected via Raw WebSocket');
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            // لو Python بيبعت metrics عبر الـ WebSocket بدل الـ HTTP
            if (data.cpu_usage !== undefined) {
                // نستخدم نفس المنطق اللي عملناه في الـ Dashboard Controller
                // وننادي على broadcastMetrics()
            }
        } catch(e) {
            logger.error(`WS Parse error: ${e.message}`);
        }
    });
});
 
// بدأنا الـ Socket.IO للداشبورد
initDashboardSocket(io);

const PORT = process.env.PORT || 3003;
app.listen(PORT, '0.0.0.0', () => {
    logger.info(`Server running on port ${PORT}`);
    logger.info(`Socket.IO ready for Flutter clients`)
});