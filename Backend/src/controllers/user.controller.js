const User = require('../models/User');
exports.addUser = async (req, res) => {
    try {
        const { username, email, password, role } = req.body;
        if (!username || !email || !password) {
            return res.status(400).json({ message: 'Please provide all fields' });
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