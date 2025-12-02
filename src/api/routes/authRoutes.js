// src/api/routes/authRoutes.js
const express = require('express');
const passport = require('passport');
const generateToken = require('../utils/generateToken'); // Import hàm tạo JWT cũ của bạn
const router = express.Router();

// @desc    Bắt đầu luồng đăng nhập Google
// @route   GET /api/auth/google
router.get(
  '/google',
  passport.authenticate('google', { scope: ['profile', 'email'] })
);

// @desc    Google gọi lại URL này sau khi user đồng ý
// @route   GET /api/auth/google/callback
router.get(
  '/google/callback',
  passport.authenticate('google', {
    failureRedirect: `${process.env.FRONTEND_URL}/login?error=true`,
    session: false, // Chúng ta dùng JWT, không dùng session
  }),
  (req, res) => {
    // Lúc này req.user đã có thông tin user nhờ Passport xử lý ở bước 3
    
    // 1. Tạo token
    const token = generateToken(req.user._id);

    // 2. Chuyển hướng về Frontend kèm theo token
    // Frontend sẽ lấy token từ URL này và lưu vào localStorage
    res.redirect(`${process.env.FRONTEND_URL}/login?token=${token}`);
  }
);

module.exports = router;