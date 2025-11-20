// src/config/passport.js
const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const User = require('../api/models/userModel');
const crypto = require('crypto');

const configurePassport = () => {
  passport.use(
    new GoogleStrategy(
      {
        clientID: process.env.GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        callbackURL: '/api/auth/google/callback',
      },
      async (accessToken, refreshToken, profile, done) => {
        try {
          // profile chứa thông tin user từ Google
          const email = profile.emails[0].value;
          
          // 1. Kiểm tra xem user đã tồn tại chưa
          let user = await User.findOne({ email });

          if (user) {
            // Nếu user đã tồn tại nhưng chưa có googleId (đăng ký bằng form thường), cập nhật googleId
            if (!user.googleId) {
              user.googleId = profile.id;
              await user.save();
            }
            return done(null, user);
          }

          // 2. Nếu user chưa tồn tại, tạo user mới
          // Vì model yêu cầu password, ta tạo một password ngẫu nhiên
          const randomPassword = crypto.randomBytes(16).toString('hex');

          user = await User.create({
            fullName: profile.displayName,
            email: email,
            password: randomPassword,
            googleId: profile.id,
            role: 'customer', // Mặc định là khách hàng
            // Nếu Google có ảnh avatar, bạn có thể lưu vào user profile nếu muốn
          });

          return done(null, user);
        } catch (error) {
          return done(error, null);
        }
      }
    )
  );
};

module.exports = configurePassport;