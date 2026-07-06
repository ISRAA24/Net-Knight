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
const { initPythonMetricsSocket } = require('./src/sockets/pythonMetrics.socket');

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

const server = http.createServer(app);
 
const io = new Server(server, {
    cors: {
        origin: '*', 
        methods: ['GET', 'POST']
    }
});
 

initDashboardSocket(io);


initPythonMetricsSocket(server);

const PORT = process.env.PORT || 3003;


server.listen(PORT, '0.0.0.0', () => {
    logger.info(`Server running on port ${PORT}`);
    logger.info(`Socket.IO ready for Flutter clients`);
    logger.info(`Python firewall agent WS listener ready on /netknight/monitor`);
});