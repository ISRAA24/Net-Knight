const mongoose = require('mongoose');
const ipRegex = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/([0-9]|[1-2][0-9]|3[0-2]))?$/;

const staticRulesSchema = new mongoose.Schema({
    tablename: { type: String, required: true},
    chainname: { type: String, required: true},
    handleId: { type: Number, required: true },
    ipsource: { 
        type: String, 
        required: true,
        match: [ipRegex, 'Invalid IPv4 address format for Source IP']
     },
    ipdestination: { 
        type: String, 
        required: true,
        match: [ipRegex, 'Invalid IPv4 address format for Destination IP']
     },
    portdestination: { type: String, required: true },
    interface: { type: String },
    protocol: { type: String, enum: ['tcp', 'udp', 'icmp', 'any'] },
    action: { type: String, enum: ['accept', 'reject', 'drop', 'log'] },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    createdAt: { type: Date, default: Date.now }
    
   
});


module.exports = mongoose.model('StaticRule', staticRulesSchema);