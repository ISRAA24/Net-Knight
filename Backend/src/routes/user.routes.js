const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth.middleware');
const { addUser, getAllUsers, deleteUser } = require('../controllers/user.controller');


router.use(protect);
router.use(authorize('super_admin'));

router.route('/')
    .post(addUser)     
    .get(getAllUsers); 

router.route('/:id')
    .delete(deleteUser); 

module.exports = router;