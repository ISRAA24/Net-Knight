const mongoose = require('mongoose');

const ipRegex = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/([0-9]|[1-2][0-9]|3[0-2]))?$/;

const natRuleSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: ['masquerade', 'snat', 'dnat'],
        required: true
    },
    handleId: { type: Number, required: true }, 
    tableName: { type: String, required: true },
    chainName: { type: String, required: true },
    sourceIp: {
        type: String,
        match: [ipRegex, 'Invalid IPv4 address format for Source IP']
    },
    outputInterface: { type: String },
    newSourceIp: {
        type: String,
        match: [ipRegex, 'Invalid IPv4 address format for New Source IP']
    },
    inputInterface: { type: String },
    protocol: { type: String, enum: ['tcp', 'udp', 'any'] },
    destinationIp: {
        type: String,
        match: [ipRegex, 'Invalid IPv4 address format for Destination IP']
    },
    externalPort: { type: String },
    internalPort: { type: String },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    isActive: { 
        type: Boolean, 
        default: true 
    }
}, { timestamps: true }
);

module.exports = mongoose.model('NatRule', natRuleSchema);