// src/api/controllers/discountController.js
const Discount = require('../models/discountModel');

// @desc    Tạo mã giảm giá mới
// @route   POST /api/discounts
// @access  Private/Admin
const createDiscount = async (req, res) => {
    try {
        const { code, value, maxUses, discountType } = req.body;

        // Kiểm tra xem mã đã tồn tại chưa
        const discountExists = await Discount.findOne({ code });
        if (discountExists) {
            return res.status(400).json({ message: 'Mã giảm giá này đã tồn tại' });
        }

        const discount = await Discount.create({
            code,
            value,
            maxUses,
            discountType: discountType || 'fixed' // Mặc định là giảm tiền mặt nếu không chọn
        });

        res.status(201).json(discount);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

// @desc    Lấy tất cả mã giảm giá
// @route   GET /api/discounts
// @access  Private/Admin
const getDiscounts = async (req, res) => {
    try {
        const discounts = await Discount.find({});
        res.json(discounts);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

// @desc    Xóa mã giảm giá
// @route   DELETE /api/discounts/:id
// @access  Private/Admin
const deleteDiscount = async (req, res) => {
    try {
        const discount = await Discount.findById(req.params.id);

        if (discount) {
            await discount.deleteOne();
            res.json({ message: 'Mã giảm giá đã được xóa' });
        } else {
            res.status(404).json({ message: 'Không tìm thấy mã giảm giá' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

module.exports = {
    createDiscount,
    getDiscounts,
    deleteDiscount
};