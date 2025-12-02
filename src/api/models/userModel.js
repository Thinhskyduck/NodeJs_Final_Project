// src/api/models/userModel.js

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: [true, 'Họ tên là bắt buộc'],
    },
    email: {
      type: String,
      required: [true, 'Email là bắt buộc'],
      unique: true,
      lowercase: true,
      match: [/\S+@\S+\.\S+/, 'Email không hợp lệ'],
    },
    password: {
      type: String,
      required: [true, 'Mật khẩu là bắt buộc'],
      minlength: 6, // Mật khẩu cần ít nhất 6 ký tự
    },
    googleId: {
        type: String,
        unique: true,
        sparse: true // Cho phép nhiều user có googleId là null
    },
    addresses: [
      {
        addressLine: String,
        city: String,
        postalCode: String,
        country: String,
        isDefault: { type: Boolean, default: false },
      },
    ],
    role: {
      type: String,
      enum: ['customer', 'admin'],
      default: 'customer',
    },
    loyaltyPoints: {
      type: Number,
      default: 0,
    },
    resetPasswordToken: String,
    resetPasswordExpire: Date,
  },
  {
    // Tự động thêm 2 trường createdAt và updatedAt
    timestamps: true,
  }
);

// Middleware: Mã hóa mật khẩu TRƯỚC KHI lưu vào DB
userSchema.pre('save', async function (next) {
  // Chỉ chạy hàm này nếu mật khẩu được thay đổi (hoặc mới)
  if (!this.isModified('password')) {
    return next();
  }

  // Băm mật khẩu với salt round là 12
  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

userSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

userSchema.methods.getResetPasswordToken = function () {
  // 1. Tạo token ngẫu nhiên
  const resetToken = crypto.randomBytes(20).toString('hex');

  // 2. Mã hóa token và lưu vào database (để bảo mật, không lưu token gốc)
  this.resetPasswordToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  // 3. Token hết hạn sau 10 phút
  this.resetPasswordExpire = Date.now() + 10 * 60 * 1000;

  return resetToken; // Trả về token gốc để gửi qua email
};

const User = mongoose.model('User', userSchema);

module.exports = User;