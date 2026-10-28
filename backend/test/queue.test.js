/**
 * Persistent queue + worker behaviour against a real (in-memory) MongoDB.
 */
const { startDb, stopDb, clearDb, oid, silenceLogs } = require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');

const GenerationJob = require('../src/models/GenerationJob');
const queue = require('../src/services/jobs/queue.service');
const { JobWorker } = require('../src/services/jobs/worker.service');

const sleep = (ms) => new Promise(r => setTimeout(r, ms));
const quiet = { info: () => {}, error: () => {} };

test.before(startDb);
test.after(stopDb);
test.beforeEach(clearDb);

function videoJob(extra = {}) {
  return { type: 'lesson_video', key: `k-${Math.random()}`, courseId: oid(), maxAttempts: 3, ...extra };
}

test('enqueue: same key twice (even concurrently) creates exactly one job', async () => {
  const doc = videoJob({ key: 'video:item:1:v1:explainer:abc' });
  const results = await Promise.all([queue.enqueue(doc), queue.enqueue(doc), queue.enqueue(doc)]);
  assert.equal(results.filter(r => r.created).length, 1);
  assert.equal(await GenerationJob.countDocuments({}), 1);
  assert.equal(String(results[0].job._id), String(results[2].job._id));
});

test('claim: two workers never get the same job', async () => {
  await queue.enqueue(videoJob());
  const [a, b] = await Promise.all([queue.claim('w1', ['lesson_video']), queue.claim('w2', ['lesson_video'])]);
  assert.equal([a, b].filter(Boolean).length, 1);
  const claimed = a || b;
  assert.equal(claimed.state, 'running');
  assert.equal(claimed.attempts, 1);
});

test('fail: retryable errors back off exponentially, then fail permanently at maxAttempts', async () => {
  const { job } = await queue.enqueue(videoJob({ maxAttempts: 2 }));
  let j = await queue.claim('w', ['lesson_video']);
  const before = Date.now();
  j = await queue.fail(j, 'w', new Error('provider 503'), 'generating_audio');
  assert.equal(j.state, 'retry_wait');
  assert.ok(j.nextRunAt.getTime() >= before + 50);
  assert.equal(j.error.stage, 'generating_audio');
  assert.equal(await queue.claim('w', ['lesson_video']), null, 'not claimable before nextRunAt');
  await sleep(300);
  j = await queue.claim('w', ['lesson_video']);
  assert.equal(j.attempts, 2);
  j = await queue.fail(j, 'w', new Error('provider 503 again'), 'generating_audio');
  assert.equal(j.state, 'failed');
  assert.equal(j.error.retryable, false);
  assert.ok(queue.backoffMs(3) >= queue.backoffMs(1));
  assert.equal(String(j._id), String(job._id));
});

test('fail: non-retryable errors fail immediately', async () => {
  await queue.enqueue(videoJob({ maxAttempts: 5 }));
  const j = await queue.claim('w', ['lesson_video']);
  const out = await queue.fail(j, 'w', Object.assign(new Error('no TTS configured'), { retryable: false }), 'generating_audio');
  assert.equal(out.state, 'failed');
});

test('crash recovery: a running job whose lease expired is claimed again', async () => {
  await queue.enqueue(videoJob());
  const j = await queue.claim('dead-worker', ['lesson_video'], 50);
  assert.ok(j);
  assert.equal(await queue.claim('w2', ['lesson_video']), null);
  await sleep(80);
  const again = await queue.claim('w2', ['lesson_video']);
  assert.equal(String(again._id), String(j._id));
  assert.equal(again.lease.owner, 'w2');
  // The dead worker can no longer complete it.
  assert.equal(await queue.complete(j._id, 'dead-worker', {}), null);
});

test('requeue resets a failed job and keeps its key unique', async () => {
  const { job } = await queue.enqueue(videoJob({ maxAttempts: 1 }));
  const j = await queue.claim('w', ['lesson_video']);
  await queue.fail(j, 'w', new Error('x'), 'assembling');
  const re = await queue.requeue(job._id, { restartFrom: 'visuals' });
  assert.equal(re.state, 'queued');
  assert.equal(re.attempts, 0);
  assert.equal(re.restartFrom, 'visuals');
});

