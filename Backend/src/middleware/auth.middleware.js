const jwt = require('jsonwebtoken');
const User = require('../models/User');

exports.protect = async (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer')) {
         return res.status(401).json({ message: 'Not authorized, no token' });
    }
    const token = authHeader.split(' ')[1];
        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            const user = await User.findById(decoded.id).select('-password');

        if (!user) {
            return res.status(401).json({ message: 'User belonging to this token no longer exists' });
        }

        if (!user.isVerified) {
            return res.status(401).json({ message: 'Account not verified' });
        }

        req.user = user;
        return next();
        } catch (error) {
            console.error(error);
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