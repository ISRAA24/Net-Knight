require('dotenv').config(); // تحميل المتغيرات البيئية
const express = require('express');
const cors = require('cors');
const connectDB = require('./src/config/db'); 
const authRoutes = require('./src/routes/auth.routes');
connectDB();

const app = express();
app.use(cors()); 
app.use(express.json()); 
app.use('/api/auth', authRoutes);
const PORT = process.env.PORT || 3003;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});