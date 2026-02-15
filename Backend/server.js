require('dotenv').config(); 
const express = require('express');
const cors = require('cors');
const connectDB = require('./src/config/db'); 
const authRoutes = require('./src/routes/auth.routes');
const userRoutes = require('./src/routes/user.routes');
connectDB();

const app = express();
app.use(cors()); 
app.use(express.json()); 
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes); 
const PORT = process.env.PORT || 3003;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});