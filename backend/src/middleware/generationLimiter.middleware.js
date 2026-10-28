/**
 * Per-user rate limit for expensive generation actions (video / figure jobs).
 * In-memory sliding window — adequate for a single API instance; the queue's
 * unique job keys and spending limits are the real protection against
 * duplicate or runaway work.
 *
 *   GENERATION_RATE_LIMIT        requests per window (default 30)
 *   GENERATION_RATE_WINDOW_MS    window length (default 10 minutes)
 */
const hits = new Map();

function generationLimiter(req, res, next) {
  const max = parseInt(process.env.GENERATION_RATE_LIMIT || '30', 10);
  const windowMs = parseInt(process.env.GENERATION_RATE_WINDOW_MS || String(10 * 60 * 1000), 10);
  const key = String(req.user?._id || req.user?.id || req.ip);
  const now = Date.now();
  const list = (hits.get(key) || []).filter(t => now - t < windowMs);
  if (list.length >= max) {
    const retryAfter = Math.ceil((windowMs - (now - list[0])) / 1000);
    res.set('Retry-After', String(retryAfter));
    return res.status(429).json({ success: false, message: `Too many generation requests. Try again in ${retryAfter}s.` });
  }
  list.push(now);
  hits.set(key, list);
  if (hits.size > 5000) {
    for (const [k, v] of hits) if (!v.length || now - v[v.length - 1] > windowMs) hits.delete(k);
  }
  next();
}

module.exports = { generationLimiter };
