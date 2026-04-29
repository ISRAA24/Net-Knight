const mongoose = require('mongoose');

const ipRegex = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/([0-9]|[1-2][0-9]|3[0-2]))?$/;

const natRuleSchema = new mongoose.Schema({
    nat_type: {
        type: String,
        enum: ['masquerade', 'source', 'destination'],
        required: true
    },
    handleId: {
        type: Number,
        required: function () {
            return this.isActive;
        },
        default: null
    },
    
    source_ip: {
        type: String,
        match: [ipRegex, 'Invalid IPv4 address format for Source IP']
    },
    output_interface: { type: String },
    new_source_ip: {
        type: String,
        match: [ipRegex, 'Invalid IPv4 address format for New Source IP']
    },
    input_interface: { type: String },
    protocol: { type: String, enum: ['tcp', 'udp', 'any'] },
    dest_ip: {
        type: String,
        match: [ipRegex, 'Invalid IPv4 address format for Destination IP']
    },
    ext_port: { type: String },
    int_port: { type: String },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    isActive: { 
        type: Boolean, 
        default: true // الرول بتنزل مفعلة تلقائياً أول ما تتكريت
    },
    comment: { type: String },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true }
);

module.exports = mongoose.model('NatRule', natRuleSchema);
