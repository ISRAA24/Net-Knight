const User = require('../models/User');
const jwt = require('jsonwebtoken');
const sendEmail = require('../utils/sendEmail');
const logger = require('../utils/logger');         
const { logActivity } = require('../utils/activityLogger');

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

const generateVerifyCode = () =>
    Math.floor(100000 + Math.random() * 900000).toString();

//POST /api/auth/signup
exports.signup = async (req, res) => {
    try {
        const { username, email, password } = req.body;
        // Only one super_admin is allowed — everyone else must be added by that super_admin
        const userCount = await User.countDocuments();
        if (userCount > 0) {
            return res.status(403).json({ 
                message: "System setup is already complete. Only Super Admin can add new users." 
            });
        }

        const verifyCode = generateVerifyCode();
        
        const user = await User.create({
            username,
            email,
            password,
            role: 'super_admin', 
            verificationCode: verifyCode,
            verificationCodeExpires: Date.now() + 10 * 60 * 1000, 
            isVerified: false
        });

    
        
        await sendEmail({
            email: user.email,
            subject: 'Net-Knight , Email Verification Code',
            code: verifyCode
        });
        res.status(201).json({
            message: "Super Admin created. Please check email for verification code.",
            email: user.email
        });
        

    } catch (error) {
        logger.error(`signup error: ${error.message}`);
        // If user was created but email failed, surface a useful message
        if (error.message?.includes('email') || error.message?.includes('ECONNREFUSED')) {
            return res.status(500).json({ message: 'Account created but verification email failed to send. Contact support.' });
        }
        return res.status(500).json({ message: error.message });
    }
};

// POST /api/auth/verify
exports.verifyEmail = async (req, res) => {
    try {
        const { email, code } = req.body; 

        const user = await User.findOne({ 
            email, 
            verificationCode: code,
            verificationCodeExpires: { $gt: Date.now() } 
        });

       if (
            !user ||
            user.verificationCode !== code ||
            user.verificationCodeExpires < Date.now()
        ) {
            return res.status(400).json({ message: 'Invalid or expired verification code' });
        }

        
        user.isVerified = true;
        user.verificationCode = undefined;
        user.verificationCodeExpires = undefined;
        await user.save();

        res.status(200).json({ 
            message: "Account verified successfully!",
            token: generateToken(user._id),
            user: {
                id: user._id,
                username: user.username,
                role: user.role
            }
        });

    } catch (error) {
        logger.error(`verifyEmail error: ${error.message}`);
        return res.status(500).json({ message: error.message });
    }
};

// POST /api/auth/login
// POST /api/auth/login
// Validates credentials then sends a one-time login verification code to the user's email.
// The client must follow up with POST /api/auth/verify-login to receive the token.
exports.login = async (req, res) => {
    try {
        const { username, password } = req.body; 
        const user = await User.findOne({ username });
 
        if (!user || !(await user.matchPassword(password))) {
            return res.status(401).json({ message: 'Invalid username or password' });
        }
 
        if (!user.isVerified) {
            return res.status(401).json({ message: 'Account not verified. Please check your email.' });
        }
 
        // Generate a fresh login verification code
        const loginCode = generateVerifyCode();
        user.verificationCode = loginCode;
        user.verificationCodeExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
        await user.save();
 
        await sendEmail({
            email: user.email,
            subject: 'Net-Knight, Login Verification Code',
            code: loginCode
        });
 
        return res.status(200).json({
            message: "Verification code sent to your email. Please verify to complete login.",
            email: user.email
        });
 
    } catch (error) {
        logger.error(`login error: ${error.message}`);
        return res.status(500).json({ message: error.message });
    }
};
 
// POST /api/auth/verify-login
// Confirms the one-time code sent during login and returns the JWT token.
exports.verifyLogin = async (req, res) => {
    try {
        const { email, code } = req.body;

        const user = await User.findOne({
            email,
            verificationCode: code,
            verificationCodeExpires: { $gt: Date.now() }
        });

        if (!user) {
            return res.status(400).json({ message: 'Invalid or expired verification code' });
        }

        user.verificationCode = undefined;
        user.verificationCodeExpires = undefined;
        await user.save();

        await logActivity(
            user._id,
            user.username,
            "System Login",
            "System",
            "Admin logged into the dashboard"
        );

        const token = generateToken(user._id);

        // ── بعت التوكن في httpOnly Cookie ──────────────────────────────
        res.cookie('token', token, {
            httpOnly: true,
            secure  : process.env.NODE_ENV === 'production',
            sameSite: 'strict',
            expires : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 يوم
        });

        return res.status(200).json({
            _id                : user._id,
            username           : user.username,
            email              : user.email,
            role               : user.role,
            mustChangedPassword: user.mustChangedPassword
            // التوكن اتشال من الـ JSON
        });

    } catch (error) {
        logger.error(`verifyLogin error: ${error.message}`);
        return res.status(500).json({ message: error.message });
    }
};
 

// POST /api/auth/resend-code
exports.resendCode = async (req, res) => {
    try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    
    if(!user) return res.status(404).json({message: "User not found"});
    if(user.isVerified) return res.status(400).json({message: "User already verified"});

    const verifyCode = generateVerifyCode();
    user.verificationCode = verifyCode;
    user.verificationCodeExpires = Date.now() + 10 * 60 * 1000;
    await user.save();

    await sendEmail({
        email: user.email,
        subject: 'Net-Knight, New Verification Code',
        code: verifyCode
    });

    res.json({message: "Code resent successfully"});
} catch (error) {
    logger.error(`resendCode error: ${error.message}`);
    return res.status(500).json({ message: error.message });
}
};

// ======================= 3. LOGOUT =======================
exports.logout = async (req, res) => {
    try {
        if (req.user) {
            await logActivity(
                req.user._id,
                req.user.username,
                "System Logout",
                "System",
                "Admin logged out of the dashboard"
            );
        }

        // ── امسح الكوكي ─────────────────────────────────────────────────
        res.cookie('token', 'none', {
            httpOnly: true,
            expires : new Date(Date.now() + 10 * 1000) // تنتهي فوراً
        });

        return res.status(200).json({
            success: true,
            message: 'Logged out successfully'
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};