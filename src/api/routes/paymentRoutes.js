// src/api/routes/paymentRoutes.js
const express = require('express');
const router = express.Router();
const { createPaymentUrl, vnpayReturn } = require('../controllers/paymentController');

/**
 * @swagger
 * tags:
 *   name: Payment
 *   description: VNPAY Integration
 */

/**
 * @swagger
 * /payment/create_payment_url:
 *   post:
 *     summary: Create VNPAY Payment URL
 *     tags: [Payment]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [orderId, amount]
 *             properties:
 *               orderId: { type: string }
 *               amount: { type: number }
 *               bankCode: { type: string, example: "NCB" }
 *               language: { type: string, example: "vn" }
 *     responses:
 *       200: { description: URL created }
 */
router.post('/create_payment_url', createPaymentUrl);

/**
 * @swagger
 * /payment/vnpay_return:
 *   get:
 *     summary: Handle VNPAY Return URL (Updates DB & Redirects)
 *     tags: [Payment]
 *     parameters:
 *       - in: query
 *         name: vnp_ResponseCode
 *         schema: { type: string }
 *     responses:
 *       302: { description: Redirect to Frontend }
 */
router.get('/vnpay_return', vnpayReturn);

module.exports = router;