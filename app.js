// app.js
const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./src/config/database');
const passport = require('passport');
const configurePassport = require('./src/config/passport');

const userRoutes = require('./src/api/routes/userRoutes');
const productRoutes = require('./src/api/routes/productRoutes');
const categoryRoutes = require('./src/api/routes/categoryRoutes');
const cartRoutes = require('./src/api/routes/cartRoutes');
const orderRoutes = require('./src/api/routes/orderRoutes');
const discountRoutes = require('./src/api/routes/discountRoutes'); 
const dashboardRoutes = require('./src/api/routes/dashboardRoutes'); 
const adminRoutes = require('./src/api/routes/adminRoutes');
const authRoutes = require('./src/api/routes/authRoutes'); 
const paymentRoutes = require('./src/api/routes/paymentRoutes');

// Nạp các biến môi trường từ file .env
dotenv.config();

// Kết nối tới database
connectDB();

const setupSwagger = require('./src/config/swagger');

const app = express();

// Cấu hình Passport
configurePassport();
app.use(passport.initialize());

// Middleware để cho phép các request từ domain khác
app.use(cors());

// Middleware để parse JSON body từ request
app.use(express.json());

// Một route test đơn giản
app.get('/', (req, res) => {
  res.json({ message: 'API is running successfully!' });
});

setupSwagger(app);

app.use('/api/users', userRoutes);
app.use('/api/products', productRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/discounts', discountRoutes); 
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/payment', paymentRoutes);

module.exports = app;