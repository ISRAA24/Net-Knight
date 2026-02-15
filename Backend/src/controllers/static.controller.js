const StaticRule = require('../models/StaticRule');
exports.addRule= async (req, res) => {
    try {
        const { tablename, chainname, ipsource, ipdestination, portdestination, action, protocol } = req.body;
        if (!tablename || !chainname || !ipsource || !ipdestination || !portdestination || !action || !protocol) {
            return res.status(400).json({ message: 'Please provide all fields' });
        }

        const staticRule = await StaticRule.create({
            tablename,
            chainname,
            ipsource,
            ipdestination,
            portdestination,
            action,
            protocol
        });

        res.status(201).json({
            success: true,
            message: "Static rule created successfully",
            data: staticRule
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
        


exports.getAllRules = async (req, res) => {
    try {
        
        const staticRules = await StaticRule.find().sort({ createdAt: -1 });
        res.status(200).json(staticRules);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};


exports.deleteRule = async (req, res) => {
    try {
        const staticRule = await StaticRule.findById(req.params.id);

        if (!staticRule) {
            return res.status(404).json({ message: 'Static rule not found' });
        }

        
        await staticRule.deleteOne();
        res.status(200).json({ message: 'Static rule removed successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};