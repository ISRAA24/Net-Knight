const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: ['ai_rule_pending', 'threat_alert', 'traffic_spike'],
        required: true
    },
    title:   { type: String, required: true }, 
    message: { type: String, required: true }, 
    severity: {
        type: String,
        enum: ['info', 'warning', 'high', 'critical'],
        default: 'info'
    },
    tag: { type: String }, 

    isRead: { type: Boolean, default: false },

   
    relatedId:    { type: mongoose.Schema.Types.ObjectId, refPath: 'relatedModel', default: null },
    relatedModel: { type: String, enum: ['AIRule', 'Threat', null], default: null },

    
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} }
}, { timestamps: true });


notificationSchema.index({ isRead: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);