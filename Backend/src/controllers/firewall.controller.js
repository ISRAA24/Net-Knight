const net = require('net');
const Table = require('../models/tables');
const Chain = require('../models/chains');
const Rule = require('../models/StaticRule');
const firewallAgent = require('../config/firewallAgent');
const logger = require('../utils/logger');
const { validateIpFields, firewallError } = require('../utils/firewall.helpers');
const NATRule = require('../models/NATrules'); 


// ======================= TABLES =======================
exports.addTable = async (req, res) => {
    try {
        const { name, family } = req.body;
        await firewallAgent.post('/api/create_table', { table_name: name, family });
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

        await firewallAgent.post('/api/create_chain', {
            family: table.family,
            table_name: tableName,
            chain_name: name,
            chain_type: type,
            hook, priority,
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
            ['Source IP', ipSource],
            ['Destination IP', ipDestination]
        ]);


        if (!ipCheck.valid) {
            return res.status(400).json({ success: false, message: ipCheck.message });
        }


        const table = await Table.findOne({ name: tableName });
        if (!table) return res.status(404).json({ message: 'Table not found.' });

        action = action === 'deny' ? 'drop' : action;
        const comment = `rule_${Date.now()}`;
        

        const payload = {
            family: table.family,
            table_name: tableName,
            chain_name: chainName,
            ip_src: ipSource,        // كان ip_source
            ip_dest: ipDestination,  // كان ip_destination
            port_dest: portDestination ? String(portDestination) : "",
            interface: networkInterface,
            protocol,
            action,
            comment: comment
        };

        // send to firewall and get the handle_id back
        const firewallResponse = await firewallAgent.post('/api/add_rule', payload);
        const handleId = firewallResponse.data.handle;
        

        if (!handleId) {
    return res.status(500).json({ 
        success: false, 
        message: "Firewall Agent did not return a handle ID for the new rule.",
        details: firewallResponse.data.output || firewallResponse.data.message || "No handle returned"
    });
}


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
            comment: comment, 
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
// في ملف src/controllers/firewall.controller.js

exports.toggleRuleStatus = async (req, res) => {
    try {
        const rule = await Rule.findById(req.params.id);
        if (!rule) return res.status(404).json({ message: 'Rule not found' });

        const table = await Table.findOne({ name: rule.tableName });

        if (rule.isActive) {
            // 🛑 الحالة الأولى: الرول شغالة وعايزين "نقفلها"
            // هنبعت أمر delete للبايثون بس مش هنمسحها من الداتابيس
            const firewallResponse = await firewallAgent.post('/api/delete_rule', {
                family: table.family,
                table: rule.tableName,
                chain: rule.chainName,
                handle: rule.handleId
            });

            if (firewallResponse.data.status === "success") {
                rule.isActive = false;
                rule.handleId = null; // بنصفر الـ handle لأن اللينكس بيمسحه
                await rule.save();
                return res.json({ success: true, message: "Rule disabled (Removed from Firewall)", data: rule });
            }
        } else {
            // ✅ الحالة الثانية: الرول مقفولة وعايزين "نفتحها"
            // هنبعت أمر add_rule للبايثون باستخدام البيانات المتخزنة عندنا
            const payload = {
                table_name: rule.tableName,
                chain_name: rule.chainName,
                family: table.family,
                ip_src: rule.ipSource,
                ip_dest: rule.ipDestination,
                port_dest: rule.portDestination ? String(rule.portDestination) : "",
                protocol: rule.protocol,
                action: rule.action,
                comment: rule.comment // الكومنت اللي فيه الـ Tag الفريد بتاعنا
            };

            const firewallResponse = await firewallAgent.post('/api/add_rule', payload);

            if (firewallResponse.data.handle) {
                rule.isActive = true;
                rule.handleId = firewallResponse.data.handle; // بنخزن الـ handle الجديد
                await rule.save();
                return res.json({ success: true, message: "Rule enabled (Added to Firewall)", data: rule });
            }
        }

        return res.status(500).json({ success: false, message: "Firewall action failed" });
    } catch (error) {
        return firewallError(res, error);
    }
};


exports.deleteRule = async (req, res) => {
    try {
        const rule = await Rule.findById(req.params.id);
        if (!rule) return res.status(404).json({ message: 'Rule not found in DB' });

        const table = await Table.findOne({ name: rule.tableName });
        if (!table) return res.status(404).json({ message: 'Associated table not found in DB' });


        await firewallAgent.delete('/api/delete_rule', {  // أو POST لأن Python بيستخدم POST
            data: {
                family: table.family,
                table: rule.tableName,   // كان table_name
                chain: rule.chainName,   // كان chain_name
                handle: rule.handleId    // كان handle_id
            }
        });

        await rule.deleteOne();
        return res.status(200).json({ success: true, message: 'Rule deleted from Firewall and DB' });
    } catch (error) {
        return firewallError(res, error);
    }
};
exports.getAllRules = async (req, res) => {
    try {
        // جلب البيانات من الموديلين بترتيب الأحدث
        const [staticRules, natRules] = await Promise.all([
            Rule.find().sort({ createdAt: -1 }).lean(),
            NATRule.find().sort({ createdAt: -1 }).lean()
        ]);

        // تهيئة بيانات الـ Static Rules لتطابق الجدول في الصورة
        const formattedStatic = staticRules.map((r, index) => ({
            no: index + 1,
            id: r._id,
            sourceIp: r.ipSource || 'Any',
            destIp: r.ipDestination || 'Any',
            port: r.portDestination || 'Any',
            protocol: r.protocol.toUpperCase(),
            action: r.action,
            status: r.isActive !== undefined ? r.isActive : true, // مفتاح الحالة (Toggle)
            comment: r.comment
        }));

        // تهيئة بيانات الـ NAT Rules لتطابق الجدول في الصورة
        const formattedNat = natRules.map((r, index) => ({
            no: index + 1,
            id: r._id,
            protocol: r.protocol.toUpperCase(),
            externalIp: r.external_ip || 'Any',
            internalIp: r.internal_ip || 'Any',
            internalPort: r.internal_port || 'Any',
            action: r.action,
            status: r.isActive !== undefined ? r.isActive : true, // مفتاح الحالة (Toggle)
            comment: r.comment
        }));

        res.status(200).json({
            success: true,
            data: {
                staticRules: formattedStatic,
                natRules: formattedNat
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};