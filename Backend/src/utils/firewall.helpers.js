const net    = require('net');
const logger = require('./logger');

/**
 * Validates an optional IPv4 address (with optional CIDR suffix).
 * Empty / null / undefined values are considered valid (field is optional).
 *
 * @param {string} value - e.g. "192.168.1.1" or "10.0.0.0/24"
 * @returns {boolean}
 */
const isValidIp = (value) => {
    if (!value || value.trim() === '') return true;
    const ipPart = value.split('/')[0];
    return net.isIPv4(ipPart);
};

/**
 * Validates multiple IP fields at once.
 * Returns the first failing field as { valid: false, message } or { valid: true }.
 *
 * @param {Array<[string, string]>} fields - Array of [label, value] pairs
 * @returns {{ valid: boolean, message?: string }}
 */
const validateIpFields = (fields) => {
    for (const [label, value] of fields) {
        if (!isValidIp(value)) {
            return {
                valid  : false,
                message: `Invalid IPv4 format for ${label}: ${value}`
            };
        }
    }
    return { valid: true };
};

/**
 * Sends a standardised error response for firewall agent failures.
 * Distinguishes between a timeout (504) and any other error (500).
 *
 * @param {import('express').Response} res
 * @param {Error} error - Axios error or generic Error
 */
const firewallError = (res, error) => {
    logger.error(`Firewall agent error: ${error.message}`);

    const isTimeout = error.code === 'ECONNABORTED' || error.code === 'ETIMEDOUT';
    const status    = isTimeout ? 504 : 500;
    const details   = error.response?.data || error.message;

    return res.status(status).json({
        success: false,
        message: isTimeout
            ? 'Firewall agent timed out. Check that the agent is running.'
            : 'Firewall agent error',
        details
    });
};

module.exports = { isValidIp, validateIpFields, firewallError };
