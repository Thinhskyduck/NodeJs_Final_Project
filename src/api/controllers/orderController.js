// src/api/controllers/orderController.js
const mongoose = require('mongoose');
const crypto = require('crypto');
const Order = require('../models/orderModel');
const Cart = require('../models/cartModel');
const Product = require('../models/productModel');
const Discount = require('../models/discountModel');
const User = require('../models/userModel');
const { sendOrderConfirmationEmail, sendNewUserPasswordEmail } = require('../../utils/emailService');

// @desc    Tạo đơn hàng mới (User đã đăng nhập)
// @route   POST /api/orders
// @access  Private
const createOrder = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { shippingAddress, paymentMethod, discountCode, useLoyaltyPoints } = req.body;
    const user = await User.findById(req.user._id).session(session);

    const cart = await Cart.findOne({ user: user._id }).session(session);
    if (!cart || cart.items.length === 0) {
      throw new Error('Giỏ hàng của bạn đang trống');
    }

    const itemsPrice = cart.items.reduce((acc, item) => acc + item.price * item.quantity, 0);
    const shippingPrice = itemsPrice > 500000 ? 0 : 30000;
    const taxPrice = 0;
    let totalPrice = itemsPrice + shippingPrice + taxPrice;
    let discountAmount = 0;
    let pointsUsedAmount = 0;

    let appliedDiscount = null;
    if (discountCode) {
      const discount = await Discount.findOne({ code: discountCode, isActive: true }).session(session);
      if (discount && discount.timesUsed < discount.maxUses) {
        discountAmount = discount.value;
        totalPrice -= discountAmount;
        appliedDiscount = discount;
      } else {
        throw new Error('Mã giảm giá không hợp lệ');
      }
    }

    if (useLoyaltyPoints && user.loyaltyPoints > 0) {
        const pointsValue = user.loyaltyPoints * 1000;
        if (totalPrice >= pointsValue) {
            pointsUsedAmount = pointsValue;
            totalPrice -= pointsValue;
            user.loyaltyPoints = 0;
        } else {
            pointsUsedAmount = totalPrice;
            user.loyaltyPoints -= Math.floor(totalPrice / 1000);
            totalPrice = 0;
        }
    }

    for (const item of cart.items) {
      const product = await Product.findById(item.product).session(session);
      const variant = product.variants.id(item.variant);
      if (variant.stockQuantity < item.quantity) {
        throw new Error(`Sản phẩm ${item.name} không đủ hàng`);
      }
      variant.stockQuantity -= item.quantity;
      await product.save({ session });
    }

    if (appliedDiscount) {
        appliedDiscount.timesUsed += 1;
        await appliedDiscount.save({ session });
    }

    const pointsEarned = Math.floor(itemsPrice / 10000);
    user.loyaltyPoints += pointsEarned;
    await user.save({ session });
    
    const order = new Order({
        user: user._id,
        orderItems: cart.items.map(item => ({...item.toObject()})),
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

    await Cart.deleteOne({ _id: cart._id }).session(session);

    await session.commitTransaction();
    session.endSession();
    
    // --- SOCKET & EMAIL ---
    const io = req.app.get('socketio');
    if (io) {
        io.emit('new_order_notification', {
            message: `Khách hàng ${user.fullName} vừa đặt đơn hàng mới #${createdOrder._id}`,
            orderId: createdOrder._id,
            totalAmount: createdOrder.totalPrice
        });
    }
    sendOrderConfirmationEmail(user.email, createdOrder).catch(err => console.log(err));

    res.status(201).json(createdOrder);
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    res.status(400).json({ message: error.message || 'Tạo đơn hàng thất bại' });
  }
};