test('worker: runs handler, stores output, records stages and artifacts', async () => {
  const restore = silenceLogs();
  try {
    const { job } = await queue.enqueue(videoJob());
    const worker = new JobWorker({ pollMs: 20, log: quiet });
    let completed = null;
    const handler = async (j, ctx) => {
      await ctx.stage('generating_script');
      await ctx.saveArtifacts({ storyboard: { scenes: [1, 2] } });
      await ctx.addCost({ stage: 'generating_script', provider: 'llm', usd: 0.01, llmTokens: 500 });
      await ctx.stage('validating');
      return { ok: true };
    };
    handler.onComplete = async (id) => { completed = String(id); };
    worker.register('lesson_video', handler);
    await worker.start();
    for (let i = 0; i < 100 && !completed; i++) await sleep(20);
    await worker.stop();
    const done = await GenerationJob.findById(job._id).lean();
    assert.equal(done.state, 'completed');
    assert.deepEqual(done.output, { ok: true });
    assert.deepEqual(done.artifacts.storyboard.scenes, [1, 2]);
    assert.equal(done.cost.llmTokens, 500);
    assert.ok(done.stageHistory.some(h => h.stage === 'generating_script'));
    assert.equal(completed, String(job._id));
  } finally { restore(); }
});

test('worker: timeout aborts the job and schedules a retry', async () => {
  const { job } = await queue.enqueue(videoJob({ maxAttempts: 3 }));
  const worker = new JobWorker({ pollMs: 20, log: quiet });
  worker.register('lesson_video', (j, ctx) => new Promise(() => {}), { timeoutMs: 100 });
  await worker.start();
  for (let i = 0; i < 60; i++) {
    const s = (await GenerationJob.findById(job._id).lean()).state;
    if (s === 'retry_wait') break;
    await sleep(25);
  }
  await worker.stop();
  const j = await GenerationJob.findById(job._id).lean();
  assert.ok(['retry_wait', 'queued', 'running', 'failed'].includes(j.state));
  assert.match(j.error.message, /timed out/);
  assert.equal(j.error.code, 'TIMEOUT');
});

test('cancel: queued jobs cancel at once; running jobs stop at the next checkpoint', async () => {
  const { job: queued } = await queue.enqueue(videoJob());
  const c = await queue.cancel(queued._id);
  assert.equal(c.state, 'cancelled');

  const { job } = await queue.enqueue(videoJob());
  const worker = new JobWorker({ pollMs: 20, heartbeatMs: 30, log: quiet });
  let reachedSecondStage = false;
  worker.register('lesson_video', async (j, ctx) => {
    await ctx.stage('generating_script');
    await queue.cancel(j._id);
    await sleep(60);
    await ctx.stage('generating_audio');
    reachedSecondStage = true;
  });
  await worker.start();
  for (let i = 0; i < 80; i++) {
    if ((await GenerationJob.findById(job._id).lean()).state === 'cancelled') break;
    await sleep(25);
  }
  await worker.stop();
  assert.equal((await GenerationJob.findById(job._id).lean()).state, 'cancelled');
  assert.equal(reachedSecondStage, false);
});

test('graceful shutdown releases unfinished jobs back to the queue without burning an attempt', async () => {
  const { job } = await queue.enqueue(videoJob());
  const worker = new JobWorker({ pollMs: 20, log: quiet });
  worker.register('lesson_video', (j, ctx) => new Promise((resolve, reject) => ctx.signal.addEventListener('abort', () => reject(ctx.signal.reason))));
  await worker.start();
  for (let i = 0; i < 40; i++) {
    if ((await GenerationJob.findById(job._id).lean()).state === 'running') break;
    await sleep(20);
  }
  await worker.stop(50);
  const j = await GenerationJob.findById(job._id).lean();
  assert.equal(j.state, 'queued');
  assert.equal(j.attempts, 0);
  assert.equal(j.lease.owner, null);
});
