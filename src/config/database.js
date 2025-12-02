// src/config/database.js
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`❌ MongoDB Connection Error: ${error.message}`);
    console.log('🔄 MongoDB Retrying in 5 seconds...');
    
    // Thay vì thoát luôn (process.exit(1)), ta đợi 5s rồi thử kết nối lại
    setTimeout(connectDB, 5000);
  }
};

module.exports = connectDB;