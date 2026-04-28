const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth.middleware');
const { addUser, getAllUsers, deleteUser , updateUser } = require('../controllers/user.controller');
const { validate, addUserSchema, updateUserSchema } = require('../utils/validators');

// All user-management routes require a valid token AND super_admin role
router.use(protect);
router.use(authorize('super_admin', 'admin')); // ممكن نخلي الأدمين يشوف بس مش يعدل

router.route('/')
    .post(validate(addUserSchema), addUser)     
    .get(getAllUsers); 

router.route('/:id')
    .put(validate(updateUserSchema), updateUser)
    .delete(deleteUser);


module.exports = router;