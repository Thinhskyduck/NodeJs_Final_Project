// src/api/routes/dashboardRoutes.js
const express = require('express');
const router = express.Router();
const { getSimpleDashboardData } = require('../controllers/dashboardController');
const { protect, admin } = require('../middlewares/authMiddleware');

router.get('/simple', protect, admin, getSimpleDashboardData);

module.exports = router;