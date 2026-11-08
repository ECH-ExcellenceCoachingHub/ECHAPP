/**
 * Process-local limit on CPU/RAM-heavy work (Puppeteer frames, FFmpeg,
 * PyMuPDF). The worker can run many jobs at once because most lesson videos
 * are made by Rekka AI and only wait on its API; this keeps the jobs that do
 * need our own compute to MEDIA_HEAVY_CONCURRENCY at a time (default 1).
 *
 * A job that cannot get a slot is put back in the queue (DeferJobError)
 * instead of holding a worker slot and burning its timeout while it waits.
 */

class DeferJobError extends Error {
  constructor(message = 'Waiting for a free render slot', delayMs = DEFAULT_DEFER_MS()) {
    super(message);
    this.code = 'DEFERRED';
    this.delayMs = delayMs;
  }
}

function DEFAULT_DEFER_MS() {
  return Math.max(5000, parseInt(process.env.MEDIA_HEAVY_DEFER_MS || '60000', 10) || 60000);
}

function limit() {
  return Math.max(1, parseInt(process.env.MEDIA_HEAVY_CONCURRENCY || '1', 10) || 1);
}

let inUse = 0;

/** Take a slot now, or null if all are busy. Call the returned function once to give it back. */
function tryAcquire() {
  if (inUse >= limit()) return null;
  inUse++;
  let done = false;
  return () => {
    if (done) return;
    done = true;
    inUse--;
  };
}

/** Run fn in a heavy slot, or throw DeferJobError if none is free. */
async function runHeavy(fn, what = 'heavy work') {
  const release = tryAcquire();
  if (!release) throw new DeferJobError(`All ${limit()} render slot(s) are busy — ${what} will start when one is free`);
  try {
    return await fn();
  } finally {
    release();
  }
}

/** Wrap a worker handler so the whole job runs in a heavy slot. Hooks are kept. */
function heavyHandler(handler, what) {
  const wrapped = (job, ctx) => runHeavy(() => handler(job, ctx), what);
  for (const k of ['onComplete', 'onFinalFailure', 'onRetryScheduled']) if (handler[k]) wrapped[k] = handler[k];
  return wrapped;
}

function _reset() { inUse = 0; }
function stats() { return { inUse, limit: limit() }; }

module.exports = { DeferJobError, tryAcquire, runHeavy, heavyHandler, stats, _reset };
