// src/api/routes/orderRoutes.js

const express = require('express');
const router = express.Router();
const {
  createOrder,
  getMyOrders,
  getOrderById,
  getOrders,
  updateOrderStatus,
  createGuestOrder, // Import thêm hàm này
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
// GUEST ROUTES (Khách vãng lai - Không cần Token)
// =================================================================

/**
 * @swagger
 * /orders/guest:
 *   post:
 *     summary: Create a new order for Guest
 *     tags: [Orders]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, fullName, shippingAddress, paymentMethod, cartItems]
 *             properties:
 *               email:
 *                 type: string
 *                 example: "guest@example.com"
 *               fullName:
 *                 type: string
 *                 example: "Guest User"
 *               shippingAddress:
 *                 type: object
 *                 properties:
 *                   addressLine: { type: string, example: "123 Street" }
 *                   city: { type: string, example: "Hanoi" }
 *                   postalCode: { type: string, example: "10000" }
 *                   country: { type: string, example: "VN" }
 *               paymentMethod:
 *                 type: string
 *                 example: "COD"
 *               discountCode:
 *                 type: string
 *                 description: "Optional discount code"
 *                 example: "SALE50"
 *               cartItems:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     product: { type: string, example: "691d84f5113a4beb7f0fc494" }
 *                     variant: { type: string, example: "691d84f5113a4beb7f0fc495" }
 *                     quantity: { type: integer, example: 1 }
 *     responses:
 *       201:
 *         description: Guest order created
 */
router.post('/guest', createGuestOrder);

// =================================================================
// USER ROUTES (Cần đăng nhập - Có Token)
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
router.get('/myorders', protect, getMyOrders);


/**
 * @swagger
 * /orders:
 *   post:
 *     summary: Create a new order (Logged in User)
 *     description: "Creates order from User's Cart in Database. No items array needed in body."
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
 *                   addressLine: { type: string, example: "456 Tran Hung Dao" }
 *                   city: { type: string, example: "Ha Noi" }
 *                   postalCode: { type: string, example: "10000" }
 *                   country: { type: string, example: "VN" }
 *               paymentMethod:
 *                 type: string
 *                 example: "COD"
 *               discountCode:
 *                 type: string
 *                 example: "SALE50"
 *               useLoyaltyPoints:
 *                 type: boolean
 *                 example: false
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
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: "Format: YYYY-MM-DD"
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: "Format: YYYY-MM-DD"
 *     responses:
 *       200:
 *         description: A list of all orders
 */
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


module.exports = router;