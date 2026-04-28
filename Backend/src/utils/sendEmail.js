const nodemailer = require('nodemailer');
const logger = require('./logger');

const sendEmail = async (options) => {
    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: process.env.EMAIL_USER, 
            pass: process.env.EMAIL_PASS  
        }
    });

    const message = {
        from: `Net-Knight <${process.env.EMAIL_USER}>`,
        to: options.email,
        subject: options.subject,
        text: options.message,
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto;">
                <h2 style="color: #1a1a2e;">Net-Knight Verification</h2>
                <p>Your verification code is:</p>
                <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #e94560;">
                    ${options.code}
                </p>
                <p style="color: #666;">This code expires in <strong>10 minutes</strong>.</p>
                <p style="color: #999; font-size: 12px;">
                    If you did not request this, please ignore this email.
                </p>
            </div>`
    };
    try{
        await transporter.sendMail(message);
        logger.info(`Verification email sent to ${options.email}`);
    }catch (err) {
        logger.error(`Failed to send email to ${options.email}: ${err.message}`);
        throw err;
    }

    
};

module.exports = sendEmail;