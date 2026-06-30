const mongoose = require('mongoose');

const aiRuleSchema = new mongoose.Schema({
    sourceIp: { type: String, required: true },
    action: { type: String, enum: ['drop', 'reject', 'accept'], required: true },
    reason: { type: String }, // ده الـ Explanation اللي هيظهر للأدمن
    threatId: { type: mongoose.Schema.Types.ObjectId, ref: 'Threat' }, 
    status: { 
        type: String, 
        enum: ['pending', 'approved', 'auto-approved', 'rejected'], 
        default: 'pending' 
    },
    reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    expireAt: { 
        type: Date, 
        expires: 0 
    }
}, { timestamps: true });

module.exports = mongoose.model('AIRule', aiRuleSchema);