// src/api/routes/productRoutes.js

const express = require('express');
const router = express.Router();
const {
  createProduct,
  getProducts,
  getProductById,
  updateProduct,
  deleteProduct,
  createProductReview,
} = require('../controllers/productController');
const { protect, admin } = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   name: Products
 *   description: Product management and retrieval
 */

/**
 * @swagger
 * /products:
 *   post:
 *     summary: Create a new product (Admin only)
 *     tags: [Products]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               brand:
 *                 type: string
 *               category:
 *                 type: string
 *                 description: "The ID of the category"
 *               images:
 *                 type: array
 *                 items:
 *                   type: string
 *               variants:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     name:
 *                       type: string
 *                     price:
 *                       type: number
 *                     stockQuantity:
 *                       type: number
 *             example:
 *               name: "Laptop Gaming XYZ"
 *               description: "A powerful gaming laptop"
 *               brand: "XYZ"
 *               category: "60c72b2f9b1e8a3a3c8d3e8a" # Thay bằng ID category thật
 *               images: ["/images/laptop1.jpg", "/images/laptop2.jpg"]
 *               variants:
 *                 - name: "16GB RAM, 512GB SSD"
 *                   price: 25000000
 *                   stockQuantity: 10
 *                 - name: "32GB RAM, 1TB SSD"
 *                   price: 32000000
 *                   stockQuantity: 5
 *     responses:
 *       201:
 *         description: Product created successfully
 *       400:
 *         description: Bad request
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Forbidden (not an admin)
 *
 *   get:
 *     summary: Get a list of products with advanced filtering, sorting, and pagination
 *     tags: [Products]
 *     parameters:
 *       - in: query
 *         name: keyword
 *         schema:
 *           type: string
 *         description: Search by product name (case-insensitive)
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number for pagination
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 12
 *         description: Number of items per page
 *       - in: query
 *         name: sort
 *         schema:
 *           type: string
 *         description: "Sort criteria. Prefix with '-' for descending order. E.g., 'price', '-price', 'name', '-name'"
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: "Filter by category ID"
 *       - in: query
 *         name: brand
 *         schema:
 *           type: string
 *         description: "Filter by brand(s). Separate multiple brands with comma. E.g., 'Dell,HP'"
 *       - in: query
 *         name: price[gte]
 *         schema:
 *           type: number
 *         description: "Filter by minimum price (greater than or equal to)"
 *       - in: query
 *         name: price[lte]
 *         schema:
 *           type: number
 *         description: "Filter by maximum price (less than or equal to)"
 *     responses:
 *       200:
 *         description: A list of products
 */

// SỬA Ở ĐÂY: Gộp cả GET và POST vào cùng một .route('/')
router.route('/')
  .get(getProducts)
  .post(protect, admin, createProduct);


/**
 * @swagger
 * /products/{id}:
 *   get:
 *     summary: Get a single product by ID
 *     tags: [Products]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Product details
 *       404:
 *         description: Product not found
 *
 *   put:
 *     summary: Update a product (Admin only)
 *     tags: [Products]
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
 *             $ref: '#/components/schemas/Product' 
 *     responses:
 *       200:
 *         description: Product updated
 *
 *   delete:
 *     summary: Delete a product (Admin only)
 *     tags: [Products]
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
 *         description: Product deleted
 */
router.route('/:id')
  .get(getProductById)
  .put(protect, admin, updateProduct)
  .delete(protect, admin, deleteProduct);

/**
 * @swagger
 * /products/{id}/reviews:
 *   post:
 *     summary: Create a new review for a product
 *     tags: [Products]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: The ID of the product to review
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - rating
 *               - comment
 *             properties:
 *               rating:
 *                 type: number
 *                 description: "Rating from 1 to 5"
 *                 example: 5
 *               comment:
 *                 type: string
 *                 description: "The review comment"
 *                 example: "Sản phẩm tuyệt vời!"
 *     responses:
 *       201:
 *         description: Review added successfully
 *       400:
 *         description: Bad request (e.g., product already reviewed)
 *       401:
 *         description: Not authorized
 *       404:
 *         description: Product not found
 */
router.route('/:id/reviews').post(protect, createProductReview);

module.exports = router;