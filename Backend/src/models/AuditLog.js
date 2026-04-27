// src/models/AuditLog.js
const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
    adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    adminName: { type: String, required: true }, 
    action: { type: String, required: true },   
    target: { type: String, required: true },    
    details: { type: String }                  
}, { timestamps: true }); 

module.exports = mongoose.model('AuditLog', auditLogSchema);