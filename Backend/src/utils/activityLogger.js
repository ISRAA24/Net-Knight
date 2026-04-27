// src/utils/activityLogger.js
const AuditLog = require('../models/AuditLog');

exports.logActivity = async (adminId, adminName, action, target, details = "") => {
    try {
        await AuditLog.create({
            adminId,
            adminName,
            action,
            target,
            details
        });
    } catch (error) {
        console.error("⚠️ Failed to save audit log:", error.message);
    }
};