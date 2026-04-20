const axios = require('axios');

/**
 * Pre-configured axios instance for the Python firewall agent.
 * Timeout prevents indefinite hangs when the agent is unreachable.
 */
const firewallAgent = axios.create({
    baseURL: process.env.FIREWALL_API_URL,
    timeout: 8000,  // 8 seconds
    headers: { 'Content-Type': 'application/json' }
});

module.exports = firewallAgent;
