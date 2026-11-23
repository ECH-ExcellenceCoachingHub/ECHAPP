/**
 * iTechPay gateway client (same integration eexams uses).
 *
 * Collects money from customers by MTN MoMo / Airtel Money (USSD prompt on the
 * phone) or card (Pesapal checkout page), and checks a payment's status.
 *
 * Env:
 *   ITECPAY_API_KEY_MOBILE_MONEY  MTN key
 *   ITECPAY_API_KEY_AIRTEL_MONEY  Airtel key
 *   ITECPAY_API_KEY_CARD          Pesapal (card) key
 *   ITECPAY_BASE_URL              e.g. https://pay.itecpay.rw/api (only the origin is used)
 *   ITECPAY_CALLBACK_URL          https://<ech-backend>/api/payments/itecpay/callback
 *
 * `req_ref` (a UUID we generate) is the one id that follows a payment from
 * start to finish. iTechPay answers {status: 200} for every call that reached
 * it, so only the INNER payment status says whether money moved.
 */
const crypto = require('crypto');

const REQUEST_TIMEOUT_MS = 30000;
const SUCCESS = ['completed', 'success', 'successful', 'paid', 'approved'];
const FAILED = ['cancelled', 'canceled', 'rejected', 'failed', 'failure', 'error', 'declined', 'expired', 'timeout'];

// ECH method names → iTechPay provider keys.
const PROVIDER = { mtn_momo: 'mtn', mobile_money: 'mtn', airtel_money: 'airtel', card: 'card' };

function origin() {
  try { return new URL(process.env.ITECPAY_BASE_URL || 'https://pay.itecpay.rw').origin; }
  catch { return 'https://pay.itecpay.rw'; }
}

function apiKey(method) {
  const provider = PROVIDER[method];
  const key = {
    mtn: process.env.ITECPAY_API_KEY_MOBILE_MONEY,
    airtel: process.env.ITECPAY_API_KEY_AIRTEL_MONEY,
    card: process.env.ITECPAY_API_KEY_CARD,
  }[provider];
  if (!key) {
    const err = new Error(`Online payment with ${method} is not configured yet.`);
    err.isConfigError = true;
    throw err;
  }
  return key;
}

function isConfigured(method) {
  try { apiKey(method); return true; } catch { return false; }
}

/** Rwandan phone → local 07XXXXXXXX (what /api2/pay expects). Returns null when it isn't one. */
function normalizePhone(phone) {
  let p = String(phone || '').replace(/[\s\-().]/g, '');
  if (p.startsWith('+')) p = p.slice(1);
  if (p.startsWith('250') && p.length === 12) p = '0' + p.slice(3);
  if (!p.startsWith('0') && p.length === 9) p = '0' + p;
  return /^07\d{8}$/.test(p) ? p : null;
}

/** MTN numbers start 078/079, Airtel 072/073. */
function phoneMatchesMethod(phone, method) {
  const p = normalizePhone(phone);
  if (!p) return false;
  if (method === 'mtn_momo') return /^07[89]/.test(p);
  if (method === 'airtel_money') return /^07[23]/.test(p);
  return true;
}

const accepted = (r) => {
  const s = String(r?.status ?? '').toLowerCase();
  return r?.status === 200 || r?.status === true || r?.status === 1 || ['success', 'ok', '200'].includes(s);
};

async function post(path, body) {
  const url = origin() + path;
  const safe = { ...body, key: body.key ? body.key.slice(0, 6) + '…' : undefined };
  console.log(`[iTechPay] → POST ${url} ${JSON.stringify(safe)}`);

  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), REQUEST_TIMEOUT_MS);
  let response;
  let text;
  try {
    response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify(body),
      signal: ctrl.signal,
    });
    text = await response.text();
  } catch (e) {
    const err = new Error(e.name === 'AbortError' ? 'The payment service did not answer in time.' : `Could not reach the payment service: ${e.message}`);
    err.isGatewayError = true;
    // A timed-out request may still have reached iTechPay.
    err.outcomeUnknown = e.name === 'AbortError';
    throw err;
  } finally {
    clearTimeout(timer);
  }
  console.log(`[iTechPay] ← HTTP ${response.status} ${text.slice(0, 400)}`);

  try {
    return JSON.parse(text);
  } catch {
    // A 2xx with an unreadable body means iTechPay accepted the request but we
    // can't read the outcome: callers must treat it as "unknown", not "failed".
    const err = new Error(text.trim()
      ? `The payment service returned an unreadable answer (HTTP ${response.status}).`
      : `The payment service returned an empty answer (HTTP ${response.status}).`);
    err.isGatewayError = true;
    err.outcomeUnknown = response.ok;
    throw err;
  }
}

