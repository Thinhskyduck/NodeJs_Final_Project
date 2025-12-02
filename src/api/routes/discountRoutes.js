// src/api/routes/discountRoutes.js
const express = require('express');
const router = express.Router();
const { 
    validateDiscount, 
    createDiscount, 
    getDiscounts, 
    deleteDiscount 
} = require('../controllers/discountController');
const { protect, admin } = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   name: Discounts
 *   description: Discount management
 */

/**
 * @swagger
 * /discounts/validate:
 *   post:
 *     summary: Validate a discount code (Public)
 *     tags: [Discounts]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [code, cartTotal]
 *             properties:
 *               code: { type: string, example: "SALE50" }
 *               cartTotal: { type: number, example: 200000 }
 *     responses:
 *       200: { description: Valid }
 *       404: { description: Invalid }
 */
router.post('/validate', validateDiscount);

router.use(protect, admin);

/**
 * @swagger
 * /discounts:
 *   get:
 *     summary: Get all discounts (Admin)
 *     tags: [Discounts]
 *     responses: { 200: { description: List } }
 *   post:
 *     summary: Create discount (Admin)
 *     tags: [Discounts]
 *     description: "Note: Code must be exactly 5 characters. Max uses limit is 10."
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
 *                 description: "Must be exactly 5 characters"
 *                 example: "ABCDE"
 *               value: { type: number, example: 50000 }
 *               maxUses: 
 *                 type: number
 *                 description: "Max 10 uses per code"
 *                 example: 10
 *               discountType: { type: string, enum: [fixed, percentage], default: fixed }
 *     responses:
 *       201: { description: Created }
 *       400: { description: Validation Error }
 */
router.route('/')
    .get(getDiscounts)
    .post(createDiscount);

router.route('/:id').delete(deleteDiscount);

module.exports = router;