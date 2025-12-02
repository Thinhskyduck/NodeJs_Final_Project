// src/api/controllers/adminController.js
const User = require('../models/userModel');
const Discount = require('../models/discountModel');

// --- User Management ---
const getUsers = async (req, res) => {
    const users = await User.find({}).select('-password');
    res.json(users);
};

const updateUserRole = async (req, res) => {
    const user = await User.findById(req.params.id);
    if (user) {
        user.role = req.body.role || user.role;
        await user.save();
        res.json({ message: 'User role updated' });
    } else {
        res.status(404).json({ message: 'User not found' });
    }
};


// --- Discount Management ---
const createDiscount = async (req, res) => {
    const { code, value, maxUses, discountType } = req.body;
    const discount = await Discount.create({ code, value, maxUses, discountType });
    res.status(201).json(discount);
};

const getDiscounts = async (req, res) => {
    const discounts = await Discount.find({});
    res.json(discounts);
};

module.exports = {
    getUsers,
    updateUserRole,
    createDiscount,
    getDiscounts
};