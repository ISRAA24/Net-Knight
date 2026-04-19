const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth.middleware');
const {addTable,addChain,addRule,deleteRule} = require('../controllers/firewall.controller');
const { getInterfaces, updateInterface } = require('../controllers/interfaces.controller');
const {addNatRule,deleteNatRule} = require('../controllers/NAT.controller');


router.use(protect);
router.use(authorize('super_admin')); 

router.post('/tables', addTable);
router.post('/chains', addChain);
router.post('/rules', addRule);
router.delete('/rules/:id', deleteRule);
router.get('/interfaces', getInterfaces); 
router.put('/interfaces/:realName', updateInterface); 
router.post('/nat', addNatRule);
router.delete('/nat/:id', deleteNatRule);


module.exports = router;