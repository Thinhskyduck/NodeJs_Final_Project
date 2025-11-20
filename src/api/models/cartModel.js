// src/api/models/cartModel.js

const mongoose = require('mongoose');

const cartSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.ObjectId,
      ref: 'User',
      required: true,
      unique: true, // Mỗi user chỉ có một giỏ hàng
    },
    items: [
      {
        product: {
          type: mongoose.Schema.ObjectId,
          ref: 'Product',
          required: true,
        },
        // Lưu ID của variant cụ thể mà người dùng chọn
        variant: {
          type: mongoose.Schema.Types.ObjectId, 
          required: true,
        },
        quantity: {
          type: Number,
          required: true,
          min: 1,
          default: 1,
        },
        // Lưu lại thông tin sản phẩm tại thời điểm thêm vào giỏ để hiển thị nhanh
        name: String,
        price: Number,
        image: String,
      },
    ],
  },
  { timestamps: true }
);

const Cart = mongoose.model('Cart', cartSchema);

module.exports = Cart;