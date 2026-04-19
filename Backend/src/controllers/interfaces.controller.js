const axios = require('axios');
const FIREWALL_API_URL = process.env.FIREWALL_API_URL || 'http://192.168.1.50:5000';

exports.getInterfaces = async (req, res) => {
    try {
        
        const pythonResponse = await axios.get(`${FIREWALL_API_URL}/api/interfaces`);
        res.status(200).json({
            success: true,
            data: pythonResponse.data 
        });
    } catch (error) {
        console.error("Error fetching interfaces from Python:", error.message);
        res.status(500).json({ 
            success: false, 
            message: "Failed to communicate with Firewall Agent",
            details: error.response?.data || error.message
        });
    }
};


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

        
        const pythonResponse = await axios.put(`${FIREWALL_API_URL}/api/interfaces/${interfaceRealName}`, payload);
        res.status(200).json({
            success: true,
            message: `Interface ${interfaceRealName} updated successfully`,
            data: pythonResponse.data
        });
    } catch (error) {
        console.error("Error updating interface via Python:", error.message);
        res.status(500).json({ 
            success: false, 
            message: "Failed to update interface on Firewall",
            details: error.response?.data || error.message
        });
    }
};