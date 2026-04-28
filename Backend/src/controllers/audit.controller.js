const AuditLog = require('../models/AuditLog');

exports.getAuditLogs = async (req, res) => {
    try {
        // بنجيب الداتا ونرتبها من الأحدث للأقدم (-1)
        const logs = await AuditLog.find().sort({ createdAt: -1 }).lean();
        
        // تظبيط شكل الداتا عشان تناسب الجدول اللي في الصورة
        const formattedLogs = logs.map((log, index) => ({
            no: index + 1,
            date: log.createdAt, // الفرونت إند يقدر يفرمت التاريخ والوقت بمعرفته
            userName: log.adminName,
            action: log.action,
            target: log.target,
            details: log.details
        }));

        res.status(200).json({ success: true, data: formattedLogs });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};