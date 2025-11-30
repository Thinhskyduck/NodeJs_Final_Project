// src/api/controllers/orderController.js
const mongoose = require('mongoose');
const crypto = require('crypto');
const Order = require('../models/orderModel');
const Cart = require('../models/cartModel');
const Product = require('../models/productModel');
const Discount = require('../models/discountModel');
const User = require('../models/userModel');

// Import RabbitMQ Producer thay vì gọi Email Service trực tiếp
const { sendToQueue } = require('../../config/rabbitmq'); 

// @desc    Tạo đơn hàng mới (User đã đăng nhập - Lấy từ Cart DB)
// @route   POST /api/orders
// @access  Private
const createOrder = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { shippingAddress, paymentMethod, discountCode, useLoyaltyPoints } = req.body;
    const user = await User.findById(req.user._id).session(session);

    // 1. Lấy giỏ hàng từ DB
    const cart = await Cart.findOne({ user: user._id }).session(session);
    if (!cart || cart.items.length === 0) {
      throw new Error('Giỏ hàng của bạn đang trống');
    }

    // 2. Validate và lấy giá chuẩn từ Product DB
    let finalOrderItems = [];
    let itemsPrice = 0;

    for (const item of cart.items) {
      const product = await Product.findById(item.product).session(session);
      if (!product) throw new Error(`Sản phẩm không tồn tại`);

      const variant = product.variants.id(item.variant);
      if (!variant) throw new Error(`Biến thể không tồn tại`);

      if (variant.stockQuantity < item.quantity) {
        throw new Error(`Sản phẩm ${product.name} không đủ hàng`);
      }

      // Trừ kho
      variant.stockQuantity -= item.quantity;
      await product.save({ session });

      // Lấy giá chuẩn từ DB
      const realPrice = variant.price;
      itemsPrice += realPrice * item.quantity;

      finalOrderItems.push({
        product: product._id,
        variant: variant._id,
        name: product.name + ' - ' + variant.name,
        image: product.images[0] || '',
        price: realPrice,
        quantity: item.quantity
      });
    }

    // 3. Tính toán tổng tiền
    const shippingPrice = itemsPrice > 500000 ? 0 : 30000;
    const taxPrice = 0;
    let totalPrice = itemsPrice + shippingPrice + taxPrice;
    let discountAmount = 0;

    // 4. Xử lý mã giảm giá
    let appliedDiscount = null;
    if (discountCode) {
      const discount = await Discount.findOne({ code: discountCode.toUpperCase(), isActive: true }).session(session);
      if (discount && discount.timesUsed < discount.maxUses) {
        if(discount.discountType === 'fixed') {
            discountAmount = discount.value;
        } else {
            discountAmount = (itemsPrice * discount.value) / 100;
        }
        if(discountAmount > totalPrice) discountAmount = totalPrice;
        
        totalPrice -= discountAmount;
        appliedDiscount = discount;
      } else {
        throw new Error('Mã giảm giá không hợp lệ');
      }
    }

    // 5. Xử lý điểm loyalty
    if (useLoyaltyPoints && user.loyaltyPoints > 0) {
        const pointsValue = user.loyaltyPoints * 1000;
        if (totalPrice >= pointsValue) {
            totalPrice -= pointsValue;
            user.loyaltyPoints = 0;
        } else {
            const pointsToSpend = Math.ceil(totalPrice / 1000);
            user.loyaltyPoints -= pointsToSpend;
            totalPrice = 0;
        }
    }

    // 6. Cập nhật Discount Usage
    if (appliedDiscount) {
        appliedDiscount.timesUsed += 1;
        await appliedDiscount.save({ session });
    }

    // 7. Cộng điểm thưởng
    const pointsEarned = Math.floor(itemsPrice / 10000);
    user.loyaltyPoints += pointsEarned;
    await user.save({ session });
    
    // 8. Lưu Order
    const order = new Order({
        user: user._id,
        orderItems: finalOrderItems,
        shippingAddress,
        paymentMethod,
        itemsPrice,
        shippingPrice,
        taxPrice,
        totalPrice,
        discount: appliedDiscount ? { code: appliedDiscount.code, amount: discountAmount } : undefined,
    });
    
    const createdOrderArray = await Order.create([order], { session });
    const createdOrder = createdOrderArray[0];

    // 9. Xóa giỏ hàng
    await Cart.deleteOne({ _id: cart._id }).session(session);

    await session.commitTransaction();
    session.endSession();
    
    // --- SOCKET IO (Realtime Notification) ---
    const io = req.app.get('socketio');
    if (io) {
        io.emit('new_order_notification', {
            message: `Khách hàng ${user.fullName} vừa đặt đơn #${createdOrder._id}`,
            orderId: createdOrder._id,
            totalAmount: createdOrder.totalPrice
        });
    }

    // --- RABBITMQ (Async Email) ---
    // Đẩy task gửi mail vào hàng đợi để Worker xử lý
    sendToQueue('email_queue', {
        type: 'ORDER_CONFIRMATION',
        email: user.email,
        order: createdOrder
    });

    res.status(201).json(createdOrder);

  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    res.status(400).json({ message: error.message || 'Tạo đơn hàng thất bại' });
  }
};

