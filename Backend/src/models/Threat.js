const mongoose = require('mongoose');

const threatSchema = new mongoose.Schema({
    sourceIp: { type: String, required: true },
    attackType: { type: String, required: true }, 
    severity: { type: String, enum: ['low', 'medium', 'high', 'critical'], default: 'medium' },
    details: { type: String },
    status: { type: String, enum: ['active', 'mitigated', 'ignored'], default: 'active' },
}, { timestamps: true });

module.exports = mongoose.model('Threat', threatSchema);