/**
 * Starts a payment. Returns { reference, gatewayId, paymentUrl }:
 * paymentUrl is set for card (send the user there), null for mobile money
 * (the customer approves a USSD prompt on their phone).
 */
async function createPaymentRequest({ amount, method, phone, email, currency = 'RWF', reference = crypto.randomUUID() }) {
  const key = apiKey(method);
  const value = Math.round(Number(amount));
  if (!(value > 0)) throw new Error('Amount must be more than 0');

  if (method === 'card') {
    if (!email) throw new Error('An email address is required for card payments');
    const r = await post('/api/pay/apis/pesapal/generatecode', {
      amount: value,
      email: String(email).trim(),
      key,
      req_ref: reference,
      currency,
      callback_url: process.env.ITECPAY_CALLBACK_URL,
    });
    const pcode = r?.PCODE;
    if (!pcode) {
      const notActive = r?.status === 500 || String(r?.error || '').toLowerCase().includes('initiate failed');
      const err = new Error(notActive
        ? 'Card payment is not available yet. Please pay with MTN MoMo or Airtel Money.'
        : (r?.message || r?.error || 'Card payment is unavailable right now.'));
      err.isGatewayError = true;
      throw err;
    }
    return {
      reference,
      gatewayId: String(pcode),
      paymentUrl: r.link || `${origin()}/api/pay/apis/pesapal/index?PCODE=${pcode}`,
    };
  }

  const local = normalizePhone(phone);
  if (!local) throw new Error('Enter a valid Rwandan phone number (07XXXXXXXX)');
  const r = await post('/api2/pay', { amount: value, phone: local, key, req_ref: reference });
  if (!accepted(r)) {
    const err = new Error(r?.data?.message || r?.message || 'The mobile money request was refused. Check the number and try again.');
    err.isGatewayError = true;
    throw err;
  }
  return {
    reference,
    gatewayId: String(r?.data?.transaction_id || r?.data?.financial_transaction_id || reference),
    paymentUrl: null,
  };
}

/**
 * Asks iTechPay whether a payment went through.
 * → { state: 'paid' | 'failed' | 'pending', status, amount, transactionId }
 */
async function verifyPayment(reference, method) {
  const r = await post('/api2/verify', { action: 'status_check', req_ref: reference, key: apiKey(method) });
  const status = String(
    r?.transaction_status || r?.data?.transaction_status ||
    r?.payment_status || r?.data?.payment_status ||
    r?.data?.status ||
    // A bare numeric/boolean top-level status is the API-call result, not the payment's.
    (typeof r?.status === 'string' && !/^\d+$/.test(r.status) ? r.status : '') ||
    ''
  ).toLowerCase();
  const amount = Number(r?.data?.amount ?? r?.amount);
  return {
    state: SUCCESS.includes(status) ? 'paid' : FAILED.includes(status) ? 'failed' : 'pending',
    status: status || 'unknown',
    amount: Number.isFinite(amount) ? amount : null,
    transactionId: r?.data?.transaction_id || r?.transaction_id || r?.data?.financial_transaction_id || null,
  };
}

module.exports = {
  createPaymentRequest,
  verifyPayment,
  normalizePhone,
  phoneMatchesMethod,
  isConfigured,
  METHODS: Object.keys(PROVIDER).filter((m) => m !== 'mobile_money'),
};
