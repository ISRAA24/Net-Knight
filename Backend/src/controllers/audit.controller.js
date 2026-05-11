const AuditLog = require('../models/AuditLog');

exports.getAuditLogs = async (req, res) => {
    try {
        
        const logs = await AuditLog.find().sort({ createdAt: -1 }).lean();
        
        const formattedLogs = logs.map((log, index) => ({
            no: index + 1,
            date: log.createdAt, 
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