const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth.middleware');
const { addUser, getAllUsers, deleteUser , updateUser } = require('../controllers/user.controller');
const { validate, addUserSchema, updateUserSchema } = require('../utils/validators');


router.route('/')   
    .get(getAllUsers); 

router.use(protect);
router.use(authorize('super_admin', 'admin')); 

router.route('/')
    .post(validate(addUserSchema), addUser)     
    

router.route('/:id')
    .put(validate(updateUserSchema), updateUser)
    .delete(deleteUser);


module.exports = router;