const express = require('express');
const router = express.Router();
const { signup, login, verifyEmail, resendCode } = require('../controllers/auth.controller');
const rateLimit = require('express-rate-limit');
const { validate, signupSchema, loginSchema, verifyEmailSchema, resendCodeSchema } =
    require('../utils/validators');


// Rate limiters to prevent brute-force attacks    
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 10,
    standardHeaders: true,
    legacyHeaders: false,
    message: { message: 'Too many login attempts. Please try again in 15 minutes.' }
});

const emailLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 5,
    standardHeaders: true,
    legacyHeaders: false,
    message: { message: 'Too many code requests. Please try again in 1 hour.' }
});

// Routes
router.post('/signup', emailLimiter, validate(signupSchema), signup);
router.post('/login', loginLimiter, validate(loginSchema), login);
router.post('/verify', emailLimiter, validate(verifyEmailSchema), verifyEmail);
router.post('/resend-code', emailLimiter, validate(resendCodeSchema), resendCode);
module.exports = router;