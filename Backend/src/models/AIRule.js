const mongoose = require('mongoose');

const aiRuleSchema = new mongoose.Schema({
    requestId: { type: String, default: null },
    ruleName: { type: String }, 
    sourceIp:      { type: String, default: null },
    destinationIp: { type: String, default: null },
    port:          { type: Number, default: null },

    action: { type: String, required: true },
    explanation: { type: String },
    explanationDetails: { type: mongoose.Schema.Types.Mixed, default: {} },
    description: { type: String },

    attackType: { type: String, default: null },
    confidence: { type: Number, min: 0, max: 100, default: null },
    severity:   { type: String, enum: ['low', 'medium', 'high', 'critical', null], default: null },
    rateLimit:  { type: String, default: null },

    family:    { type: String, default: 'inet' },
    tableName: { type: String },
    chainName: { type: String },
    handleId:  { type: Number, default: null }, 
    setName:   { type: String, default: null }, 
    status: {
        type: String,
        enum: ['pending', 'approved', 'auto-approved', 'rejected'],
        default: 'pending'
    },
    reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    threatId:   { type: mongoose.Schema.Types.ObjectId, ref: 'Threat', default: null },
    timeout: { type: Number, default: null },
    expireAt: { type: Date, default: null },
    deletions: { type: Array, default: [] },
    isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('AIRule', aiRuleSchema);