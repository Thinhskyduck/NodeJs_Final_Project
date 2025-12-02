// src/api/routes/cartRoutes.js

const express = require('express');
const router = express.Router();
const {
  getCart,
  addItemToCart,
  removeItemFromCart
} = require('../controllers/cartController');
const { protect } = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   name: Cart
 *   description: Shopping cart management
 */

router.use(protect); // Áp dụng middleware `protect` cho tất cả các route bên dưới

/**
 * @swagger
 * /cart:
 *   get:
 *     summary: Get user's shopping cart
 *     tags: [Cart]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: The user's cart
 *   post:
 *     summary: Add an item to the cart or update its quantity
 *     tags: [Cart]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [productId, variantId, quantity]
 *             properties:
 *               productId:
 *                 type: string
 *               variantId:
 *                 type: string
 *               quantity:
 *                 type: number
 *     responses:
 *       200:
 *         description: Item added/updated in cart
 */
router.route('/')
  .get(getCart)
  .post(addItemToCart);

/**
 * @swagger
 * /cart/items/{itemId}:
 *   delete:
 *     summary: Remove an item from the cart
 *     tags: [Cart]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: itemId
 *         required: true
 *         schema:
 *           type: string
 *         description: The ID of the cart item to remove
 *     responses:
 *       200:
 *         description: Item removed from cart
 */
router.route('/items/:itemId').delete(removeItemFromCart);

module.exports = router;