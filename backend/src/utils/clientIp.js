/**
 * The caller's IP address as seen by our edge proxy.
 *
 * X-Forwarded-For is "client, proxy1, proxy2…" and every entry except the ones
 * our own proxies append can be forged by the client. We therefore count
 * TRUSTED_PROXY_HOPS entries from the right (Render adds one → default 1).
 * Without the header (local development) the socket address is used.
 */
function clientIp(req) {
  const hops = Math.max(1, parseInt(process.env.TRUSTED_PROXY_HOPS || '1', 10) || 1);
  const xff = String(req.headers?.['x-forwarded-for'] || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  const raw = xff.length ? xff[Math.max(0, xff.length - hops)] : (req.socket?.remoteAddress || req.ip || '');
  return normalizeIp(raw);
}

function normalizeIp(ip) {
  let s = String(ip || '').trim();
  if (s.startsWith('::ffff:')) s = s.slice(7); // IPv4-mapped IPv6
  if (/^\d+\.\d+\.\d+\.\d+:\d+$/.test(s)) s = s.split(':')[0]; // strip port
  return s.toLowerCase();
}

function ipv4ToInt(ip) {
  const p = ip.split('.').map(Number);
  if (p.length !== 4 || p.some((n) => !Number.isInteger(n) || n < 0 || n > 255)) return null;
  return ((p[0] << 24) >>> 0) + (p[1] << 16) + (p[2] << 8) + p[3];
}

/** Exact match for any address; IPv4 CIDR ranges like 41.186.12.0/24. */
function ipMatches(ip, rule) {
  const a = normalizeIp(ip);
  const r = String(rule || '').trim().toLowerCase();
  if (!a || !r) return false;
  if (!r.includes('/')) return a === normalizeIp(r);
  const [base, bitsStr] = r.split('/');
  const bits = parseInt(bitsStr, 10);
  const ai = ipv4ToInt(a);
  const bi = ipv4ToInt(base);
  if (ai == null || bi == null || !(bits >= 0 && bits <= 32)) return false;
  const mask = bits === 0 ? 0 : (~0 << (32 - bits)) >>> 0;
  return (ai & mask) === (bi & mask);
}

function ipAllowed(ip, rules) {
  return (rules || []).some((r) => ipMatches(ip, r));
}

function isValidIpRule(rule) {
  const r = String(rule || '').trim();
  if (/^\d+\.\d+\.\d+\.\d+(\/\d{1,2})?$/.test(r)) {
    const [base, bits] = r.split('/');
    return ipv4ToInt(base) != null && (bits === undefined || +bits <= 32);
  }
  return /^[0-9a-f:]+$/i.test(r) && r.includes(':'); // IPv6 exact
}

module.exports = { clientIp, normalizeIp, ipMatches, ipAllowed, isValidIpRule };
