const jwt = require('jsonwebtoken');
const User = require('../models/User');

exports.protect = async (req, res, next) => {
    let token;

    // ── أول حاجة: دور على الكوكي ────────────────────────────────────────
    if (req.cookies && req.cookies.token) {
        token = req.cookies.token;

    // ── تاني حاجة: دور على الـ Authorization Header (للـ API clients) ──
    } else if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
        return res.status(401).json({ message: 'Not authorized, no token' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user    = await User.findById(decoded.id).select('-password');

        if (!user) {
            return res.status(401).json({ message: 'User belonging to this token no longer exists' });
        }

        if (!user.isVerified) {
            return res.status(401).json({ message: 'Account not verified' });
        }

        req.user = user;
        return next();

    } catch (error) {
        return res.status(401).json({ message: 'Not authorized, token failed' });
    }
};

exports.authorize = (...roles) => (req, res, next) => {
        if (!req.user) {
             return res.status(401).json({ message: 'User not found' });
        }
        
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ 
                message: `User role '${req.user.role}' is not authorized to access this route` 
            });
        }
        return next();
    };