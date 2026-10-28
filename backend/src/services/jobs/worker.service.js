const GenerationJob = require('../../models/GenerationJob');
const queue = require('./queue.service');

/**
 * Generic worker loop for GenerationJob handlers.
 *
 *   const worker = new JobWorker({ concurrency: 1 });
 *   worker.register('lesson_video', handler, { timeoutMs });
 *   await worker.start();
 *
 * A handler receives (job, ctx). ctx gives it:
 *   ctx.stage(name, message)      record progress (also checks cancellation)
 *   ctx.checkpoint()              throw if the job was cancelled / timed out
 *   ctx.saveArtifacts(patch)      persist stage outputs for resumable retries
 *   ctx.addCost(item)             record provider cost / usage
 *   ctx.addProviderRequest(info)  record provider request ids
 *   ctx.signal                    AbortSignal fired on cancel / timeout / shutdown
 * The handler's return value is stored as job.output.
 */

class JobCancelledError extends Error {
  constructor(msg = 'Job cancelled') { super(msg); this.code = 'CANCELLED'; this.retryable = false; }
}
class JobTimeoutError extends Error {
  constructor(ms) { super(`Job timed out after ${Math.round(ms / 1000)}s`); this.code = 'TIMEOUT'; this.retryable = true; }
}

class JobWorker {
  constructor({ concurrency = 1, pollMs = 5000, leaseMs, heartbeatMs, log = console } = {}) {
    this.concurrency = Math.max(1, concurrency);
    this.pollMs = pollMs;
    this.leaseMs = leaseMs || parseInt(process.env.JOB_LEASE_MS || '120000', 10);
    this.heartbeatMs = heartbeatMs || Math.max(1000, Math.floor(this.leaseMs / 3));
    this.handlers = new Map();
    this.owner = queue.workerId();
    this.running = false;
    this.active = new Map(); // jobId -> {controller}
    this.loops = [];
    this.log = log;
    this._wake = null;
  }

  register(type, handler, { timeoutMs = 30 * 60 * 1000 } = {}) {
    this.handlers.set(type, { handler, timeoutMs });
    return this;
  }

  async start() {
    if (this.running) return;
    this.running = true;
    for (let i = 0; i < this.concurrency; i++) this.loops.push(this.loop(i));
    this.log.info?.(`[worker ${this.owner}] started: ${[...this.handlers.keys()].join(', ')} x${this.concurrency}`);
  }

  /** Stop claiming new work; wait for active jobs up to graceMs, then release them. */
  async stop(graceMs = 25000) {
    this.running = false;
    if (this._wake) this._wake();
    const deadline = Date.now() + graceMs;
    while (this.active.size && Date.now() < deadline) await sleep(250);
    for (const [jobId, a] of this.active) {
      a.controller.abort(new JobCancelledError('Worker shutting down'));
      a.released = true;
      await queue.release(jobId, this.owner).catch(() => {});
    }
    await Promise.allSettled(this.loops);
    this.loops = [];
  }

  async loop(index) {
    while (this.running) {
      let job = null;
      try {
        await this.sweepCancelled();
        job = await queue.claim(this.owner, [...this.handlers.keys()], this.leaseMs);
      } catch (err) {
        this.log.error?.(`[worker] claim failed: ${err.message}`);
      }
      if (!job) {
        await new Promise((resolve) => {
          const t = setTimeout(resolve, this.pollMs);
          this._wake = () => { clearTimeout(t); resolve(); };
        });
        continue;
      }
      await this.runOne(job, index);
    }
  }

  /** Running jobs that were cancelled and whose worker vanished. */
  async sweepCancelled() {
    await GenerationJob.updateMany(
      { state: 'running', cancelRequested: true, 'lease.expiresAt': { $lt: new Date() } },
      { $set: { state: 'cancelled', finishedAt: new Date(), 'lease.owner': null, 'lease.expiresAt': null } },
    );
  }

