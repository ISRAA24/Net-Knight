const Notification = require('../models/notification');
const logger       = require('../utils/logger');

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/notifications
// ─────────────────────────────────────────────────────────────────────────────
exports.getNotifications = async (req, res) => {
    try {
        const page  = Math.max(1, parseInt(req.query.page)  || 1);
        const limit = Math.min(100, parseInt(req.query.limit) || 20);
        const skip  = (page - 1) * limit;

        const filter = {};
        if (req.query.isRead !== undefined) filter.isRead = req.query.isRead === 'true';
        if (req.query.type)                 filter.type   = req.query.type;

        const [notifications, total] = await Promise.all([
            Notification.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
            Notification.countDocuments(filter)
        ]);

        return res.status(200).json({
            success: true,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: notifications
        });
    } catch (error) {
        logger.error(`getNotifications error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/notifications/unread-count
// 
// ─────────────────────────────────────────────────────────────────────────────
exports.getUnreadCount = async (req, res) => {
    try {
        const count = await Notification.countDocuments({ isRead: false });
        return res.status(200).json({ success: true, count });
    } catch (error) {
        logger.error(`getUnreadCount error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// PATCH /api/notifications/:id/read
// ─────────────────────────────────────────────────────────────────────────────
exports.markAsRead = async (req, res) => {
    try {
        const notif = await Notification.findByIdAndUpdate(
            req.params.id,
            { isRead: true },
            { new: true }
        );
        if (!notif) return res.status(404).json({ success: false, message: 'Notification not found' });

        return res.status(200).json({ success: true, data: notif });
    } catch (error) {
        logger.error(`markAsRead error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// PATCH /api/notifications/read-all
// ─────────────────────────────────────────────────────────────────────────────
exports.markAllAsRead = async (req, res) => {
    try {
        const result = await Notification.updateMany({ isRead: false }, { isRead: true });
        return res.status(200).json({
            success: true,
            message: `${result.modifiedCount} notifications marked as read`
        });
    } catch (error) {
        logger.error(`markAllAsRead error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/notifications/:id
// Flutter: حذف notification واحدة
// ─────────────────────────────────────────────────────────────────────────────
exports.deleteNotification = async (req, res) => {
    try {
        const notif = await Notification.findByIdAndDelete(req.params.id);
        if (!notif) return res.status(404).json({ success: false, message: 'Notification not found' });

        return res.status(200).json({ success: true, message: 'Notification deleted' });
    } catch (error) {
        logger.error(`deleteNotification error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/notifications
// ─────────────────────────────────────────────────────────────────────────────
exports.clearAllNotifications = async (req, res) => {
    try {
        const result = await Notification.deleteMany({});
        return res.status(200).json({
            success: true,
            message: `${result.deletedCount} notifications cleared`
        });
    } catch (error) {
        logger.error(`clearAllNotifications error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};