// @desc    Tạo đơn hàng Guest (Logic quan trọng)
// @route   POST /api/orders/guest
// @access  Public
const createGuestOrder = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  let generatedPassword = null;

  try {
    const { email, fullName, cartItems, shippingAddress, paymentMethod, discountCode } = req.body;

    if (!email || !fullName || !cartItems || cartItems.length === 0) {
        throw new Error('Thiếu thông tin hoặc giỏ hàng trống');
    }

    // 1. User Logic
    let user = await User.findOne({ email }).session(session);
    let isNewUser = false;
    
    if (!user) {
        generatedPassword = crypto.randomBytes(4).toString('hex'); 
        user = new User({
            fullName,
            email,
            password: generatedPassword, 
            addresses: [shippingAddress],
            role: 'customer'
        });
        await user.save({ session });
        isNewUser = true;
    }
    
    // 2. Validate và Lấy giá từ Database
    let finalOrderItems = [];
    let itemsPrice = 0;

    for (const item of cartItems) {
        const product = await Product.findById(item.product).session(session);
        if (!product) throw new Error(`Sản phẩm ID ${item.product} không tồn tại`);

        const variant = product.variants.id(item.variant);
        if (!variant) throw new Error(`Biến thể ID ${item.variant} không tồn tại`);

        if (variant.stockQuantity < item.quantity) {
             throw new Error(`Sản phẩm ${product.name} (${variant.name}) không đủ hàng`);
        }
        
        variant.stockQuantity -= item.quantity;
        await product.save({ session });

        const realPrice = variant.price;
        itemsPrice += realPrice * item.quantity;

        finalOrderItems.push({
            product: product._id,
            variant: variant._id,
            name: product.name + ' - ' + variant.name,
            image: product.images[0] || '',
            price: realPrice,
            quantity: item.quantity
        });
    }

    // 3. Tính toán tổng
    const shippingPrice = itemsPrice > 500000 ? 0 : 30000;
    const taxPrice = 0;
    let totalPrice = itemsPrice + shippingPrice + taxPrice;
    let discountAmount = 0;

    // --- LOGIC MÃ GIẢM GIÁ (MỚI THÊM) ---
    let appliedDiscount = null;
    if (discountCode) {
      const discount = await Discount.findOne({ code: discountCode.toUpperCase(), isActive: true }).session(session);
      
      // Kiểm tra hợp lệ
      if (discount && discount.timesUsed < discount.maxUses) {
        if(discount.discountType === 'fixed') {
            discountAmount = discount.value;
        } else {
            discountAmount = (itemsPrice * discount.value) / 100;
        }
        if(discountAmount > totalPrice) discountAmount = totalPrice;
        
        totalPrice -= discountAmount;
        appliedDiscount = discount;
      } else {
        throw new Error('Mã giảm giá không hợp lệ hoặc đã hết lượt');
      }
    }
    // ------------------------------------

    // --- CẬP NHẬT SỐ LẦN DÙNG DISCOUNT ---
    if (appliedDiscount) {
        appliedDiscount.timesUsed += 1;
        await appliedDiscount.save({ session });
    }
    
    // 4. Lưu Order
    const order = new Order({
        user: user._id,
        guestInfo: { email, fullName },
        orderItems: finalOrderItems,
        shippingAddress,
        paymentMethod,
        itemsPrice,
        shippingPrice,
        taxPrice,
        totalPrice,
        discount: appliedDiscount ? { code: appliedDiscount.code, amount: discountAmount } : undefined,
    });

    const createdOrderArray = await Order.create([order], { session });
    const createdOrder = createdOrderArray[0];

    await session.commitTransaction();
    session.endSession();

    // --- SOCKET IO ---
    const io = req.app.get('socketio');
    if (io) {
        io.emit('new_order_notification', {
            message: `Đơn GUEST mới #${createdOrder._id} từ ${fullName}`,
            orderId: createdOrder._id,
            totalAmount: createdOrder.totalPrice
        });
    }

    // --- RABBITMQ (Gửi email bất đồng bộ) ---
    
    // 1. Task gửi mail xác nhận đơn hàng
    sendToQueue('email_queue', {
        type: 'ORDER_CONFIRMATION',
        email: email,
        order: createdOrder
    });

    // 2. Task gửi mail mật khẩu (nếu là user mới)
    if (isNewUser && generatedPassword) {
        sendToQueue('email_queue', {
            type: 'NEW_USER_PASSWORD',
            email: email,
            password: generatedPassword
        });
    }

    res.status(201).json({
        message: isNewUser 
            ? 'Đơn hàng thành công. Tài khoản đã được tạo.'
            : 'Đơn hàng thành công.',
        order: createdOrder
    });

  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    res.status(400).json({ message: error.message || 'Tạo đơn hàng thất bại' });
  }
};