  async runOne(job, index = 0) {
    const entry = this.handlers.get(job.type);
    const controller = new AbortController();
    const record = { controller, released: false };
    this.active.set(String(job._id), record);
    const owner = this.owner;
    let currentStage = job.stage;
    const started = Date.now();

    const timeout = setTimeout(() => controller.abort(new JobTimeoutError(entry.timeoutMs)), entry.timeoutMs);
    const hb = setInterval(async () => {
      try {
        const { alive, cancelled } = await queue.heartbeat(job._id, owner, this.leaseMs);
        if (!alive) controller.abort(new JobCancelledError('Lease lost'));
        else if (cancelled) controller.abort(new JobCancelledError());
      } catch (_) { /* transient DB error: next beat retries */ }
    }, this.heartbeatMs);

    const checkpoint = () => {
      if (controller.signal.aborted) throw controller.signal.reason || new JobCancelledError();
    };
    const ctx = {
      owner,
      signal: controller.signal,
      checkpoint,
      async stage(name, message = '') {
        checkpoint();
        currentStage = name;
        await queue.setStage(job._id, owner, name, message);
        const fresh = await GenerationJob.findById(job._id).select('cancelRequested').lean();
        if (fresh?.cancelRequested) controller.abort(new JobCancelledError());
        checkpoint();
      },
      async saveArtifacts(patch) {
        const set = {};
        for (const [k, v] of Object.entries(patch)) set[`artifacts.${k}`] = v;
        await GenerationJob.updateOne({ _id: job._id, 'lease.owner': owner }, { $set: set });
        job.artifacts = { ...(job.artifacts || {}), ...patch };
      },
      async unsetArtifacts(keys) {
        const unset = {};
        for (const k of keys) unset[`artifacts.${k}`] = '';
        await GenerationJob.updateOne({ _id: job._id }, { $unset: unset });
        for (const k of keys) if (job.artifacts) delete job.artifacts[k];
      },
      async addCost({ stage, provider, units = 0, unit = '', usd = 0, requestId = null, llmTokens = 0, ttsChars = 0 }) {
        await GenerationJob.updateOne({ _id: job._id }, {
          $inc: { 'cost.actualUsd': usd || 0, 'cost.llmTokens': llmTokens || 0, 'cost.ttsChars': ttsChars || 0 },
          $push: { 'cost.items': { stage, provider, units, unit, usd, requestId, at: new Date() } },
        });
      },
      async addProviderRequest({ stage, provider, requestId }) {
        if (!requestId) return;
        await GenerationJob.updateOne({ _id: job._id }, { $push: { providerRequests: { stage, provider, requestId, at: new Date() } } });
      },
      async update(set) {
        await GenerationJob.updateOne({ _id: job._id }, { $set: set });
      },
      log: (msg) => this.log.info?.(`[worker#${index} ${job.type} ${job._id}] ${msg}`),
    };

    try {
      ctx.log(`claimed (attempt ${job.attempts}/${job.maxAttempts})`);
      const output = await Promise.race([
        entry.handler(job, ctx),
        new Promise((_, reject) => controller.signal.addEventListener('abort', () => reject(controller.signal.reason), { once: true })),
      ]);
      await queue.complete(job._id, owner, { output: output ?? null });
      ctx.log(`completed in ${Math.round((Date.now() - started) / 1000)}s`);
      await safeHook(entry.handler.onComplete, job._id);
    } catch (err) {
      if (record.released) {
        ctx.log('released for another worker (shutdown)');
      } else if (err instanceof JobCancelledError || err?.code === 'CANCELLED') {
        await queue.markCancelled(job._id, owner);
        ctx.log(`cancelled: ${err.message}`);
        await safeHook(entry.handler.onFinalFailure, job._id, err);
      } else {
        const updated = await queue.fail(job, owner, err, currentStage);
        ctx.log(`failed at ${currentStage}: ${err.message}${updated?.state === 'retry_wait' ? ` — retry at ${updated.nextRunAt.toISOString()}` : ''}`);
        if (updated?.state === 'failed') await safeHook(entry.handler.onFinalFailure, job._id, err);
        else await safeHook(entry.handler.onRetryScheduled, job._id, err);
      }
    } finally {
      clearTimeout(timeout);
      clearInterval(hb);
      this.active.delete(String(job._id));
    }
  }
}

async function safeHook(fn, ...args) {
  if (typeof fn !== 'function') return;
  try { await fn(...args); } catch (e) { console.error('[worker] hook failed:', e.message); }
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

module.exports = { JobWorker, JobCancelledError, JobTimeoutError };
