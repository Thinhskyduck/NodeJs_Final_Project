// src/api/controllers/dashboardController.js
const Order = require('../models/orderModel');
const User = require('../models/userModel');
const Product = require('../models/productModel');

// @desc    Lấy dữ liệu cho Simple Dashboard
// @route   GET /api/dashboard/simple
// @access  Private/Admin
const getSimpleDashboardData = async (req, res) => {
    try {
        const totalUsers = await User.countDocuments();
        const totalOrders = await Order.countDocuments();
        
        const totalRevenueResult = await Order.aggregate([
            { $match: { status: 'delivered' } }, // Chỉ tính doanh thu từ đơn đã giao
            { $group: { _id: null, totalRevenue: { $sum: '$totalPrice' } } }
        ]);
        const totalRevenue = totalRevenueResult.length > 0 ? totalRevenueResult[0].totalRevenue : 0;

        // Lấy sản phẩm bán chạy nhất
        const bestSellingProducts = await Order.aggregate([
            { $unwind: '$orderItems' },
            { $group: { _id: '$orderItems.product', totalQuantity: { $sum: '$orderItems.quantity' } } },
            { $sort: { totalQuantity: -1 } },
            { $limit: 5 },
            { $lookup: { from: 'products', localField: '_id', foreignField: '_id', as: 'productDetails' } }
        ]);

        res.json({
            totalUsers,
            totalOrders,
            totalRevenue,
            bestSellingProducts
        });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

// Bạn có thể tạo thêm hàm getAdvancedDashboardData với logic phức tạp hơn về thời gian
module.exports = { getSimpleDashboardData };