// @desc    Tạo đơn hàng cho khách (Guest)
// @route   POST /api/orders/guest
// @access  Public
const createGuestOrder = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  let generatedPassword = null; // Biến lưu password tạm để gửi mail

  try {
    const { email, fullName, cartItems, shippingAddress, paymentMethod } = req.body;

    if (!email || !fullName || !cartItems || cartItems.length === 0) {
        throw new Error('Thiếu thông tin người dùng hoặc giỏ hàng trống');
    }

    // 1. Tìm hoặc Tạo người dùng
    let user = await User.findOne({ email }).session(session);
    let isNewUser = false;
    
    if (!user) {
        // Tạo password ngẫu nhiên 8 ký tự
        generatedPassword = crypto.randomBytes(4).toString('hex'); 
        
        user = new User({
            fullName,
            email,
            password: generatedPassword, // Model sẽ tự hash password này khi save
            addresses: [shippingAddress],
            role: 'customer'
        });
        
        await user.save({ session });
        isNewUser = true;
    }
    
    // 2. Tính toán giá trị đơn hàng
    const itemsPrice = cartItems.reduce((acc, item) => acc + item.price * item.quantity, 0);
    const shippingPrice = itemsPrice > 500000 ? 0 : 30000;
    const totalPrice = itemsPrice + shippingPrice;
    
    // 3. Tạo đơn hàng
    const order = new Order({
        user: user._id,
        guestInfo: { email, fullName }, // Lưu thêm info guest để tiện tra cứu
        orderItems: cartItems, // Format cartItems từ frontend gửi lên phải khớp với schema
        shippingAddress,
        paymentMethod,
        itemsPrice,
        shippingPrice,
        totalPrice,
    });

    // 4. Cập nhật kho hàng
    for (const item of order.orderItems) {
        // Lưu ý: frontend gửi item.product là ID string, cần cẩn thận khi query
        const product = await Product.findById(item.product).session(session);
        if (!product) throw new Error(`Sản phẩm không tồn tại`);

        const variant = product.variants.id(item.variant);
        if (!variant) throw new Error(`Biến thể không tồn tại`);

        if (variant.stockQuantity < item.quantity) {
             throw new Error(`Sản phẩm ${product.name} không đủ số lượng`);
        }
        variant.stockQuantity -= item.quantity;
        await product.save({ session });
    }

    const createdOrderArray = await Order.create([order], { session });
    const createdOrder = createdOrderArray[0];

    // --- COMMIT TRANSACTION ---
    await session.commitTransaction();
    session.endSession();

    // --- XỬ LÝ SAU KHI LƯU THÀNH CÔNG (SOCKET & EMAIL) ---
    
    // A. Gửi Socket cho Admin
    const io = req.app.get('socketio');
    if (io) {
        io.emit('new_order_notification', {
            message: `Đơn hàng GUEST mới #${createdOrder._id} từ ${fullName}`,
            orderId: createdOrder._id,
            totalAmount: createdOrder.totalPrice
        });
    }

    // B. Gửi Email xác nhận đơn hàng
    sendOrderConfirmationEmail(email, createdOrder).catch(err => console.log("Email order error:", err));

    // C. Gửi Email mật khẩu (CHỈ GỬI NẾU LÀ USER MỚI)
    if (isNewUser && generatedPassword) {
        sendNewUserPasswordEmail(email, generatedPassword).catch(err => console.log("Email password error:", err));
    }

    res.status(201).json({
        message: isNewUser 
            ? 'Đơn hàng thành công. Tài khoản đã được tạo, vui lòng kiểm tra email để lấy mật khẩu.'
            : 'Đơn hàng thành công.',
        order: createdOrder
    });

  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    res.status(400).json({ message: error.message || 'Tạo đơn hàng thất bại' });
  }
};

// @desc    Lấy danh sách đơn hàng của người dùng đang đăng nhập
// @route   GET /api/orders/myorders
// @access  Private
const getMyOrders = async (req, res) => {
  try {
    const orders = await Order.find({ user: req.user._id }).sort({ createdAt: -1 });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Lấy chi tiết đơn hàng bằng ID
// @route   GET /api/orders/:id
// @access  Private
const getOrderById = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id).populate(
      'user',
      'fullName email'
    );

    if (order) {
      if (order.user._id.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Không có quyền truy cập đơn hàng này' });
      }
      res.json(order);
    } else {
      res.status(404).json({ message: 'Không tìm thấy đơn hàng' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// @desc    Lấy tất cả đơn hàng (Admin)
// @route   GET /api/orders
// @access  Private/Admin
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

// @desc    Cập nhật trạng thái đơn hàng (Admin)
// @route   PUT /api/orders/:id/status
// @access  Private/Admin
const updateOrderStatus = async (req, res) => {
    try {
        const order = await Order.findById(req.params.id);
        const { status } = req.body;

        if (order) {
            order.status = status;
            order.statusHistory.push({ status: status, updatedAt: new Date() });

            if (status === 'delivered') {
                order.deliveredAt = Date.now();
            }

            const updatedOrder = await order.save();
            
            // Có thể thêm socket thông báo cho user biết đơn hàng đã update
            // io.emit(...)

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
  getMyOrders,
  getOrderById,
  getOrders,
  updateOrderStatus,
  createGuestOrder,
};