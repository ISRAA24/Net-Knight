require('dotenv').config();

// ── Startup environment guards ──────────────────────────────────────────────
const REQUIRED_ENV = ['MONGO_URI', 'JWT_SECRET', 'EMAIL_USER', 'EMAIL_PASS'];
const missing = REQUIRED_ENV.filter((k) => !process.env[k]);
if (missing.length) {
    console.error(`FATAL: Missing required environment variables: ${missing.join(', ')}`);
    process.exit(1);
}
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const connectDB = require('./src/config/db');
const authRoutes = require('./src/routes/auth.routes');
const userRoutes = require('./src/routes/user.routes');
const firewallRoutes = require('./src/routes/firewall.routes');
const { errorHandler } = require('./src/middleware/error.middleware');
const logger = require('./src/utils/logger');
const cookieParser = require('cookie-parser');

connectDB();
app.use(cookieParser());
const app = express();
app.set('trust proxy', 1);
// ── Security middleware ──────────────────────────────────────────────────────
app.use(helmet());

const allowedOrigins = process.env.ALLOWED_ORIGINS
    ? process.env.ALLOWED_ORIGINS.split(',')
    : [];

app.use(cors({
    origin:(origin, cb) => {
        if (!origin) return cb(null, true);
        if (allowedOrigins.includes(origin)) return cb(null, true);
        cb(new Error(`CORS: origin '${origin}' not allowed`));
        },
        credentials: true
}));
app.use(express.json({ limit: '10kb' }));
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/staticfirewall', firewallRoutes);
app.use(errorHandler);

const PORT = process.env.PORT || 3003;
app.listen(PORT, () => {
    logger.info(`Server running on port ${PORT}`);
});