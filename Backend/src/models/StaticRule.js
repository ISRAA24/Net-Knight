const mongoose = require('mongoose');

const staticRulesSchema = new mongoose.Schema({
    tablename: { type: String, required: true},
    chainname: { type: String, required: true},
    handleId: { type: Number, required: true },
    ipsource: { type: String, required: true },
    ipdestination: { type: String, required: true },
    portdestination: { type: String, required: true },
    interface: { type: String }, // من الصورة: ens33
    protocol: { type: String, enum: ['tcp', 'udp', 'icmp', 'any'] },
    action: { type: String, enum: ['accept', 'reject', 'drop', 'log'] }, // deny بتبقى drop
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    createdAt: { type: Date, default: Date.now }
    
   
});


module.exports = mongoose.model('StaticRule', staticRulesSchema);