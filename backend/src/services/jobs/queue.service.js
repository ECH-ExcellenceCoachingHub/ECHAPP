const crypto = require('crypto');
const os = require('os');
const GenerationJob = require('../../models/GenerationJob');

/**
 * MongoDB-backed persistent job queue.
 *
 * Why not BullMQ/Redis: the platform has no Redis today and MongoDB Atlas is
 * already highly available. Jobs are low-volume and long-running (minutes),
 * so a lease-based Mongo queue gives persistence, retries, duplicate
 * prevention and crash recovery without new infrastructure. The interface
 * (enqueue / claim / complete / fail) is small enough to swap for BullMQ later.
 *
 * Guarantees:
 *  - `key` is unique: enqueueing the same work twice returns the existing job.
 *  - claim() is atomic (findOneAndUpdate) — two workers never run one job.
 *  - A job whose lease expired (worker crashed / redeployed) is claimable again.
 *  - Failed attempts back off exponentially with jitter, up to maxAttempts.
 */

const DEFAULT_LEASE_MS = parseInt(process.env.JOB_LEASE_MS || '120000', 10);
const BACKOFF_BASE_MS = parseInt(process.env.JOB_BACKOFF_BASE_MS || '30000', 10);
const BACKOFF_MAX_MS = parseInt(process.env.JOB_BACKOFF_MAX_MS || String(30 * 60 * 1000), 10);
const MAX_HISTORY = 60;

function workerId() {
  return `${os.hostname()}:${process.pid}:${crypto.randomBytes(3).toString('hex')}`;
}

function hashConfig(config) {
  const stable = JSON.stringify(sortKeys(config || {}));
  return crypto.createHash('sha256').update(stable).digest('hex').slice(0, 16);
}

function sortKeys(v) {
  if (Array.isArray(v)) return v.map(sortKeys);
  if (v && typeof v === 'object' && !(v instanceof Date)) {
    return Object.keys(v).sort().reduce((o, k) => { o[k] = sortKeys(v[k]); return o; }, {});
  }
  return v;
}

/**
 * Insert a job unless one with the same key exists.
 * @returns {Promise<{job: object, created: boolean}>}
 */
async function enqueue(doc) {
  if (!doc.key) throw new Error('enqueue requires a key');
  const now = new Date();
  const res = await GenerationJob.findOneAndUpdate(
    { key: doc.key },
    {
      $setOnInsert: {
        state: 'queued',
        stage: 'queued',
        attempts: 0,
        nextRunAt: now,
        artifacts: {},
        ...doc,
      },
    },
    { upsert: true, new: true, includeResultMetadata: true },
  ).catch(async (err) => {
    // Two concurrent upserts on a unique key: the loser gets E11000 — read the winner.
    if (err && err.code === 11000) {
      return { value: await GenerationJob.findOne({ key: doc.key }), lastErrorObject: { updatedExisting: true } };
    }
    throw err;
  });
  const created = !res.lastErrorObject?.updatedExisting;
  return { job: res.value, created };
}

/**
 * Put an existing (finished or failed) job back on the queue, optionally
 * restarting from a given stage. Running jobs are left alone.
 */
async function requeue(jobId, { restartFrom = null, resetAttempts = true, requestedBy = null } = {}) {
  const set = {
    state: 'queued',
    stage: 'queued',
    nextRunAt: new Date(),
    cancelRequested: false,
    error: null,
    restartFrom,
    'lease.owner': null,
    'lease.expiresAt': null,
    finishedAt: null,
  };
  if (resetAttempts) set.attempts = 0;
  if (requestedBy) set.requestedBy = requestedBy;
  return GenerationJob.findOneAndUpdate(
    { _id: jobId, state: { $in: ['completed', 'failed', 'cancelled', 'retry_wait', 'queued'] } },
    { $set: set, $push: { stageHistory: { $each: [{ stage: 'queued', status: 'requeued', at: new Date(), message: restartFrom ? `restart from ${restartFrom}` : 'retry' }], $slice: -MAX_HISTORY } } },
    { new: true },
  );
}

/** Atomically claim the next runnable job of the given types. */
async function claim(owner, types, leaseMs = DEFAULT_LEASE_MS) {
  const now = new Date();
  return GenerationJob.findOneAndUpdate(
    {
      type: { $in: types },
      cancelRequested: { $ne: true },
      $or: [
        { state: { $in: ['queued', 'retry_wait'] }, nextRunAt: { $lte: now } },
        // crash recovery: running, but the lease ran out
        { state: 'running', 'lease.expiresAt': { $lt: now } },
      ],
    },
    {
      $set: {
        state: 'running',
        'lease.owner': owner,
        'lease.expiresAt': new Date(now.getTime() + leaseMs),
        startedAt: now,
      },
      $inc: { attempts: 1 },
    },
    { sort: { priority: -1, nextRunAt: 1 }, new: true },
  );
}

