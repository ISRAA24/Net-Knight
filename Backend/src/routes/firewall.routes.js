const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth.middleware');
const { addTable, addChain, addRule, deleteRule,toggleRuleStatus,getAllRules , getTables,getChains} = require('../controllers/firewall.controller');
const { getInterfaces, updateInterface } = require('../controllers/interfaces.controller');
const { addNatRule, getNatRules, deleteNatRule, editNatRule,toggleNatRuleStatus } = require('../controllers/NAT.controller');
const {
    validate,
    addTableSchema, addChainSchema, addRuleSchema, addNatRuleSchema
} = require('../utils/validators');
const { getAuditLogs } = require('../controllers/audit.controller');

// All routes require authentication and 'super_admin' role 
router.use(protect);

// ── Read-write routes (super_admin + admin) ────────────────────────────────────

router.get('/nat', authorize('super_admin', 'admin'), getNatRules);
router.get('/interfaces', authorize('super_admin', 'admin'), getInterfaces);
router.get('/allRules', authorize('super_admin', 'admin'), getAllRules);
router.get('/tables', authorize('super_admin', 'admin'), getTables);
router.post('/tables', authorize('super_admin', 'admin'), validate(addTableSchema), addTable);
router.get('/chains', authorize('super_admin', 'admin'), getChains);
router.post('/chains', authorize('super_admin', 'admin'), validate(addChainSchema), addChain);
router.post('/rules', authorize('super_admin', 'admin'), validate(addRuleSchema), addRule);
router.delete('/rules/:id', authorize('super_admin', 'admin'), deleteRule);
router.put('/interfaces/:realName', authorize('super_admin', 'admin'), updateInterface);
router.post('/nat', authorize('super_admin', 'admin'), validate(addNatRuleSchema), addNatRule);
router.delete('/nat/:id', authorize('super_admin', 'admin'), deleteNatRule);
router.patch('/nat/:id/toggle', authorize('super_admin', 'admin'), toggleNatRuleStatus);
router.patch('/rules/:id/toggle', authorize('super_admin', 'admin'), toggleRuleStatus);
router.put('/nat/:id', authorize('super_admin', 'admin'), editNatRule);
router.get('/logs', authorize('super_admin', 'admin', 'analyst'), getAuditLogs);

module.exports = router;
