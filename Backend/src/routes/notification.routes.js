const express = require('express');
const router  = express.Router();
const {
    getNotifications,
    getUnreadCount,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    clearAllNotifications
} = require('../controllers/notification.controller');
const { protect } = require('../middleware/auth.middleware');

// كل الـ notification routes بتطلب JWT (Flutter فقط)
router.use(protect);

router.get   ('/',               getNotifications);
router.get   ('/unread-count',   getUnreadCount);
router.patch ('/read-all',       markAllAsRead);
router.patch ('/:id/read',       markAsRead);
router.delete('/clear-all',      clearAllNotifications);
router.delete('/:id',            deleteNotification);

module.exports = router;