/** Extend the lease while working. Returns false if the job was taken away or cancelled. */
async function heartbeat(jobId, owner, leaseMs = DEFAULT_LEASE_MS) {
  const res = await GenerationJob.findOneAndUpdate(
    { _id: jobId, 'lease.owner': owner, state: 'running' },
    { $set: { 'lease.expiresAt': new Date(Date.now() + leaseMs) } },
    { new: true, projection: { cancelRequested: 1 } },
  );
  if (!res) return { alive: false, cancelled: false };
  return { alive: true, cancelled: !!res.cancelRequested };
}

async function setStage(jobId, owner, stage, message = '') {
  await GenerationJob.updateOne(
    { _id: jobId, 'lease.owner': owner },
    {
      $set: { stage },
      $push: { stageHistory: { $each: [{ stage, status: 'started', at: new Date(), message }], $slice: -MAX_HISTORY } },
    },
  );
}

async function complete(jobId, owner, fields = {}) {
  return GenerationJob.findOneAndUpdate(
    { _id: jobId, 'lease.owner': owner },
    {
      $set: {
        ...fields,
        state: 'completed',
        stage: 'completed',
        error: null,
        finishedAt: new Date(),
        restartFrom: null,
        'lease.owner': null,
        'lease.expiresAt': null,
      },
      $push: { stageHistory: { $each: [{ stage: 'completed', status: 'done', at: new Date() }], $slice: -MAX_HISTORY } },
    },
    { new: true },
  );
}

function backoffMs(attempt) {
  const exp = Math.min(BACKOFF_MAX_MS, BACKOFF_BASE_MS * 2 ** Math.max(0, attempt - 1));
  const jitter = Math.round(exp * 0.2 * Math.random());
  return exp + jitter;
}

/**
 * Record a failure. Retryable errors go back to the queue with exponential
 * backoff until maxAttempts is reached; everything else fails permanently.
 */
async function fail(job, owner, err, stage) {
  const retryable = err?.retryable !== false && (job.attempts || 1) < (job.maxAttempts || 1);
  const at = new Date();
  const error = {
    message: String(err?.message || err).slice(0, 2000),
    stage: stage || job.stage,
    code: err?.code || null,
    retryable,
    at,
  };
  const set = {
    error,
    'lease.owner': null,
    'lease.expiresAt': null,
  };
  if (retryable) {
    set.state = 'retry_wait';
    set.nextRunAt = new Date(at.getTime() + backoffMs(job.attempts || 1));
  } else {
    set.state = 'failed';
    set.finishedAt = at;
  }
  return GenerationJob.findOneAndUpdate(
    { _id: job._id, 'lease.owner': owner },
    {
      $set: set,
      $push: { stageHistory: { $each: [{ stage: error.stage, status: retryable ? 'retry' : 'failed', at, message: error.message.slice(0, 300) }], $slice: -MAX_HISTORY } },
    },
    { new: true },
  );
}

/** Give a job back without counting the attempt (graceful shutdown). */
async function release(jobId, owner) {
  await GenerationJob.updateOne(
    { _id: jobId, 'lease.owner': owner, state: 'running' },
    { $set: { state: 'queued', nextRunAt: new Date(), 'lease.owner': null, 'lease.expiresAt': null }, $inc: { attempts: -1 } },
  );
}

/** Ask a job to stop. Queued jobs are cancelled at once; running jobs at the next checkpoint. */
async function cancel(jobId) {
  const queued = await GenerationJob.findOneAndUpdate(
    { _id: jobId, state: { $in: ['queued', 'retry_wait'] } },
    { $set: { state: 'cancelled', cancelRequested: true, finishedAt: new Date() } },
    { new: true },
  );
  if (queued) return queued;
  return GenerationJob.findOneAndUpdate({ _id: jobId, state: 'running' }, { $set: { cancelRequested: true } }, { new: true });
}

/**
 * Stop a job now, without waiting for its worker. A worker still running it
 * loses its lease at the next heartbeat, drops the job and moves on, so a
 * hung job can no longer hold up the queue.
 */
async function forceCancel(jobId) {
  return GenerationJob.findOneAndUpdate(
    { _id: jobId, state: { $in: ['queued', 'retry_wait', 'running'] } },
    {
      $set: { state: 'cancelled', cancelRequested: true, finishedAt: new Date(), 'lease.owner': null, 'lease.expiresAt': null },
      $push: { stageHistory: { $each: [{ stage: 'cancelled', status: 'forced', at: new Date(), message: 'stopped by an admin' }], $slice: -MAX_HISTORY } },
    },
    { new: true },
  );
}

async function markCancelled(jobId, owner) {
  return GenerationJob.findOneAndUpdate(
    { _id: jobId, 'lease.owner': owner },
    { $set: { state: 'cancelled', finishedAt: new Date(), 'lease.owner': null, 'lease.expiresAt': null } },
    { new: true },
  );
}

module.exports = {
  enqueue,
  requeue,
  claim,
  heartbeat,
  setStage,
  complete,
  fail,
  release,
  cancel,
  forceCancel,
  markCancelled,
  backoffMs,
  hashConfig,
  workerId,
};
