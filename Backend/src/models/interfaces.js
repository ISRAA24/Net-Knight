const mongoose = require('mongoose');
 
const interfaceSchema = new mongoose.Schema(
    {
        logicalName: {
            type: String,
            required: true,
            unique: true,
            trim: true
        },
        realName: {
            type: String,
            required: true,
            unique: true,
            trim: true
        },
        ipAddress: {
            type: String,
            default: null
        },
        status: {
            type: String,
            enum: ['up', 'down', 'unknown'],
            default: 'unknown'
        },
        macAddress: {
            type: String,
            default: null
        },
        notes: {
            type: String,
            default: ''
        },
        lastSyncedAt: {
            type: Date,
            default: null
        },
        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }
    },
    { timestamps: true }
);
 
module.exports = mongoose.model('Interface', interfaceSchema);
 