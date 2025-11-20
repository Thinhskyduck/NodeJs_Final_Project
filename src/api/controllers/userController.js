// src/api/controllers/userController.js

const User = require('../models/userModel');
const generateToken = require('../utils/generateToken');
const crypto = require('crypto');
const { sendResetPasswordEmail } = require('../../utils/emailService');

// @desc    Đăng ký người dùng mới
// @route   POST /api/users/register
// @access  Public
const registerUser = async (req, res) => {
  // 1. Lấy thông tin từ request body
  const { fullName, email, password } = req.body;

  // 2. Validate dữ liệu đầu vào cơ bản
  if (!fullName || !email || !password) {
    return res.status(400).json({ message: 'Vui lòng điền đầy đủ thông tin' });
  }

  try {
    // 3. Kiểm tra xem email đã tồn tại trong DB chưa
    const userExists = await User.findOne({ email });

    if (userExists) {
      return res.status(400).json({ message: 'Email đã tồn tại' });
    }

    // 4. Tạo người dùng mới
    // (Lưu ý: Mật khẩu sẽ được tự động mã hóa nhờ middleware trong userModel)
    const user = await User.create({
      fullName,
      email,
      password,
    });

    // 5. Nếu tạo thành công, trả về thông tin người dùng (không bao gồm mật khẩu)
    if (user) {
      res.status(201).json({
        _id: user._id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        // Chúng ta sẽ thêm token ở đây trong các bước sau
      });
    } else {
      res.status(400).json({ message: 'Dữ liệu người dùng không hợp lệ' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Đăng nhập & lấy token
// @route   POST /api/users/login
// @access  Public
const loginUser = async (req, res) => {
  const { email, password } = req.body;

  try {
    // 1. Tìm người dùng bằng email
    const user = await User.findOne({ email });

    // 2. Kiểm tra người dùng có tồn tại VÀ mật khẩu có khớp không
    if (user && (await user.matchPassword(password))) {
      // 3. Nếu khớp, trả về thông tin và token
      res.json({
        _id: user._id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        token: generateToken(user._id), // Tạo và gửi token về cho client
      });
    } else {
      res.status(401).json({ message: 'Email hoặc mật khẩu không đúng' }); // 401 Unauthorized
    }
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Lấy thông tin cá nhân của người dùng
// @route   GET /api/users/profile
// @access  Private (Cần token)
const getUserProfile = async (req, res) => {
  // Nhờ middleware `protect`, chúng ta đã có thông tin user trong `req.user`
  const user = await User.findById(req.user._id);

  if (user) {
    res.json({
      _id: user._id,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      addresses: user.addresses,
      loyaltyPoints: user.loyaltyPoints,
    });
  } else {
    res.status(404).json({ message: 'User not found' });
  }
};

// @desc    Cập nhật thông tin cá nhân (họ tên)
// @route   PUT /api/users/profile
// @access  Private
const updateUserProfile = async (req, res) => {
    const user = await User.findById(req.user._id);
    if (user) {
        user.fullName = req.body.fullName || user.fullName;
        const updatedUser = await user.save();
        res.json({
            _id: updatedUser._id,
            fullName: updatedUser.fullName,
            email: updatedUser.email,
        });
    } else {
        res.status(404).json({ message: 'User not found' });
    }
};

// @desc    Thêm địa chỉ mới
// @route   POST /api/users/addresses
// @access  Private
const addAddress = async (req, res) => {
    const { addressLine, city, postalCode, country } = req.body;
    const user = await User.findById(req.user._id);
    if (user) {
        const newAddress = { addressLine, city, postalCode, country };
        // Nếu đây là địa chỉ đầu tiên, đặt nó làm mặc định
        if (user.addresses.length === 0) {
            newAddress.isDefault = true;
        }
        user.addresses.push(newAddress);
        await user.save();
        res.status(201).json(user.addresses);
    } else {
        res.status(404).json({ message: 'User not found' });
    }
};

// @desc    Đổi mật khẩu (User đã đăng nhập)
// @route   PUT /api/users/change-password
// @access  Private
const changePassword = async (req, res) => {
  const { oldPassword, newPassword } = req.body;

  try {
    const user = await User.findById(req.user._id);

    // Kiểm tra mật khẩu cũ
    if (!(await user.matchPassword(oldPassword))) {
      return res.status(401).json({ message: 'Mật khẩu cũ không đúng' });
    }

    // Cập nhật mật khẩu mới (middleware pre-save sẽ tự hash)
    user.password = newPassword;
    await user.save();

    res.json({ message: 'Đổi mật khẩu thành công' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Quên mật khẩu (Gửi email reset)
// @route   POST /api/users/forgot-password
// @access  Public
const forgotPassword = async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy tài khoản với email này' });
    }

    // Lấy token reset
    const resetToken = user.getResetPasswordToken();
    await user.save({ validateBeforeSave: false }); // Lưu token vào DB

    // Tạo URL reset (Frontend URL)
    // Ví dụ: http://localhost:3000/reset-password/TOKEN
    // Frontend_URL nên lấy từ .env
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password/${resetToken}`;

    try {
      await sendResetPasswordEmail(user.email, resetUrl);
      res.json({ message: 'Email đặt lại mật khẩu đã được gửi' });
    } catch (error) {
      // Nếu gửi mail lỗi, xóa token trong DB đi
      user.resetPasswordToken = undefined;
      user.resetPasswordExpire = undefined;
      await user.save({ validateBeforeSave: false });
      return res.status(500).json({ message: 'Không thể gửi email', error: error.message });
    }
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Đặt lại mật khẩu mới (Từ link email)
// @route   PUT /api/users/reset-password/:resetToken
// @access  Public
const resetPassword = async (req, res) => {
  // Mã hóa token từ URL để so sánh với DB
  const resetPasswordToken = crypto
    .createHash('sha256')
    .update(req.params.resetToken)
    .digest('hex');

  try {
    // Tìm user có token trùng khớp và chưa hết hạn ($gt = greater than = lớn hơn hiện tại)
    const user = await User.findOne({
      resetPasswordToken,
      resetPasswordExpire: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({ message: 'Token không hợp lệ hoặc đã hết hạn' });
    }

    // Đặt mật khẩu mới
    user.password = req.body.password;
    // Xóa token reset đi
    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;

    await user.save();

    res.json({ message: 'Đặt lại mật khẩu thành công. Bạn có thể đăng nhập ngay bây giờ.' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

module.exports = {
  registerUser,
  loginUser,
  getUserProfile,
  updateUserProfile,
  changePassword,
  addAddress,
  forgotPassword,
  resetPassword,
};