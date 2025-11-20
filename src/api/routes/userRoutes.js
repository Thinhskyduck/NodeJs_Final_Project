// src/api/routes/userRoutes.js

const express = require('express');
const router = express.Router();
const { registerUser, loginUser, getUserProfile, updateUserProfile, 
    changePassword, 
    addAddress,
    forgotPassword,
    resetPassword } = require('../controllers/userController');
const { protect } = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   name: Users
 *   description: User management and authentication
 */

/**
 * @swagger
 * /users/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - fullName
 *               - email
 *               - password
 *             properties:
 *               fullName:
 *                 type: string
 *                 example: "Châu Nguyễn Khánh Trình"
 *               email:
 *                 type: string
 *                 format: email
 *                 example: "khantrinh293@gmail.com"
 *               password:
 *                 type: string
 *                 format: password
 *                 example: "123456"
 *     responses:
 *       201:
 *         description: User created successfully
 *       400:
 *         description: Bad request (e.g., email already exists, missing fields)
 *       500:
 *         description: Internal server error
 */
router.post('/register', registerUser);

/**
 * @swagger
 * /users/login:
 *   post:
 *     summary: Login a user
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: "khantrinh293@gmail.com"
 *               password:
 *                 type: string
 *                 format: password
 *                 example: "password123"
 *     responses:
 *       200:
 *         description: Login successful, returns user info and token
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 _id:
 *                   type: string
 *                 fullName:
 *                   type: string
 *                 email:
 *                   type: string
 *                 role:
 *                   type: string
 *                 token:
 *                   type: string
 *       401:
 *         description: Invalid email or password
 */
router.post('/login', loginUser);

/**
 * @swagger
 * /users/profile:
 *   get:
 *     summary: Get user profile
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Successful response with user profile
 *       401:
 *         description: Not authorized (token missing or invalid)
 *       404:
 *         description: User not found
 */
// Áp dụng middleware `protect` vào route này
// Bất kỳ request nào tới '/profile' sẽ phải đi qua `protect` trước
router.route('/profile')
    .get(protect, getUserProfile)
    .put(protect, updateUserProfile);

/**
 * @swagger
 * /users/change-password:
 *   put:
 *     summary: Change password (Logged in user)
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [oldPassword, newPassword]
 *             properties:
 *               oldPassword: { type: string }
 *               newPassword: { type: string }
 *     responses:
 *       200: { description: Password updated }
 *       401: { description: Incorrect old password }
 */
router.put('/change-password', protect, changePassword);

/**
 * @swagger
 * /users/forgot-password:
 *   post:
 *     summary: Request password reset email
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email]
 *             properties:
 *               email: { type: string, format: email }
 *     responses:
 *       200: { description: Email sent }
 *       404: { description: User not found }
 */
router.post('/forgot-password', forgotPassword);

/**
 * @swagger
 * /users/reset-password/{resetToken}:
 *   put:
 *     summary: Reset password using token
 *     tags: [Users]
 *     parameters:
 *       - in: path
 *         name: resetToken
 *         required: true
 *         schema: { type: string }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [password]
 *             properties:
 *               password: { type: string, description: "New password" }
 *     responses:
 *       200: { description: Password reset successful }
 *       400: { description: Invalid or expired token }
 */
router.put('/reset-password/:resetToken', resetPassword);

router.route('/addresses')
    .post(protect, addAddress);

module.exports = router;