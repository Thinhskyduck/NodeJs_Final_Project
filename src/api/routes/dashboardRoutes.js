// src/api/routes/dashboardRoutes.js
const express = require('express');
const router = express.Router();
const { 
    getSimpleDashboardData, 
    getAdvancedDashboardData // Import hàm mới
} = require('../controllers/dashboardController');
const { protect, admin } = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   name: Dashboard
 *   description: Admin Dashboard Statistics
 */

// Tất cả route dashboard đều cần quyền Admin
router.use(protect, admin);

/**
 * @swagger
 * /dashboard/simple:
 *   get:
 *     summary: Get simple stats (Cards & Top Products)
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Success
 */
router.get('/simple', getSimpleDashboardData);

/**
 * @swagger
 * /dashboard/advanced:
 *   get:
 *     summary: Get advanced chart data (Revenue/Profit)
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [month, year]
 *         description: "Group by: 'month' (daily stats) or 'year' (monthly stats)"
 *     responses:
 *       200:
 *         description: Array of stats for charts
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   revenue: { type: number }
 *                   profit: { type: number }
 *                   orders: { type: number }
 *                   date: 
 *                      type: object
 *                      properties:
 *                          day: { type: integer }
 *                          month: { type: integer }
 *                          year: { type: integer }
 */
router.get('/advanced', getAdvancedDashboardData);

module.exports = router;