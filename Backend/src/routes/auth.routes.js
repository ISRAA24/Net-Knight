const express = require('express');
const router = express.Router();
const { signup, login, verifyEmail, resendCode , verifyLogin} = require('../controllers/auth.controller');
const rateLimit = require('express-rate-limit');
const { validate, signupSchema, loginSchema, verifyEmailSchema, resendCodeSchema, verifyLoginSchema } =
    require('../utils/validators');

// Rate limiters to prevent brute-force attacks    
router.use(
    ['/signup', '/verify', '/resend-code'],
    rateLimit({
        windowMs: 60 * 60 * 1000, // 1 hour
        max: 100,
        standardHeaders: true,
        legacyHeaders: false,
        message: { message: 'Too many code requests. Please try again in 1 hour.' }
    })
);

router.use(
    '/login',
    rateLimit({
        windowMs: 15 * 60 * 1000, // 15 minutes
        max: 100,
        standardHeaders: true,
        legacyHeaders: false,
        message: { message: 'Too many login attempts. Please try again in 15 minutes.' }
    })
);




// Routes
router.post('/signup', validate(signupSchema), signup);
router.post('/login', validate(loginSchema), login);
router.post('/verify', validate(verifyEmailSchema), verifyEmail);
router.post('/resend-code', validate(resendCodeSchema), resendCode);
router.post('/verify-login', validate(verifyLoginSchema), verifyLogin);
module.exports = router;