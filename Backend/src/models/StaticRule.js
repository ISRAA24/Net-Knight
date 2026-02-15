const mongoose = require('mongoose');

const staticRulesSchema = new mongoose.Schema({
    tablename: { type: String, required: true},
    chainname: { type: String, required: true},
    ipsource: { type: String, required: true },
    ipdestination: { type: String, required: true },
    portdestination: { type: String, required: true },
    action:{ type: String, required: true},
    protocol: { type: String, required: true},
    
   
});


module.exports = mongoose.model('StaticRule', staticRulesSchema);