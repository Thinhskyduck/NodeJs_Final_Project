// src/api/models/discountModel.js
const mongoose = require('mongoose');

const discountSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    trim: true,
    minlength: [5, 'Mã giảm giá phải có đúng 5 ký tự'], 
    maxlength: [5, 'Mã giảm giá phải có đúng 5 ký tự'], 
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
  maxUses: { 
      type: Number, 
      required: true,
      max: [10, 'Giới hạn sử dụng tối đa là 10 lần']
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