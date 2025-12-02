// src/api/controllers/orderController.js
const mongoose = require('mongoose');
const crypto = require('crypto');
const Order = require('../models/orderModel');
const Cart = require('../models/cartModel');
const Product = require('../models/productModel');
const Discount = require('../models/discountModel');
const User = require('../models/userModel');

// Import RabbitMQ Producer
const { sendToQueue } = require('../../config/rabbitmq'); 

// ==============================================================================
// 1. TẠO ĐƠN HÀNG (USER ĐÃ LOGIN - LẤY TỪ CART DB)
// ==============================================================================
// @route   POST /api/orders
// @access  Private
const createOrder = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // Merge: Sử dụng pointsToUse (số lượng cụ thể) thay vì boolean useLoyaltyPoints
    const { shippingAddress, paymentMethod, discountCode, pointsToUse } = req.body;
    
    const user = await User.findById(req.user._id).session(session);

    // 1. Lấy và kiểm tra giỏ hàng
    const cart = await Cart.findOne({ user: user._id }).session(session);
    if (!cart || cart.items.length === 0) {
      throw new Error('Giỏ hàng của bạn đang trống');
    }

    // 2. Tính toán giá sản phẩm & trừ kho
    let finalOrderItems = [];
    let itemsPrice = 0;

    for (const item of cart.items) {
      const product = await Product.findById(item.product).session(session);
      if (!product) throw new Error(`Sản phẩm không tồn tại`);

      const variant = product.variants.id(item.variant);
      if (!variant) throw new Error(`Biến thể không tồn tại`);

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

    // 3. Tính tổng tiền ban đầu
    const shippingPrice = itemsPrice > 500000 ? 0 : 30000;
    const taxPrice = 0;
    
    // totalPrice bắt đầu bằng tổng phụ phí
    let totalPrice = itemsPrice + shippingPrice + taxPrice;
    
    // Khởi tạo biến theo dõi giảm giá
    let discountAmount = 0; 
    let loyaltyDiscount = 0; 
    let actualPointsUsed = 0; 

    // 4. Xử lý Coupon (Ưu tiên trừ Coupon trước)
    let appliedDiscount = null;
    if (discountCode) {
      const discount = await Discount.findOne({ code: discountCode.toUpperCase(), isActive: true }).session(session);
      if (discount && discount.timesUsed < discount.maxUses) {
        if(discount.discountType === 'fixed') {
            discountAmount = discount.value;
        } else {
            discountAmount = (itemsPrice * discount.value) / 100;
        }

        // Không giảm quá tổng tiền
        if(discountAmount > totalPrice) discountAmount = totalPrice;
        
        totalPrice -= discountAmount;
        appliedDiscount = discount;
        
        // Cập nhật số lần dùng coupon
        discount.timesUsed += 1;
        await discount.save({ session });
      } else {
        throw new Error('Mã giảm giá không hợp lệ hoặc đã hết lượt');
      }
    }

    // 5. Xử lý điểm Loyalty (Logic nâng cao từ Incoming)
    const pointsToUseNum = Number(pointsToUse) || 0;

    if (pointsToUseNum > 0) {
        // a. Kiểm tra số dư điểm
        if (user.loyaltyPoints < pointsToUseNum) {
            throw new Error(`Bạn không đủ điểm (Có: ${user.loyaltyPoints}, Muốn dùng: ${pointsToUseNum})`);
        }

        // b. Tính giá trị quy đổi (1 điểm = 1000đ)
        let potentialDiscount = pointsToUseNum * 1000;

        // c. Logic thông minh: Kiểm tra xem có bị thừa điểm không
        if (potentialDiscount > totalPrice) {
            // Trường hợp điểm nhiều hơn tiền phải trả -> Chỉ trừ vừa đủ
            loyaltyDiscount = totalPrice;
            // Tính ngược lại số điểm thực sự cần (làm tròn lên)
            actualPointsUsed = Math.ceil(totalPrice / 1000); 
            totalPrice = 0; // Đơn hàng về 0đ
        } else {
            // Trường hợp bình thường
            loyaltyDiscount = potentialDiscount;
            actualPointsUsed = pointsToUseNum;
            totalPrice -= loyaltyDiscount;
        }

        // d. Trừ điểm của user (Dùng số thực tế actualPointsUsed)
        user.loyaltyPoints -= actualPointsUsed;
        await user.save({ session });
    }

    // --- QUYẾT ĐỊNH MERGE: KHÔNG cộng điểm ở đây (theo Current) ---
    // Điểm sẽ được cộng ở updateOrderStatus khi đơn hàng thành công để an toàn hơn.
    
    // 6. Lưu Order
    const order = new Order({
        user: user._id,
        orderItems: finalOrderItems,
        shippingAddress,
        paymentMethod,
        itemsPrice,
        shippingPrice,
        taxPrice,
        
        totalPrice, // Giá cuối cùng khách phải trả
        
        // Lưu thông tin Coupon
        discount: appliedDiscount ? { code: appliedDiscount.code, amount: discountAmount } : undefined,
        
        // Lưu thông tin Điểm (Merge từ Incoming: thêm field này để tracking tốt hơn)
        loyaltyPointsUsed: actualPointsUsed,
        loyaltyDiscountAmount: loyaltyDiscount 
    });
    
    const createdOrderArray = await Order.create([order], { session });
    const createdOrder = createdOrderArray[0];

    // 7. Xóa giỏ hàng & Commit
    await Cart.deleteOne({ _id: cart._id }).session(session);

    await session.commitTransaction();
    session.endSession();
    
    // --- POST-TRANSACTION ---

    // Socket IO
    const io = req.app.get('socketio');
    if (io) {
        io.emit('new_order_notification', {
            message: `Khách hàng ${user.fullName} vừa đặt đơn #${createdOrder._id}`,
            orderId: createdOrder._id,
            totalAmount: createdOrder.totalPrice
        });
    }

    // RabbitMQ
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

// ==============================================================================
// 2. TẠO ĐƠN HÀNG GUEST (KHÔNG CẦN LOGIN)
// ==============================================================================
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
    
    // 2. Validate Items & Lấy giá từ Database
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

    // 4. Xử lý Mã giảm giá
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
        throw new Error('Mã giảm giá không hợp lệ hoặc đã hết lượt');
      }
    }

    // 5. Cập nhật số lần dùng Discount
    if (appliedDiscount) {
        appliedDiscount.timesUsed += 1;
        await appliedDiscount.save({ session });
    }
    
    // 6. Lưu Order
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

    // --- POST-TRANSACTION ---

    // Socket IO
    const io = req.app.get('socketio');
    if (io) {
        io.emit('new_order_notification', {
            message: `Đơn GUEST mới #${createdOrder._id} từ ${fullName}`,
            orderId: createdOrder._id,
            totalAmount: createdOrder.totalPrice
        });
    }

    // RabbitMQ: Gửi mail xác nhận
    sendToQueue('email_queue', {
        type: 'ORDER_CONFIRMATION',
        email: email,
        order: createdOrder
    });

    // RabbitMQ: Gửi password nếu user mới
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

