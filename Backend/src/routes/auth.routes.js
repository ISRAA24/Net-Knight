const express = require('express');
const router = express.Router();
const { signup, login, verifyEmail, resendCode } = require('../controllers/auth.controller');

router.post('/signup', signup);       
router.post('/login', login);        
router.post('/verify', verifyEmail);  
router.post('/resend-code', resendCode); 

module.exports = router;