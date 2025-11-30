// src/api/models/productModel.js

const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.ObjectId,
      ref: 'User',
      required: false, // <-- Cho phép null nếu là Guest
    },
    guestName: { // <-- Thêm trường này cho Guest
        type: String,
        required: false 
    },
    rating: {
      type: Number,
      required: true, 
      default: 0, // Guest comment thì rating = 0 (coi như không đánh giá)
    },
    comment: {
      type: String,
      required: true,
    },
  },
  { timestamps: true }
);

const productSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Tên sản phẩm là bắt buộc'],
      trim: true,
    },
    description: {
      type: String,
      required: [true, 'Mô tả sản phẩm là bắt buộc'],
    },
    brand: {
      type: String,
      required: true,
    },
    // Tham chiếu đến Category Model
    category: {
      type: mongoose.Schema.ObjectId,
      ref: 'Category',
      required: true,
    },
    images: [
      {
        type: String,
        required: true,
      },
    ],
    // Yêu cầu quan trọng: sản phẩm có nhiều biến thể
    variants: [
      {
        name: { type: String, required: true }, // Ví dụ: '16GB RAM, 512GB SSD'
        price: { type: Number, required: true },
        stockQuantity: { type: Number, required: true, default: 0 },
      },
    ],
    reviews: [reviewSchema],
    // Tính toán rating trung bình và số lượng review để truy vấn nhanh hơn
    averageRating: {
      type: Number,
      default: 0,
    },
    numReviews: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

const Product = mongoose.model('Product', productSchema);

module.exports = Product;