const Joi = require('joi');

// ── Reusable schemas ──────────────────────────────────────────────────────────

const ipWithCidr = Joi.string()
    .pattern(/^(\d{1,3}\.){3}\d{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/)
    .allow('', null);

const portField = Joi.alternatives()
    .try(
        Joi.number().integer().min(1).max(65535),
        Joi.string().pattern(/^\d+:\d+$/)   // range e.g. "8080:8090"
    )
    .allow('', null);

// ── Auth ─────────────────────────────────────────────────────────────────────

exports.signupSchema = Joi.object({
    username : Joi.string().alphanum().min(3).max(30).required(),
    email    : Joi.string().email().required(),
    password : Joi.string().min(8).required()
});

exports.loginSchema = Joi.object({
    username : Joi.string().required(),
    password : Joi.string().required()
});

exports.verifyEmailSchema = Joi.object({
    email : Joi.string().email().required(),
    code  : Joi.string().length(6).pattern(/^\d+$/).required()
});

exports.resendCodeSchema = Joi.object({
    email: Joi.string().email().required()
});

exports.verifyLoginSchema = Joi.object({
    email : Joi.string().email().required(),
    code  : Joi.string().length(6).pattern(/^\d+$/).required()
});


// ── Users ─────────────────────────────────────────────────────────────────────

exports.addUserSchema = Joi.object({
    username : Joi.string().alphanum().min(3).max(30).required(),
    email    : Joi.string().email().required(),
    password : Joi.string().min(8).required(),
    role     : Joi.string().valid('admin', 'analyst').default('analyst')
});

exports.updateUserSchema = Joi.object({
    username : Joi.string().alphanum().min(3).max(30),
    email    : Joi.string().email(),
    password : Joi.string().min(8),
    role     : Joi.string().valid('admin', 'analyst')
}).min(1); // at least one field required

// ── Firewall ──────────────────────────────────────────────────────────────────

exports.addTableSchema = Joi.object({
    name   : Joi.string().min(1).max(50).required(),
    family : Joi.string().valid('ip', 'ip6', 'inet', 'arp', 'bridge', 'netdev').required()
});

exports.addChainSchema = Joi.object({
    tableName : Joi.string().required(),
    name      : Joi.string().required(),
    hook      : Joi.string().valid('prerouting','input','forward','output','postrouting').required(),
    priority  : Joi.number().integer().required(),
    policy    : Joi.string().valid('accept', 'deny', 'drop').required(),
    type      : Joi.string().valid('filter', 'nat', 'route').required()
});

exports.addRuleSchema = Joi.object({
    tableName       : Joi.string().required(),
    chainName       : Joi.string().required(),
    ipSource        : ipWithCidr,
    ipDestination   : ipWithCidr,
    portDestination : portField,
    networkInterface: Joi.string().allow('', null),
    protocol        : Joi.string().valid('tcp', 'udp', 'icmp', 'any').allow('', null),
    action          : Joi.string().valid('accept', 'reject', 'drop', 'log', 'deny').required()
});

// ── NAT ───────────────────────────────────────────────────────────────────────

exports.addNatRuleSchema = Joi.object({
    nat_type            : Joi.string().valid('masquerade', 'source', 'destination').required(),
    source_ip        : ipWithCidr,
    output_interface : Joi.string().allow('', null),
    new_source_ip     : ipWithCidr,
    protocol        : Joi.string().valid('tcp', 'udp', 'any').allow('', null),
    input_interface  : Joi.string().allow('', null),
    dest_ip   : ipWithCidr,
    ext_port    : portField,
    int_port    : portField
});

// ── Middleware factory ────────────────────────────────────────────────────────

/**
 * Returns an Express middleware that validates req.body against a Joi schema.
 * Sends 400 with a clear message on failure.
 */
exports.validate = (schema) => (req, res, next) => {
    const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
    if (error) {
        const details = error.details.map((d) => d.message).join('; ');
        return res.status(400).json({ success: false, message: `Validation error: ${details}` });
    }
    req.body = value; // use the sanitised + coerced value
    return next();
};
