const User = require('../models/User');
const logger = require('../utils/logger');

//POST /api/users
exports.addUser = async (req, res) => {
    try {
        const { username, email, password, role } = req.body;
        
        if (role === 'super_admin') {
            return res.status(403).json({ 
                message: 'Action denied. There can be only one Super Admin. You can only create Admins or Analysts.' 
            });
        }

       
        const userExists = await User.findOne({ $or: [{ email }, { username }] });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        
        const user = await User.create({
            username,
            email,
            password, 
            role: role || 'analyst', 
            isVerified: true ,
            mustChangedPassword: true,
        });

        return res.status(201).json({
            success: true,
            message: 'User created successfully',
            data   : { _id: user._id, username: user.username, email: user.email, role: user.role }
        });

    } catch (error) {
        logger.error(`addUser error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

//GET /api/users
exports.getAllUsers = async (req, res) => {
    try {
        const page  = Math.max(1, parseInt(req.query.page)  || 1);
        const limit = Math.min(100, parseInt(req.query.limit) || 20);
        const skip  = (page - 1) * limit;

        const [users, total] = await Promise.all([
            User.find().select('-password').sort({ createdAt: -1 }).skip(skip).limit(limit),
            User.countDocuments()
        ]);

        return res.status(200).json({
            success   : true,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data      : users
        });
    } catch (error) {
        logger.error(`getAllUsers error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

//DELETE /api/users/:id
exports.deleteUser = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        
        if (user.role === 'super_admin') {
            return res.status(400).json({ message: 'Cannot delete Super Admin account' });
        }

          // Prevent self-deletion
        if (user._id.equals(req.user._id)) {
            return res.status(400).json({ message: 'You cannot delete your own account' });
        }
        await user.deleteOne();
        return res.status(200).json({ success: true, message: 'User removed successfully' });
    } catch (error) {
        logger.error(`deleteUser error: ${error.message}`);
        return res.status(500).json({ success: false, message: error.message });
    }
};

//PUT /api/users/:id
exports.updateUser = async (req, res) => {
    try {
        
        const user = await User.findById(req.params.id);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        if (user.role === 'super_admin' && req.body.role && req.body.role !== 'super_admin') {
            return res.status(403).json({ 
                message: 'Action denied. Cannot downgrade or change role of the Root Super Admin.' 
            });
        }
        
        
        if (req.body.role === 'super_admin' && user.role !== 'super_admin') {
            return res.status(403).json({ 
                message: 'Action denied. There can be only one Root Super Admin. You cannot upgrade other users to this role.' 
            });
        }

        
        if (req.body.email && req.body.email !== user.email) {
            const emailExists = await User.findOne({ email: req.body.email });
            if (emailExists) return res.status(400).json({ message: 'Email already in use by another user' });
        }
        
        if (req.body.username && req.body.username !== user.username) {
            const usernameExists = await User.findOne({ username: req.body.username });
            if (usernameExists) return res.status(400).json({ message: 'Username already taken' });
        }

        user.username = req.body.username || user.username;
        user.email = req.body.email || user.email;
        user.role = req.body.role || user.role;

       
        if (req.body.password) {
            user.password = req.body.password;
        }

        const updatedUser = await user.save();

        return res.status(200).json({
            success: true,
            message: "User updated successfully",
            data: {
                _id: updatedUser._id,
                username: updatedUser.username,
                email: updatedUser.email,
                role: updatedUser.role
            }
        });

    } catch (error) {
        logger.error(`updateUser error: ${error.message}`);
        return res.status(500).json({ message: error.message });
    }
};