// ... (Các hàm GET giữ nguyên)
const getMyOrders = async (req, res) => {
  try {
    const orders = await Order.find({ user: req.user._id }).sort({ createdAt: -1 });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

const getOrderById = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id).populate('user', 'fullName email');
    if (order) {
      if (order.user._id.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Không có quyền truy cập' });
      }
      res.json(order);
    } else {
      res.status(404).json({ message: 'Không tìm thấy đơn hàng' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

const getOrders = async (req, res) => {
  try {
    const pageSize = 20;
    const page = Number(req.query.page) || 1;
    let filter = {};
    if (req.query.startDate && req.query.endDate) {
        filter.createdAt = {
            $gte: new Date(req.query.startDate),
            $lte: new Date(req.query.endDate),
        }
    }
    const count = await Order.countDocuments(filter);
    const orders = await Order.find(filter)
      .populate('user', 'id fullName')
      .sort({ createdAt: -1 })
      .limit(pageSize)
      .skip(pageSize * (page - 1));
    res.json({ orders, page, pages: Math.ceil(count / pageSize) });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

const updateOrderStatus = async (req, res) => {
    try {
        const order = await Order.findById(req.params.id);
        const { status } = req.body;
        if (order) {
            order.status = status;
            order.statusHistory.push({ status: status, updatedAt: new Date() });
            if (status === 'delivered') order.deliveredAt = Date.now();
            const updatedOrder = await order.save();
            res.json(updatedOrder);
        } else {
            res.status(404).json({ message: 'Không tìm thấy đơn hàng' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

module.exports = {
  createOrder,
  createGuestOrder,
  getMyOrders,
  getOrderById,
  getOrders,
  updateOrderStatus,
};