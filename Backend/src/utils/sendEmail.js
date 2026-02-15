const nodemailer = require('nodemailer');

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
        html: `<h1>Net-Knight Verification </h1>
               <p>Your verification code is: <b style="font-size: 24px;">${options.code}</b></p>
               <p>This code expires in 10 minutes.</p>`
    };

    await transporter.sendMail(message);
};

module.exports = sendEmail;