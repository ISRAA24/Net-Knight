const mongoose = require('mongoose');

const aiRuleSchema = new mongoose.Schema({
    requestId: { type: String, default: null },
    ruleName: { type: String }, 
    sourceIp:      { type: String, default: null },
    destinationIp: { type: String, default: null },
    action: { type: String, required: true },
    explanation: { type: String },
    description: { type: String },
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
    timeout: { type: Number, default: null },
    deletions: { type: Array, default: [] },
    isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('AIRule', aiRuleSchema);