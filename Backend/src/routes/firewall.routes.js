const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth.middleware');
const {addTable,addChain,addRule,deleteRule} = require('../controllers/firewall.controller');

router.use(protect);
router.use(authorize('super_admin')); 

router.post('/tables', addTable);
router.post('/chains', addChain);
router.post('/rules', addRule);
router.delete('/rules/:id', deleteRule);

module.exports = router;