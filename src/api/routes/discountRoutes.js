// src/api/routes/discountRoutes.js
const express = require('express');
const router = express.Router();
const { 
    validateDiscount, // Import hàm mới
    createDiscount, 
    getDiscounts, 
    deleteDiscount 
} = require('../controllers/discountController');
const { protect, admin } = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   name: Discounts
 *   description: Discount code management
 */

// ========================================================
// PUBLIC ROUTES (Ai cũng dùng được, kể cả Guest)
// ========================================================

/**
 * @swagger
 * /discounts/validate:
 *   post:
 *     summary: Validate a discount code before checkout
 *     tags: [Discounts]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [code, cartTotal]
 *             properties:
 *               code:
 *                 type: string
 *                 example: "SALE50"
 *               cartTotal:
 *                 type: number
 *                 example: 500000
 *     responses:
 *       200:
 *         description: Valid coupon
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                  valid: { type: boolean }
 *                  discountAmount: { type: number }
 *                  newTotal: { type: number }
 *       404:
 *         description: Invalid code
 */
router.post('/validate', validateDiscount);


// ========================================================
// ADMIN ROUTES (Chỉ Admin mới được thêm/xóa mã)
// ========================================================

// Áp dụng bảo vệ cho các route bên dưới dòng này
router.use(protect, admin);

/**
 * @swagger
 * /discounts:
 *   get:
 *     summary: Get all discount codes (Admin)
 *     tags: [Discounts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: List of discounts }
 *   post:
 *     summary: Create a new discount code (Admin)
 *     tags: [Discounts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [code, value, maxUses]
 *             properties:
 *               code: { type: string }
 *               value: { type: number }
 *               maxUses: { type: number }
 *               discountType: { type: string, enum: [fixed, percentage] }
 *     responses:
 *       201: { description: Discount created }
 */
router.route('/')
    .get(getDiscounts)
    .post(createDiscount);

/**
 * @swagger
 * /discounts/{id}:
 *   delete:
 *     summary: Delete a discount code (Admin)
 *     tags: [Discounts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Discount deleted }
 */
router.route('/:id').delete(deleteDiscount);

module.exports = router;