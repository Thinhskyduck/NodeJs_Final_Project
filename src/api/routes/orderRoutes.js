// src/api/routes/orderRoutes.js

const express = require('express');
const router = express.Router();
const {
  createOrder,
  getMyOrders,
  getOrderById,
  getOrders,
  updateOrderStatus,
  createGuestOrder 
} = require('../controllers/orderController');
// Import một lần duy nhất
const { protect, admin } = require('../middlewares/authMiddleware');


/**
 * @swagger
 * tags:
 *   name: Orders
 *   description: Order management
 */


// =================================================================
// USER ROUTES (Các route dành cho người dùng thông thường)
// =================================================================

/**
 * @swagger
 * /orders/myorders:
 *   get:
 *     summary: Get logged in user's orders (USER)
 *     tags: [Orders]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: A list of the user's orders
 */
// Route này phải được đặt TRƯỚC '/:id'
router.get('/myorders', protect, getMyOrders);


/**
 * @swagger
 * /orders:
 *   post:
 *     summary: Create a new order (USER)
 *     tags: [Orders]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [shippingAddress, paymentMethod]
 *             properties:
 *               shippingAddress:
 *                 type: object
 *                 properties:
 *                   addressLine: { type: string }
 *                   city: { type: string }
 *                   postalCode: { type: string }
 *                   country: { type: string }
 *               paymentMethod:
 *                 type: string
 *                 example: "COD"
 *               discountCode:
 *                 type: string
 *                 example: "SALE10"
 *     responses:
 *       201:
 *         description: Order created successfully
 */
router.post('/', protect, createOrder);


/**
 * @swagger
 * /orders/{id}:
 *   get:
 *     summary: Get a specific order by ID (USER or ADMIN)
 *     tags: [Orders]
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
 *         description: Order details
 */
router.get('/:id', protect, getOrderById);


// =================================================================
// ADMIN ROUTES (Các route chỉ dành cho Admin)
// =================================================================


/**
 * @swagger
 * /orders/admin/all:
 *   get:
 *     summary: Get all orders in the system (ADMIN)
 *     tags: [Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: A list of all orders
 */
 // Tôi đã đổi tên route này thành /admin/all để tránh xung đột với route GET /:id và POST /
router.get('/admin/all', protect, admin, getOrders);


/**
 * @swagger
 * /orders/{id}/status:
 *   put:
 *     summary: Update order status (ADMIN)
 *     tags: [Orders]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [pending, confirmed, shipping, delivered, cancelled]
 *     responses:
 *       200:
 *         description: Order status updated
 */
router.put('/:id/status', protect, admin, updateOrderStatus);

/**
 * @swagger
 * /orders/guest:
 *   post:
 *     summary: Create a new order for a guest user
 *     tags: [Orders]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *                email: { type: string }
 *                fullName: { type: string }
 *                shippingAddress: { type: object }
 *                paymentMethod: { type: string }
 *                cartItems:
 *                  type: array
 *                  items:
 *                     type: object
 *                     properties:
 *                         name: { type: string }
 *                         quantity: { type: number }
 *                         image: { type: string }
 *                         price: { type: number }
 *                         product: { type: string }
 *                         variant: { type: string }
 *     responses:
 *       201:
 *         description: Guest order created successfully
 */
router.post('/guest', createGuestOrder);

module.exports = router;