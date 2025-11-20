// seeder.js
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs'); // Cần bcrypt để hash password thủ công

// Load env vars
dotenv.config();

// Load models
const User = require('./src/api/models/userModel');
const Product = require('./src/api/models/productModel');
const Category = require('./src/api/models/categoryModel');
const Order = require('./src/api/models/orderModel'); // Import các model khác nếu bạn muốn seed data

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB Connected for Seeder...');
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

const importData = async () => {
  await connectDB();
  try {
    // Xóa dữ liệu cũ
    await User.deleteMany();
    await Product.deleteMany();
    await Category.deleteMany();
    // await Order.deleteMany();

    // Tạo tài khoản Admin
    const adminUser = await User.create({
      fullName: 'Admin User',
      email: 'khantrinh293@gmail.com',
      password: '123456', // Mật khẩu sẽ được hash tự động bởi pre-save hook trong model
      role: 'admin',
    });

    console.log('Admin user created!');

    // (Tùy chọn) Tạo thêm người dùng customer mẫu
    const customerUser = await User.create({
      fullName: 'Customer User',
      email: 'thinhskyduct@gmail.com',
      password: '123456',
    });

    console.log('Customer user created!');

    // (Tùy chọn) Tạo thêm dữ liệu mẫu khác
    // const sampleCategory = await Category.create({ name: 'Laptops', slug: 'laptops' });
    // console.log('Sample category created!');
    
    console.log('Data Imported!');
    process.exit();
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
};

const destroyData = async () => {
    await connectDB();
  try {
    await Order.deleteMany();
    await Product.deleteMany();
    await User.deleteMany();
    await Category.deleteMany();
    
    console.log('Data Destroyed!');
    process.exit();
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
};

// Lấy tham số từ dòng lệnh
if (process.argv[2] === '-d') {
  destroyData();
} else {
  importData();
}