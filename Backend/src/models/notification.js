const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: ['ai_rule_pending', 'threat_alert', 'traffic_spike'],
        required: true
    },
    title:   { type: String, required: true }, // "AI rule pending review"
    message: { type: String, required: true }, // الرسالة التفصيلية
    severity: {
        type: String,
        enum: ['info', 'warning', 'high', 'critical'],
        default: 'info'
    },
    tag: { type: String }, // النص اللي بيظهر في الـ badge: "Review needed" | "Warning" | "Critical" | "High"

    isRead: { type: Boolean, default: false },

    // ربط بالـ document المرتبط (AIRule أو Threat)
    relatedId:    { type: mongoose.Schema.Types.ObjectId, refPath: 'relatedModel', default: null },
    relatedModel: { type: String, enum: ['AIRule', 'Threat', null], default: null },

    // بيانات إضافية (ip، confidence، interface، bandwidth...)
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} }
}, { timestamps: true });

// index عشان جلب الـ unread بسرعة
notificationSchema.index({ isRead: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);