const User = require('../models/User');
exports.addUser = async (req, res) => {
    try {
        const { username, email, password, role } = req.body;
        if (!username || !email || !password) {
            return res.status(400).json({ message: 'Please provide all fields' });
        }

        if (role === 'super_admin') {
            return res.status(403).json({ 
                message: 'Action denied. There can be only one Root Super Admin. You can only create Admins or Analysts.' 
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
            isVerified: true 
        });

        if (user) {
            res.status(201).json({
                success: true,
                message: "User created successfully",
                data: {
                    _id: user._id,
                    username: user.username,
                    email: user.email,
                    role: user.role
                }
            });
        }

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};


exports.getAllUsers = async (req, res) => {
    try {
        
        const users = await User.find().select('-password').sort({ createdAt: -1 });
        res.status(200).json(users);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};


exports.deleteUser = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        
        if (user.role === 'super_admin') {
            return res.status(400).json({ message: 'Cannot delete Super Admin account' });
        }

        await user.deleteOne();
        res.status(200).json({ message: 'User removed successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};


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

        res.status(200).json({
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
        res.status(500).json({ message: error.message });
    }
};