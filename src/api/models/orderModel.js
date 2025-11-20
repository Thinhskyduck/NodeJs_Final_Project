// src/api/models/orderModel.js
const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.ObjectId,
      ref: 'User',
      required: true,
    },
    orderItems: [
      {
        name: { type: String, required: true },
        quantity: { type: Number, required: true },
        image: { type: String, required: true },
        price: { type: Number, required: true },
        product: {
          type: mongoose.Schema.ObjectId,
          ref: 'Product',
          required: true,
        },
        variant: {
            type: mongoose.Schema.Types.ObjectId,
            required: true,
        },
      },
    ],
    shippingAddress: {
      addressLine: { type: String, required: true },
      city: { type: String, required: true },
      postalCode: { type: String, required: true },
      country: { type: String, required: true },
    },
    paymentMethod: { // Phương thức thanh toán (vd: COD, Stripe)
      type: String,
      required: true,
      default: 'COD'
    },
    // Lưu lại giá trị các loại phí tại thời điểm đặt hàng
    itemsPrice: { // Tổng tiền hàng
      type: Number,
      required: true,
      default: 0.0,
    },
    shippingPrice: { // Phí vận chuyển
      type: Number,
      required: true,
      default: 0.0,
    },
    taxPrice: { // Thuế
      type: Number,
      required: true,
      default: 0.0,
    },
    totalPrice: { // Tổng cộng cuối cùng
      type: Number,
      required: true,
      default: 0.0,
    },
    discount: { // Thông tin mã giảm giá đã áp dụng
      code: String,
      amount: Number,
    },
    status: {
      type: String,
      required: true,
      enum: ['pending', 'confirmed', 'shipping', 'delivered', 'cancelled'],
      default: 'pending',
    },
    statusHistory: [
        {
            status: String,
            updatedAt: Date,
        }
    ],
    deliveredAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Middleware để thêm status history khi tạo mới
orderSchema.pre('save', function(next) {
    if (this.isNew) {
        this.statusHistory.push({ status: this.status, updatedAt: new Date() });
    }
    next();
});


const Order = mongoose.model('Order', orderSchema);
module.exports = Order;