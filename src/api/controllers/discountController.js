// src/api/controllers/discountController.js
const Discount = require('../models/discountModel');

// @desc    Kiểm tra mã giảm giá (Pre-validate)
// @route   POST /api/discounts/validate
// @access  Public (Khách và User đều dùng được)
const validateDiscount = async (req, res) => {
    try {
        const { code, cartTotal } = req.body;

        if (!code || !cartTotal) {
            return res.status(400).json({ message: 'Vui lòng cung cấp mã giảm giá và tổng tiền đơn hàng' });
        }

        // 1. Tìm mã
        const discount = await Discount.findOne({ code: code.toUpperCase(), isActive: true });

        // 2. Kiểm tra tồn tại
        if (!discount) {
            return res.status(404).json({ message: 'Mã giảm giá không hợp lệ hoặc đã bị khóa' });
        }

        // 3. Kiểm tra số lượt sử dụng
        if (discount.timesUsed >= discount.maxUses) {
            return res.status(400).json({ message: 'Mã giảm giá đã hết lượt sử dụng' });
        }

        // 4. (Optional) Kiểm tra ngày hết hạn nếu Model có trường startDate/endDate
        // const now = new Date();
        // if (discount.endDate && now > discount.endDate) ...

        // 5. Tính toán số tiền giảm
        let discountAmount = 0;
        if (discount.discountType === 'fixed') {
            discountAmount = discount.value;
        } else if (discount.discountType === 'percentage') {
            discountAmount = (cartTotal * discount.value) / 100;
        }

        // Không được giảm quá tổng tiền hàng
        if (discountAmount > cartTotal) {
            discountAmount = cartTotal;
        }

        res.status(200).json({
            valid: true,
            code: discount.code,
            discountType: discount.discountType,
            discountValue: discount.value, // Giá trị gốc (vd: 10% hoặc 50k)
            discountAmount: discountAmount, // Số tiền thực tế được giảm (vd: 100k)
            newTotal: cartTotal - discountAmount
        });

    } catch (error) {
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

// --- CÁC HÀM CŨ (ADMIN) GIỮ NGUYÊN ---

// @desc    Tạo mã giảm giá mới
const createDiscount = async (req, res) => {
    try {
        const { code, value, maxUses, discountType } = req.body;
        const discountExists = await Discount.findOne({ code });
        if (discountExists) {
            return res.status(400).json({ message: 'Mã giảm giá này đã tồn tại' });
        }
        const discount = await Discount.create({
            code: code.toUpperCase(),
            value,
            maxUses,
            discountType: discountType || 'fixed'
        });
        res.status(201).json(discount);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

// @desc    Lấy tất cả mã giảm giá
const getDiscounts = async (req, res) => {
    try {
        const discounts = await Discount.find({});
        res.json(discounts);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
    }
};

// @desc    Xóa mã giảm giá
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
    validateDiscount, // <-- Export thêm hàm này
    createDiscount,
    getDiscounts,
    deleteDiscount
};