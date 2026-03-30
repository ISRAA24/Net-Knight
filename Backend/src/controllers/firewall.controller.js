const Table = require('../models/tables');
const Chain = require('../models/chains');
const Rule = require('../models/StaticRule');
const axios = require('axios');

const FIREWALL_API_URL = process.env.FIREWALL_API_URL || 'http://<FIREWALL_IP>:5000';

// ======================= TABLES =======================
exports.addTable = async (req, res) => {
    try {
        const { name, family } = req.body;
        await axios.post(`${FIREWALL_API_URL}/api/tables`, { name, family });
        const newTable = await Table.create({ name, family, createdBy: req.user._id });
        res.status(201).json({ success: true, data: newTable });
    } catch (error) {
        res.status(500).json({ success: false, message: "Firewall Error", details: error.response?.data || error.message });
    }
};

// ======================= CHAINS =======================
exports.addChain = async (req, res) => {
    try {
        const { tableName, name, hook, priority, policy, type } = req.body;
        
        const table = await Table.findOne({ name: tableName });
        if (!table) return res.status(404).json({ message: 'Table not found' });

        const linuxPolicy = policy === 'deny' ? 'drop' : policy;

        await axios.post(`${FIREWALL_API_URL}/api/chains`, {
            family: table.family,
            table_name: tableName,
            chain_name: name,
            type, hook, priority, policy: linuxPolicy
        });

        const newChain = await Chain.create({
            tableId: table._id, name, hook, priority, policy: linuxPolicy, type, createdBy: req.user._id
        });
        res.status(201).json({ success: true, data: newChain });
    } catch (error) {
        res.status(500).json({ success: false, message: "Firewall Error", details: error.response?.data || error.message });
    }
};

// ======================= RULES =======================
exports.addRule = async (req, res) => {
    try {
        let { tableName, chainName, ipSource, ipDestination, portDestination, interface, protocol, action } = req.body;

        const table = await Table.findOne({ name: tableName });
        if (!table) return res.status(404).json({ message: 'Table not found.' });

        action = action === 'deny' ? 'drop' : action;

        const payload = {
            family: table.family,
            table_name: tableName,
            chain_name: chainName,
            ip_source: ipSource,
            ip_destination: ipDestination,
            port_destination: portDestination,
            interface: interface,
            protocol: protocol,
            action: action
        };

        // 1. نبعت للفايروول وننتظر الـ Handle
        const firewallResponse = await axios.post(`${FIREWALL_API_URL}/api/rules`, payload);
        const handleId = firewallResponse.data.handle_id;

        // 2. نحفظ في الداتابيس مع الـ Handle ID
        const newRule = await Rule.create({
            tableName, chainName, handleId, ipSource, ipDestination, portDestination, interface, protocol, action, createdBy: req.user._id
        });

        res.status(201).json({ success: true, data: newRule, message: "Rule added with handle: " + handleId });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to apply rule", details: error.response?.data || error.message });
    }
};

exports.deleteRule = async (req, res) => {
    try {
        const rule = await Rule.findById(req.params.id);
        if (!rule) return res.status(404).json({ message: 'Rule not found in DB' });

        const table = await Table.findOne({ name: rule.tableName });

        // 1. مسح من الفايروول باستخدام الـ handle_id
        await axios.delete(`${FIREWALL_API_URL}/api/rules`, {
            data: {
                family: table.family,
                table_name: rule.tableName,
                chain_name: rule.chainName,
                handle_id: rule.handleId
            }
        });

        // 2. مسح من الداتابيس
        await rule.deleteOne();
        res.status(200).json({ success: true, message: 'Rule deleted from Firewall and DB' });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to delete rule", details: error.response?.data || error.message });
    }
};