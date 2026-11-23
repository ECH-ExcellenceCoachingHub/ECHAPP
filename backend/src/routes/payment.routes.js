const express = require('express');
const router = express.Router();

// Add logging for all requests to this router
router.use((req, res, next) => {
  console.log(`[payments] ${req.method} ${req.originalUrl}`);
  next();
});
const { 
  initiatePayment,
  adminInitiatePayment,
  verifyPayment,
  getMyPayments,
  getPaymentById,
  getAllPayments,
  cancelPayment,
  deletePayment,
  getPaymentStats,
  getPaymentOverview
} = require('../controllers/payment_workflow.controller');
const { getAdminPaymentsSimple } = require('../controllers/admin_payment_debug.controller');
const { generateInvoice } = require('../controllers/invoice.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Automatic payments (iTechPay). Webhook is public: it only names a reference,
// and the payment's status is always confirmed with iTechPay itself.
const checkout = require('../controllers/checkout.controller');
router.post('/itecpay/callback', checkout.callback);
router.get('/itecpay/callback', checkout.callback);
router.get('/checkout/methods', protect, checkout.methods);
router.post('/checkout', protect, checkout.start);
router.get('/checkout/:reference', protect, checkout.status);
router.post('/:id/recheck', protect, authorize('admin'), checkout.recheck);

// Student routes
router.post('/initiate', protect, initiatePayment);
router.post('/admin-initiate', protect, authorize('admin'), adminInitiatePayment);
router.get('/my-payments', protect, getMyPayments);
router.get('/my', protect, getMyPayments);

// Admin routes
router.get('/', protect, authorize('admin'), getAllPayments);
router.get('/stats', protect, authorize('admin'), getPaymentStats);
router.get('/admin/overview', protect, authorize('admin'), getPaymentOverview);
router.get('/admin-simple', protect, authorize('admin'), getAdminPaymentsSimple);
router.delete('/cancel/:paymentId', protect, cancelPayment);
router.delete('/:paymentId', protect, authorize('admin'), deletePayment);
router.get('/:paymentId/invoice', protect, generateInvoice);

// Specific payment routes (must come BEFORE parameterized routes to avoid conflicts)
router.post('/verify', protect, verifyPayment);
router.put('/verify', protect, authorize('admin'), verifyPayment);
router.get('/:id', protect, getPaymentById);

module.exports = router;