// ==============================================================================
// 3. CÁC API KHÁC (GET, UPDATE)
// ==============================================================================

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

// @desc    Cập nhật trạng thái đơn hàng (Admin)
// Merge Decision: Giữ logic của Current để cộng điểm tại đây
const updateOrderStatus = async (req, res) => {
    try {
        const order = await Order.findById(req.params.id);
        const { status } = req.body;
        if (order) {
            const oldStatus = order.status; 

            order.status = status;
            order.statusHistory.push({ status: status, updatedAt: new Date() });
            
            if (status === 'delivered') order.deliveredAt = Date.now();
            
            const updatedOrder = await order.save();

            // --- LOGIC CỘNG ĐIỂM (Giữ từ Current) ---
            // Chỉ cộng khi chuyển từ 'pending' sang 'confirmed' và có User
            if (oldStatus === 'pending' && status === 'confirmed' && order.user) {
                const user = await User.findById(order.user);
                if (user) {
                    // 10.000đ = 1 điểm
                    const pointsEarned = Math.floor(order.totalPrice / 10000);
                    
                    user.loyaltyPoints = (user.loyaltyPoints || 0) + pointsEarned;
                    await user.save();
                    
                    // console.log(`[Admin] Đã cộng ${pointsEarned} điểm cho user ${user.email}`);
                }
            }

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