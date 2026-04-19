const mongoose = require('mongoose');

// نفس شفرة التحقق من صحة الـ IP
const ipRegex = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/([0-9]|[1-2][0-9]|3[0-2]))?$/;

const natRuleSchema = new mongoose.Schema({
    type: { 
        type: String, 
        enum: ['masquerade', 'snat', 'dnat'], 
        required: true 
    },
    handleId: { type: Number, required: true }, // الرقم المرجعي من اللينكس
    tableName: { type: String, required: true },
    chainName: { type: String, required: true },
    sourceIp: { 
        type: String,
        match: [ipRegex, 'Invalid IPv4 address format for Source IP']
    },
    outputInterface: { type: String },
    
    // --- حقل خاص بـ SNAT ---
    newSourceIp: { 
        type: String,
        match: [ipRegex, 'Invalid IPv4 address format for New Source IP']
    },
    
    // --- حقول خاصة بـ DNAT ---
    inputInterface: { type: String },
    protocol: { type: String, enum: ['tcp', 'udp', 'any'] },
    destinationIp: { 
        type: String,
        match: [ipRegex, 'Invalid IPv4 address format for Destination IP']
    },
    externalPort: { type: String },
    internalPort: { type: String },

    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('NatRule', natRuleSchema);