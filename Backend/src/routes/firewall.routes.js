const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth.middleware');
const { addTable, addChain, addRule, getRules, deleteRule,toggleRuleStatus,getAllRules} = require('../controllers/firewall.controller');
const { getInterfaces, updateInterface } = require('../controllers/interfaces.controller');
const { addNatRule, getNatRules, deleteNatRule } = require('../controllers/NAT.controller');
const {
    validate,
    addTableSchema, addChainSchema, addRuleSchema, addNatRuleSchema
} = require('../utils/validators');

// All routes require authentication and 'super_admin' role 
router.use(protect);

// ── Read-only routes (super_admin + admin) ────────────────────────────────────
router.get('/rules', authorize('super_admin', 'admin'), getRules);
router.get('/nat', authorize('super_admin', 'admin'), getNatRules);
router.get('/interfaces', authorize('super_admin', 'admin'), getInterfaces);
router.get('/allRules', authorize('super_admin', 'admin'), getAllRules);
router.post('/tables', authorize('super_admin', 'admin'), validate(addTableSchema), addTable);
router.post('/chains', authorize('super_admin', 'admin'), validate(addChainSchema), addChain);
router.post('/rules', authorize('super_admin', 'admin'), validate(addRuleSchema), addRule);
router.delete('/rules/:id', authorize('super_admin', 'admin'), deleteRule);
router.put('/interfaces/:realName', authorize('super_admin', 'admin'), updateInterface);
router.post('/nat', authorize('super_admin', 'admin'), validate(addNatRuleSchema), addNatRule);
router.delete('/nat/:id', authorize('super_admin', 'admin'), deleteNatRule);
router.patch('/rules/:id/toggle', authorize('super_admin', 'admin'), toggleRuleStatus);

module.exports = router;