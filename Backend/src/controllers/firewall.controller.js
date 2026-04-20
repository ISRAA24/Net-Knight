const net = require('net');
const Table = require('../models/tables');
const Chain = require('../models/chains');
const Rule = require('../models/StaticRule');
const firewallAgent = require('../config/firewallAgent');
const logger = require('../utils/logger');
const { validateIpFields, firewallError } = require('../utils/firewall.helpers');


// ======================= TABLES =======================
exports.addTable = async (req, res) => {
    try {
        const { name, family } = req.body;
        await firewallAgent.post('/api/tables', { name, family });
        const newTable = await Table.create({ name, family, createdBy: req.user._id });
        res.status(201).json({ success: true, data: newTable });
    } catch (error) {
        return firewallError(res, error);
    }
};

// ======================= CHAINS =======================
exports.addChain = async (req, res) => {
    try {
        const { tableName, name, hook, priority, policy, type } = req.body;

        const table = await Table.findOne({ name: tableName });
        if (!table) return res.status(404).json({ message: 'Table not found' });

        const linuxPolicy = policy === 'deny' ? 'drop' : policy;

        await firewallAgent.post('/api/chains', {
            family: table.family,
            table_name: tableName,
            chain_name: name,
            type, hook, priority,
            policy: linuxPolicy
        });
        const newChain = await Chain.create({
            tableId: table._id, 
            name, 
            hook, 
            priority, 
            policy: linuxPolicy, 
            type, 
            createdBy: req.user._id
        });
        res.status(201).json({ success: true, data: newChain });
    } catch (error) {
        return firewallError(res, error);
    }
};

// ======================= RULES =======================
exports.addRule = async (req, res) => {
    try {
        let {
            tableName, chainName,
            ipSource, ipDestination, portDestination,
            networkInterface,
            protocol, action
        } = req.body;

        const ipCheck = validateIpFields([
            ['Source IP', ipSource ] ,
            ['Destination IP', ipDestination ]
        ]);


      if(!ipCheck.valid) {
        return res.status(400).json({ success: false, message: ipCheck.message });
      }


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
            interface: networkInterface,
            protocol: protocol,
            action: action
        };

        // send to firewall and get the handle_id back
        const firewallResponse = await firewallAgent.post('/api/rules', payload);
        const handleId = firewallResponse.data.handle_id;

    
        const newRule = await Rule.create({
            tableName, 
            chainName, 
            handleId, 
            ipSource, 
            ipDestination, 
            portDestination, 
            networkInterface, 
            protocol, 
            action, 
            createdBy: req.user._id
        });

        return res.status(201).json({ 
            success: true, 
            data: newRule, 
            message: `Rule added with handle: ${handleId}`
         });
    } catch (error) {
        return firewallError(res, error);
    }
};
exports.getRules = async (req, res) => {
    try {
        const page  = Math.max(1, parseInt(req.query.page)  || 1);
        const limit = Math.min(100, parseInt(req.query.limit) || 20);
        const skip  = (page - 1) * limit;

        const [rules, total] = await Promise.all([
            Rule.find().sort({ createdAt: -1 }).skip(skip).limit(limit),
            Rule.countDocuments()
        ]);

        return res.status(200).json({
            success: true, total, page,
            totalPages: Math.ceil(total / limit),
            data: rules
        });
    } catch (error) {
        logger.error(`getRules error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.deleteRule = async (req, res) => {
    try {
        const rule = await Rule.findById(req.params.id);
        if (!rule) return res.status(404).json({ message: 'Rule not found in DB' });

        const table = await Table.findOne({ name: rule.tableName });
        if (!table) return res.status(404).json({ message: 'Associated table not found in DB' });

       
        await firewallAgent.delete('/api/rules', {
            data: {
                family: table.family,
                table_name: rule.tableName,
                chain_name: rule.chainName,
                handle_id: rule.handleId
            }
        });

        await rule.deleteOne();
        return res.status(200).json({ success: true, message: 'Rule deleted from Firewall and DB' });
    } catch (error) {
        return firewallError(res, error);
    }
};