const express = require('express');
const { pinLogin, classCodeInfo, changePin } = require('../controllers/pinAuth.controller');
const router = express.Router();
const { chooseRole, register, login, refreshToken, getProfile, updateProfile, logout, startSession, recordSessionHeartbeat, googleSignIn, firebaseLogin, forgotPassword, resetPassword, verifyResetToken, resetUserDevice, deleteAccount } = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth.middleware');
const { adminOnly } = require('../middleware/admin.middleware');

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/pin-login', pinLogin);
router.post('/class-code', classCodeInfo);
router.post('/pin/change', protect, changePin);
router.post('/refresh-token', refreshToken);
router.post('/google', googleSignIn);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/verify-reset-token', verifyResetToken);

// Firebase authentication route
router.post('/firebase-login', firebaseLogin);

// Protected routes
router.get('/profile', protect, getProfile);
router.put('/profile', protect, updateProfile);
router.put('/role', protect, chooseRole);
router.post('/logout', protect, logout);
router.post('/session/start', protect, startSession);
router.post('/session/heartbeat', protect, recordSessionHeartbeat);
router.delete('/delete-account', protect, deleteAccount);

// Admin routes for device management
router.put('/admin/users/:userId/device-reset', protect, adminOnly, resetUserDevice);

module.exports = router;