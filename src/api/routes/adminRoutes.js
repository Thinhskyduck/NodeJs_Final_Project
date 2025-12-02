// src/api/routes/adminRoutes.js
const express = require('express');
const router = express.Router();
const { getUsers, updateUserRole, createDiscount, getDiscounts } = require('../controllers/adminController');
const { protect, admin } = require('../middlewares/authMiddleware');

// Tất cả các route trong file này đều yêu cầu là admin
router.use(protect, admin);

// User routes
router.route('/users').get(getUsers);
router.route('/users/:id/role').put(updateUserRole);

// Discount routes
router.route('/discounts').get(getDiscounts).post(createDiscount);

module.exports = router;