const User = require('../models/User');
const jwt = require('jsonwebtoken');
const sendEmail = require('../utils/sendEmail');
const crypto = require('crypto'); 

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

exports.signup = async (req, res) => {
    try {
        const { username, email, password } = req.body;
        const userCount = await User.countDocuments();
        if (userCount > 0) {
            return res.status(403).json({ 
                message: "System setup is already complete. Only Super Admin can add new users." 
            });
        }

        const verifyCode = Math.floor(100000 + Math.random() * 900000).toString();
        
        const user = await User.create({
            username,
            email,
            password,
            role: 'super_admin', 
            verificationCode: verifyCode,
            verificationCodeExpires: Date.now() + 10 * 60 * 1000, 
            isVerified: false
        });

    
        try {
            await sendEmail({
                email: user.email,
                subject: 'Email Verification Code',
                code: verifyCode
            });
            res.status(201).json({
                message: "Super Admin created. Please check email for verification code.",
                email: user.email
            });
        } catch (emailError) {
            console.error(emailError);
            res.status(500).json({ message: "User created but failed to send email." });
        }

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.verifyEmail = async (req, res) => {
    try {
        const { email, code } = req.body; 

        const user = await User.findOne({ 
            email, 
            verificationCode: code,
            verificationCodeExpires: { $gt: Date.now() } 
        });

        if (!user) {
            return res.status(400).json({ message: "Invalid or expired code" });
        }

        // تفعيل الحساب
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
        res.status(500).json({ message: error.message });
    }
};


exports.login = async (req, res) => {
    try {
        const { username, password } = req.body; 
        const user = await User.findOne({ username });

        if (user && (await user.matchPassword(password))) {
            if (!user.isVerified) {
                return res.status(401).json({ message: "Account not verified. Please verify your email." });
            }

            res.json({
                _id: user._id,
                username: user.username,
                email: user.email,
                role: user.role,
                token: generateToken(user._id)
            });
        } else {
            res.status(401).json({ message: 'Invalid username or password' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};


exports.resendCode = async (req, res) => {
    const { email } = req.body;
    const user = await User.findOne({ email });
    
    if(!user) return res.status(404).json({message: "User not found"});
    if(user.isVerified) return res.status(400).json({message: "User already verified"});

    const verifyCode = Math.floor(100000 + Math.random() * 900000).toString();
    user.verificationCode = verifyCode;
    user.verificationCodeExpires = Date.now() + 10 * 60 * 1000;
    await user.save();

    await sendEmail({
        email: user.email,
        subject: 'New Verification Code',
        code: verifyCode
    });

    res.json({message: "Code resent successfully"});
};