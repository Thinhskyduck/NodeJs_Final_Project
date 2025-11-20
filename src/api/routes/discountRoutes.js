// src/api/routes/discountRoutes.js
const express = require('express');
const router = express.Router();
const { createDiscount, getDiscounts, deleteDiscount } = require('../controllers/discountController');
const { protect, admin } = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   name: Discounts
 *   description: Discount code management (Admin only)
 */

// Tất cả các route dưới đây đều cần quyền Admin
router.use(protect, admin);

/**
 * @swagger
 * /discounts:
 *   get:
 *     summary: Get all discount codes
 *     tags: [Discounts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of discounts
 *   post:
 *     summary: Create a new discount code
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
 *               code:
 *                 type: string
 *                 example: "SALE50"
 *               value:
 *                 type: number
 *                 example: 50000
 *               maxUses:
 *                 type: number
 *                 example: 10
 *               discountType:
 *                 type: string
 *                 enum: [fixed, percentage]
 *                 default: fixed
 *     responses:
 *       201:
 *         description: Discount created
 */
router.route('/')
    .get(getDiscounts)
    .post(createDiscount);

/**
 * @swagger
 * /discounts/{id}:
 *   delete:
 *     summary: Delete a discount code
 *     tags: [Discounts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Discount deleted
 */
router.route('/:id').delete(deleteDiscount);

module.exports = router;    