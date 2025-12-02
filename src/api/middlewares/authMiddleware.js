// src/api/middlewares/authMiddleware.js

const jwt = require('jsonwebtoken');
const User = require('../models/userModel');

const protect = async (req, res, next) => {
  let token;

  // 1. Đọc token từ header 'Authorization'
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    try {
      // 2. Lấy token ra khỏi header (loại bỏ chữ 'Bearer ')
      token = req.headers.authorization.split(' ')[1];

      // 3. Xác thực token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // 4. Lấy thông tin người dùng từ ID trong token (loại bỏ password)
      // và gắn vào object `req` để các route sau có thể sử dụng
      req.user = await User.findById(decoded.id).select('-password');

      // 5. Cho phép đi tiếp tới controller
      next();
    } catch (error) {
      console.error(error);
      res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    res.status(401).json({ message: 'Not authorized, no token' });
  }
};

const admin = (req, res, next) => {
  // Middleware này phải được dùng SAU middleware `protect`
  // vì nó cần `req.user` do `protect` tạo ra.
  if (req.user && req.user.role === 'admin') {
    next(); // Nếu là admin, cho đi tiếp
  } else {
    res.status(403).json({ message: 'Not authorized as an admin' }); // 403 Forbidden
  }
};

module.exports = { protect, admin };