const mongoose = require('mongoose');

const ipRegex = /^(\d{1,3}\.){3}\d{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/;

const staticRuleSchema = new mongoose.Schema(
    {
        tableName: { type: String, required: true },
        chainName: { type: String, required: true },
        handleId: { type: Number, required: true },
        ipSource: {
            type: String,
            match: [ipRegex, 'Invalid IPv4 address for Source IP']
        },
        ipDestination: {
            type: String,
            match: [ipRegex, 'Invalid IPv4 address for Destination IP']
        },
        portDestination: { type: String },
        networkInterface: { type: String },          // renamed from 'interface' (reserved word)
        protocol: { type: String, enum: ['tcp', 'udp', 'icmp', 'any'] },
        action: { type: String, enum: ['accept', 'reject', 'drop', 'log'] },
        comment: { type: String, required: true },
        createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        isActive: {
            type: Boolean,
            default: true
        }
    },
    { timestamps: true }
);

module.exports = mongoose.model('StaticRule', staticRuleSchema);
