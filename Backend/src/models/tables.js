const mongoose = require('mongoose');

const tableSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    family: {
        type: String, 
        required: true
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }
   
}
, { timestamps: true }
);


module.exports = mongoose.model('Table', tableSchema);