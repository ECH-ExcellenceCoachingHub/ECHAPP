/**
 * Automatic (iTechPay) payments: start, poll status, webhook, admin re-check.
 * The logic lives in services/payments/checkout.service.js.
 */
const Payment = require('../models/Payment');
const checkout = require('../services/payments/checkout.service');
const itecpay = require('../services/payments/itecpay.service');

function fail(res, err) {
  if (err instanceof checkout.CheckoutError) {
    return res.status(err.status).json({ success: false, message: err.message, ...err.extra });
  }
  console.error('[checkout]', err);
  return res.status(500).json({ success: false, message: 'Payment failed to start. Please try again.' });
}

const STATUS_MESSAGE = {
  pending: 'Waiting for you to approve the payment',
  completed: 'Payment received',
  approved: 'Payment received',
  admin_review: 'Payment received. ECH is finishing your order.',
  failed: 'The payment did not go through',
  cancelled: 'Payment cancelled',
};

function statusView(p) {
  const v = checkout.view(p);
  let message = STATUS_MESSAGE[p.status] || p.status;
  if (p.status === 'failed' && p.gateway?.failureReason === 'timeout') {
    message = 'We did not get a confirmation in time. If money left your account, it will be applied automatically within a few minutes, or contact ECH.';
  } else if (p.status === 'failed' && p.gateway?.failureReason === 'declined') {
    message = 'The payment was declined or cancelled on the phone. You were not charged.';
  }
  return { ...v, paid: ['completed', 'approved'].includes(p.status), message };
}

/** GET /api/payments/checkout/methods — which methods can be used right now. */
const methods = (req, res) => {
  res.json({
    success: true,
    data: {
      methods: [
        { id: 'mtn_momo', label: 'MTN MoMo', enabled: itecpay.isConfigured('mtn_momo') },
        { id: 'airtel_money', label: 'Airtel Money', enabled: itecpay.isConfigured('airtel_money') },
        { id: 'card', label: 'Card (Visa / Mastercard)', enabled: itecpay.isConfigured('card') },
      ],
    },
  });
};

/** POST /api/payments/checkout {purpose, courseId | schoolId+termId+students, paymentMethod, phone | email} */
const start = async (req, res) => {
  try {
    const data = await checkout.start(req.user._id || req.user.id, req.body || {});
    const message = data.paymentUrl
      ? 'Complete the payment on the card page.'
      : `Check your phone ${data.phone} and enter your PIN to approve RWF ${Number(data.amount).toLocaleString()}.`;
    res.status(data.resumed ? 200 : 201).json({ success: true, message, data });
  } catch (err) {
    fail(res, err);
  }
};

/** GET /api/payments/checkout/:reference — the app polls this while the user approves. */
const status = async (req, res) => {
  try {
    const p = await Payment.findOne({ 'gateway.reference': req.params.reference });
    if (!p) return res.status(404).json({ success: false, message: 'Payment not found' });
    if (String(p.userId) !== String(req.user._id || req.user.id) && req.user.role !== 'admin') {
      return res.status(404).json({ success: false, message: 'Payment not found' });
    }
    const fresh = await checkout.refresh(p, { via: 'poll' });
    res.json({ success: true, data: statusView(fresh) });
  } catch (err) {
    fail(res, err);
  }
};

/**
 * POST|GET /api/payments/itecpay/callback — public webhook. The body is only
 * used to find OUR payment; whether it was paid is always asked from iTechPay.
 */
const callback = async (req, res) => {
  try {
    const reference = checkout.referenceFrom(req.body || {}, req.query || {});
    console.log(`[payments] iTechPay callback ref=${reference} status=${req.body?.status || req.body?.data?.status || req.query?.status}`);
    if (!reference) return res.status(400).json({ success: false, message: 'Missing req_ref' });
    const p = await Payment.findOne({ 'gateway.reference': String(reference) });
    if (!p) return res.status(404).json({ success: false, message: 'Payment reference not recognized' });
    const fresh = await checkout.refresh(p, { via: 'callback', force: true });
    // A card customer lands here in the browser after Pesapal: show a plain page.
    if (req.method === 'GET') {
      const ok = ['completed', 'approved'].includes(fresh.status);
      return res.type('html').send(`<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1"><title>Payment</title><body style="font-family:sans-serif;text-align:center;padding:48px 16px"><h2>${ok ? 'Payment received ✅' : 'Payment is being confirmed…'}</h2><p>You can close this page and return to the Excellence Coaching Hub app.</p></body>`);
    }
    res.json({ success: true, status: fresh.status });
  } catch (err) {
    console.error('[payments] callback error:', err);
    res.status(500).json({ success: false, message: 'Callback processing failed' });
  }
};

/** POST /api/payments/:id/recheck (admin) — ask iTechPay again right now. */
const recheck = async (req, res) => {
  try {
    const p = await Payment.findById(req.params.id);
    if (!p) return res.status(404).json({ success: false, message: 'Payment not found' });
    if (p.gateway?.provider !== 'itecpay') return res.status(400).json({ success: false, message: 'This payment was not made online' });
    const fresh = await checkout.refresh(p, { via: 'admin', force: true });
    res.json({ success: true, data: statusView(fresh), message: STATUS_MESSAGE[fresh.status] || fresh.status });
  } catch (err) {
    fail(res, err);
  }
};

module.exports = { methods, start, status, callback, recheck };
