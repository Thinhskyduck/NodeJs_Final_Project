// src/api/models/discountModel.js
const mongoose = require('mongoose');

const discountSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    trim: true,
  },
  value: {
    type: Number, // Giá trị giảm giá, có thể là % hoặc số tiền cụ thể
    required: true,
  },
  discountType: {
    type: String,
    enum: ['percentage', 'fixed'],
    default: 'fixed'
  },
  maxUses: { // Số lần sử dụng tối đa
    type: Number,
    required: true,
  },
  timesUsed: { // Số lần đã sử dụng
    type: Number,
    default: 0,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
}, { timestamps: true });

const Discount = mongoose.model('Discount', discountSchema);
module.exports = Discount;