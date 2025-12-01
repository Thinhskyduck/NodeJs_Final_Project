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

// @desc    Lấy dữ liệu Dashboard nâng cao (Biểu đồ doanh thu)
// @route   GET /api/dashboard/advanced
// @access  Private/Admin
const getAdvancedDashboardData = async (req, res) => {
    try {
        const { type } = req.query; // type = 'month' (theo ngày trong tháng), 'year' (theo tháng trong năm)
        let groupBy = {};
        let sortBy = {};

        if (type === 'year') {
            // Thống kê theo 12 tháng trong năm
            groupBy = { 
                month: { $month: "$createdAt" }, 
                year: { $year: "$createdAt" } 
            };
            sortBy = { "_id.year": 1, "_id.month": 1 };
        } else {
            // Mặc định (hoặc type='month'): Thống kê theo ngày
            groupBy = { 
                year: { $year: "$createdAt" }, 
                month: { $month: "$createdAt" }, 
                day: { $dayOfMonth: "$createdAt" } 
            };
            sortBy = { "_id.year": 1, "_id.month": 1, "_id.day": 1 };
        }

        const stats = await Order.aggregate([
            // 1. Chỉ lấy đơn đã giao (hoặc confirmed tùy logic của bạn)
            { $match: { status: { $in: ['delivered', 'confirmed'] } } }, 
            
            // 2. Gom nhóm
            {
                $group: {
                    _id: groupBy,
                    totalRevenue: { $sum: '$totalPrice' },
                    // Giả sử lợi nhuận 30% doanh thu (vì schema không lưu giá vốn)
                    totalProfit: { $sum: { $multiply: ['$totalPrice', 0.3] } }, 
                    totalOrders: { $sum: 1 }
                }
            },
            
            // 3. Sắp xếp theo thời gian
            { $sort: sortBy },

            // 4. Format lại dữ liệu trả về cho đẹp
            {
                $project: {
                    _id: 0,
                    date: "$_id", // Trả về object ngày tháng
                    revenue: "$totalRevenue",
                    profit: "$totalProfit",
                    orders: "$totalOrders"
                }
            }
        ]);

        res.json(stats);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi thống kê', error: error.message });
    }
};

module.exports = { 
    getSimpleDashboardData,
    getAdvancedDashboardData 
};