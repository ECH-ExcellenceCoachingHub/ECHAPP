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

/** IPv6 text → BigInt (handles "::" and an embedded IPv4 tail), or null. */
function ipv6ToBig(ip) {
  let s = String(ip || '').trim().toLowerCase().split('%')[0];
  if (!s.includes(':')) return null;
  const v4 = s.match(/(\d+\.\d+\.\d+\.\d+)$/);
  if (v4) {
    const n = ipv4ToInt(v4[1]);
    if (n == null) return null;
    s = s.slice(0, -v4[1].length) + `${(n >>> 16).toString(16)}:${(n & 0xffff).toString(16)}`;
  }
  const halves = s.split('::');
  if (halves.length > 2) return null;
  const left = halves[0] ? halves[0].split(':') : [];
  const right = halves.length === 2 && halves[1] ? halves[1].split(':') : [];
  const missing = 8 - left.length - right.length;
  if (halves.length === 1 ? missing !== 0 : missing < 1) return null;
  const parts = [...left, ...Array(halves.length === 2 ? missing : 0).fill('0'), ...right];
  if (parts.length !== 8 || parts.some((h) => !/^[0-9a-f]{1,4}$/.test(h))) return null;
  return parts.reduce((acc, h) => (acc << 16n) + BigInt(parseInt(h, 16)), 0n);
}

function bigToIpv6(n) {
  const parts = [];
  for (let i = 7; i >= 0; i--) parts.push(Number((n >> BigInt(i * 16)) & 0xffffn).toString(16));
  // Compress the longest run of zeros.
  let best = { at: -1, len: 0 };
  for (let i = 0; i < 8;) {
    if (parts[i] !== '0') { i++; continue; }
    let j = i;
    while (j < 8 && parts[j] === '0') j++;
    if (j - i > best.len) best = { at: i, len: j - i };
    i = j;
  }
  if (best.len < 2) return parts.join(':');
  return `${parts.slice(0, best.at).join(':')}::${parts.slice(best.at + best.len).join(':')}`;
}

/**
 * Exact match for any address; ranges for IPv4 (41.186.12.0/24) and IPv6
 * (2c0f:eb68:1:2::/64 — every device on one Wi-Fi shares the first 64 bits).
 */
function ipMatches(ip, rule) {
  const a = normalizeIp(ip);
  const r = String(rule || '').trim().toLowerCase();
  if (!a || !r) return false;
  if (!r.includes('/')) {
    const ab = ipv6ToBig(a);
    const rb = ipv6ToBig(r);
    if (ab != null && rb != null) return ab === rb;
    return a === normalizeIp(r);
  }
  const [base, bitsStr] = r.split('/');
  const bits = parseInt(bitsStr, 10);
  if (base.includes(':')) {
    const ab = ipv6ToBig(a);
    const bb = ipv6ToBig(base);
    if (ab == null || bb == null || !(bits >= 0 && bits <= 128)) return false;
    const shift = BigInt(128 - bits);
    return (ab >> shift) === (bb >> shift);
  }
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
  const [base, bits] = r.split('/');
  if (ipv6ToBig(base) == null) return false;
  return bits === undefined || (/^\d{1,3}$/.test(bits) && +bits >= 16 && +bits <= 128);
}

/** Loopback / private / link-local: what a server never sees from the public internet. */
function isPrivateIp(ip) {
  const a = normalizeIp(ip);
  const n = ipv4ToInt(a);
  if (n != null) {
    const [x, y] = a.split('.').map(Number);
    return x === 10 || x === 127 || (x === 172 && y >= 16 && y <= 31) || (x === 192 && y === 168) || (x === 169 && y === 254) || (x === 100 && y >= 64 && y <= 127);
  }
  const b = ipv6ToBig(a);
  if (b == null) return true;
  const top = Number(b >> 112n);
  return b === 1n || (top & 0xfe00) === 0xfc00 || (top & 0xffc0) === 0xfe80;
}

/**
 * The rule to save for the connection the admin is on now: the exact IPv4
 * address, or the IPv6 /64 network (each device has its own IPv6 address).
 */
function suggestedRule(ip) {
  const a = normalizeIp(ip);
  if (ipv4ToInt(a) != null) return a;
  const b = ipv6ToBig(a);
  if (b == null) return a;
  return `${bigToIpv6((b >> 64n) << 64n)}/64`;
}

module.exports = { clientIp, normalizeIp, ipMatches, ipAllowed, isValidIpRule, isPrivateIp, suggestedRule };
