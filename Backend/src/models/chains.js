const mongoose = require('mongoose');

const chainsSchema = new mongoose.Schema(
    {
    tableId: { 
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Table',
        required: true
    },
    name: { type: String, required: true},
    priority: { type: Number, required: true },
    policy: { type: String, required: true },
    hook: { type: String, required: true },
    type: { type: String, required: true },
    createdBy : { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
    
   
},
{ timestamps: true }

);


module.exports = mongoose.model('Chain', chainsSchema);