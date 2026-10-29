const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');

/**
 * Small HTTP helpers for the stock-media providers (Node 22 global fetch).
 * Every request has a timeout, honours the job's abort signal and sends an
 * identifying User-Agent (required by the Wikimedia API etiquette).
 */

function userAgent() {
  return process.env.VIDEO_STOCK_USER_AGENT || 'ECH-CourseBuilder/1.0 (educational lesson videos)';
}

function withTimeout(signal, ms) {
  const t = AbortSignal.timeout(ms);
  return signal ? AbortSignal.any([signal, t]) : t;
}

// Polite pacing: requests to one host are spaced by VIDEO_STOCK_MIN_INTERVAL_MS
// (default 1 s), and 429/503 answers are retried after Retry-After.
const nextSlot = new Map();
const sleep = (ms, signal) => new Promise((resolve, reject) => {
  const t = setTimeout(resolve, ms);
  signal?.addEventListener('abort', () => { clearTimeout(t); reject(signal.reason || new Error('aborted')); }, { once: true });
});

async function pace(host, signal) {
  const gap = Math.max(0, parseInt(process.env.VIDEO_STOCK_MIN_INTERVAL_MS || '1000', 10) || 0);
  const now = Date.now();
  const at = Math.max(now, nextSlot.get(host) || 0);
  nextSlot.set(host, at + gap);
  if (at > now) await sleep(at - now, signal);
}

async function fetchJson(url, { headers = {}, signal, timeoutMs = 20000, retries = 2 } = {}) {
  const host = new URL(url).host;
  for (let attempt = 0; ; attempt++) {
    await pace(host, signal);
    const res = await fetch(url, { headers: { 'User-Agent': userAgent(), Accept: 'application/json', ...headers }, signal: withTimeout(signal, timeoutMs) });
    if (res.ok) return res.json();
    if ((res.status === 429 || res.status === 503) && attempt < retries) {
      const retryAfter = parseInt(res.headers.get('retry-after') || '', 10);
      await sleep(Math.min(10000, Number.isFinite(retryAfter) ? retryAfter * 1000 : 2000 * (attempt + 1)), signal);
      continue;
    }
    const err = new Error(`HTTP ${res.status} from ${host}`);
    err.status = res.status;
    throw err;
  }
}

/**
 * Stream a file to disk, refusing anything larger than maxBytes or with an
 * unexpected content type. Returns { file, bytes, contentType }.
 */
async function downloadToFile(url, file, { maxBytes, accept = /^(image|video|application\/ogg)/, signal, timeoutMs = 60000, headers = {} } = {}) {
  const res = await fetch(url, { headers: { 'User-Agent': userAgent(), ...headers }, signal: withTimeout(signal, timeoutMs), redirect: 'follow' });
  if (!res.ok) throw Object.assign(new Error(`HTTP ${res.status} downloading ${new URL(url).host}`), { status: res.status });
  const contentType = (res.headers.get('content-type') || '').toLowerCase();
  if (!accept.test(contentType)) throw new Error(`Unexpected content type "${contentType}" from ${new URL(url).host}`);
  const declared = parseInt(res.headers.get('content-length') || '0', 10);
  if (maxBytes && declared > maxBytes) throw new Error(`File too large (${declared} bytes > ${maxBytes})`);

  await fsp.mkdir(path.dirname(file), { recursive: true });
  const out = fs.createWriteStream(file);
  let bytes = 0;
  try {
    for await (const chunk of res.body) {
      bytes += chunk.length;
      if (maxBytes && bytes > maxBytes) throw new Error(`File too large (> ${maxBytes} bytes)`);
      if (!out.write(chunk)) await new Promise(r => out.once('drain', r));
    }
    await new Promise((resolve, reject) => out.end(err => (err ? reject(err) : resolve())));
  } catch (e) {
    // Close the handle before deleting (Windows cannot delete an open file).
    await new Promise(r => { out.once('close', r); out.destroy(); });
    await fsp.rm(file, { force: true });
    throw e;
  }
  return { file, bytes, contentType };
}

module.exports = { fetchJson, downloadToFile, userAgent };
