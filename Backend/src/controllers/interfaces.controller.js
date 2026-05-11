const firewallAgent = require('../config/firewallAgent');
const logger = require('../utils/logger');
const { logActivity } = require('../utils/activityLogger'); // لو بتسجلي في اللوجز

//GET /api/interfaces
exports.getInterfaces = async (req, res) => {
    try {
        
        const pythonResponse = await firewallAgent.get('/api/manage_interfaces');
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
        const { status, ipAddress } = req.body; 

        
        if (status === undefined && ipAddress === undefined) {
            return res.status(400).json({ success: false, message: "No data provided to update" });
        }

        let pythonResponse;
        let actionDetails = [];

        if (ipAddress !== undefined) {
            if (ipAddress === "" || ipAddress === null) {
                pythonResponse = await firewallAgent.post('/api/manage_interfaces', {
                    interface: interfaceRealName,
                    action: 'del_ip' 
                });
                actionDetails.push('IP Address deleted');
            } else {
               
                pythonResponse = await firewallAgent.post('/api/manage_interfaces', {
                    interface: interfaceRealName,
                    action: 'modify_ip',
                    new_ip: ipAddress
                });
                actionDetails.push(`IP changed to ${ipAddress}`);
            }

            if (pythonResponse.data.status === "error") {
                return res.status(400).json({ success: false, message: pythonResponse.data.message });
            }
        }

        
        if (status && (status === 'up' || status === 'down')) {
            pythonResponse = await firewallAgent.post('/api/manage_interfaces', {
                interface: interfaceRealName,
                action: status 
            });
            actionDetails.push(`Status changed to ${status}`);

            if (pythonResponse.data.status === "error") {
                return res.status(400).json({ success: false, message: pythonResponse.data.message });
            }
        }

        
        if (req.user && actionDetails.length > 0) {
            const { logActivity } = require('../utils/activityLogger');
            await logActivity(
                req.user._id, 
                req.user.username, 
                "Update Interface", 
                interfaceRealName,
                actionDetails.join(' | ')
            );
        }

        return res.status(200).json({
            success: true,
            message: `Interface ${interfaceRealName} updated successfully`,
            data: pythonResponse ? pythonResponse.data : null
        });

    } catch (error) {
        if (typeof logger !== 'undefined') {
            logger.error(`updateInterface error: ${error.message}`);
        }
        const statusCode = error.code === 'ECONNABORTED' ? 504 : 500;
        return res.status(statusCode).json({ 
            success: false, 
            message: "Failed to update interface on Firewall",
            details: error.response?.data || error.message
        });
    }
};