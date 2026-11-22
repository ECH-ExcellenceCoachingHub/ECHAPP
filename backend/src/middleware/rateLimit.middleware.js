/**
 * Small in-memory rate limiter (fixed window), keyed by the real client IP
 * (see utils/clientIp.js — Render's proxy address would put everyone in one bucket).
 *
 * Schools put a whole computer lab behind ONE public IP, so limits are keyed by
 * IP + who is calling (the bearer token, or the sign-in identifier) wherever
 * possible, with a much higher cap for the IP alone.
 *
 * Disabled in tests. Tune with RATE_LIMIT_SCALE (e.g. 2 doubles every limit).
 */
const crypto = require('crypto');
const { clientIp } = require('../utils/clientIp');

const SCALE = Number(process.env.RATE_LIMIT_SCALE || 1) || 1;
const disabled = () => process.env.NODE_ENV === 'test' || process.env.RATE_LIMIT_DISABLED === 'true';

function rateLimit({ name, windowMs, max, key }) {
  const hits = new Map();
  const limit = Math.max(1, Math.round(max * SCALE));
  let lastSweep = Date.now();

  return (req, res, next) => {
    if (disabled()) return next();
    const now = Date.now();
    if (now - lastSweep > windowMs) {
      for (const [k, v] of hits) if (v.reset <= now) hits.delete(k);
      lastSweep = now;
    }
    const k = `${name}:${key(req)}`;
    let e = hits.get(k);
    if (!e || e.reset <= now) {
      e = { n: 0, reset: now + windowMs };
      hits.set(k, e);
    }
    e.n += 1;
    if (e.n > limit) {
      const wait = Math.ceil((e.reset - now) / 1000);
      res.set('Retry-After', String(wait));
      return res.status(429).json({ success: false, code: 'RATE_LIMITED', message: `Too many requests. Please wait ${wait > 60 ? `${Math.ceil(wait / 60)} minutes` : `${wait} seconds`} and try again.` });
    }
    return next();
  };
}

const hash = (s) => crypto.createHash('sha1').update(String(s)).digest('base64').slice(0, 16);
const caller = (req) => {
  const auth = req.headers?.authorization;
  return auth ? hash(auth) : 'anon';
};
const identifier = (req) => {
  const b = req.body || {};
  const id = b.email || b.emailOrPhone || b.identifier || b.phone || b.code || '';
  return hash(String(id).toLowerCase().trim());
};

/** Whole API: per caller, and a generous cap per IP (a school lab shares one). */
const apiPerCaller = rateLimit({ name: 'api', windowMs: 60 * 1000, max: 300, key: (r) => `${clientIp(r)}|${caller(r)}` });
const apiPerIp = rateLimit({ name: 'api-ip', windowMs: 60 * 1000, max: 3000, key: (r) => clientIp(r) });

/** Sign-in / registration / password reset: per account and per IP. */
const authPerAccount = rateLimit({ name: 'auth-acct', windowMs: 10 * 60 * 1000, max: 15, key: (r) => `${clientIp(r)}|${identifier(r)}` });
const authPerIp = rateLimit({ name: 'auth-ip', windowMs: 10 * 60 * 1000, max: 400, key: (r) => clientIp(r) });

/** Expensive endpoints (uploads, AI). */
const heavyPerCaller = rateLimit({ name: 'heavy', windowMs: 60 * 1000, max: 30, key: (r) => `${clientIp(r)}|${caller(r)}` });

module.exports = { rateLimit, apiPerCaller, apiPerIp, authPerAccount, authPerIp, heavyPerCaller };
