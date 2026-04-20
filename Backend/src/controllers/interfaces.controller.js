const firewallAgent = require('../services/firewallAgent');
const logger = require('../utils/logger');

//GET /api/interfaces
exports.getInterfaces = async (req, res) => {
    try {
        
        const pythonResponse = await firewallAgent.get('/api/interfaces');
        res.status(200).json({
            success: true,
            data: pythonResponse.data 
        });
    } catch (error) {
        logger.error(`Error fetching interfaces from Python: ${error.message}`);
         const status = error.code === 'ECONNABORTED' ? 504 : 500;
        return res.status(status).json({
            success: false,
            message: status === 504
                ? 'Firewall agent timed out.'
                : 'Failed to communicate with Firewall Agent',
            details: error.response?.data || error.message
        });
    }
};

//PUT /api/interfaces/:realName
exports.updateInterface = async (req, res) => {
    try {
        const interfaceRealName = req.params.realName; 
        const { logicalName, status, ipAddress } = req.body; 

        const payload = {
            real_name: interfaceRealName,
            logical_name: logicalName, 
            status: status,            
            ip_address: ipAddress      
        };

        
        const pythonResponse = await firewallAgent.put(`/api/interfaces/${interfaceRealName}`, payload);
        return res.status(200).json({
            success: true,
            message: `Interface ${interfaceRealName} updated successfully`,
            data: pythonResponse.data
        });
    } catch (error) {
        logger.error(`updateInterface error: ${error.message}`);
        const status = error.code === 'ECONNABORTED' ? 504 : 500;
        return res.status(status).json({ 
            success: false, 
            message: "Failed to update interface on Firewall",
            details: error.response?.data || error.message
        });
    }
};