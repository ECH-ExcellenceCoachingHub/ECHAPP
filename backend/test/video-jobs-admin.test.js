/**
 * Finding and stopping stuck lesson videos: the build's job list flags stuck
 * jobs, a forced stop frees the worker even when the job ignores
 * cancellation, and failed videos can be retried in bulk.
 */
const { startDb, stopDb, oid, silenceLogs } = require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');

const CourseBuildJob = require('../src/models/CourseBuildJob');
const CourseBuildItem = require('../src/models/CourseBuildItem');
const GenerationJob = require('../src/models/GenerationJob');
const queue = require('../src/services/jobs/queue.service');
const videoJobs = require('../src/services/video/video-jobs.service');
const { JobWorker } = require('../src/services/jobs/worker.service');
const controller = require('../src/controllers/lessonVideo.controller');

const sleep = (ms) => new Promise(r => setTimeout(r, ms));
let restoreLogs;
const buildJobId = oid();
const courseId = oid();

async function waitFor(fn, ms = 10000) {
  const end = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > end) throw new Error('timed out waiting');
    await sleep(100);
  }
}

async function videoJob(title, key) {
  const item = await CourseBuildItem.create({ jobId: buildJobId, courseId, kind: 'lesson', chapterIndex: 0, title, status: 'draft', contentVersion: 1 });
  const { job } = await queue.enqueue({ type: 'lesson_video', key, courseId, buildJobId, buildItemId: item._id, variant: 'explainer', contentVersion: 1 });
  return job;
}

test.before(async () => {
  restoreLogs = silenceLogs();
  await startDb();
  await CourseBuildJob.create({ _id: buildJobId, courseId, createdBy: oid(), status: 'ready' });
});

test.after(async () => {
  await stopDb();
  restoreLogs();
});

test('a hung video is flagged as stuck, force-stopped, and the next video runs', async () => {
  const hung = await videoJob('Photosynthesis', 'video:test:hung');
  const next = await videoJob('Respiration', 'video:test:next');
  const ran = [];
  // The first job hangs and ignores its abort signal (like a frozen render).
  const worker = new JobWorker({ pollMs: 50, concurrency: 1, leaseMs: 900, heartbeatMs: 150, log: {} });
  worker.register('lesson_video', async (job, ctx) => {
    ran.push(String(job._id));
    await ctx.stage('generating_visuals', 'Rendering');
    if (String(job._id) === String(hung._id)) return new Promise(() => {});
    return { ok: true };
  });
  await worker.start();
  try {
    await waitFor(async () => (await GenerationJob.findById(hung._id).lean()).stage === 'generating_visuals');

    let list = await videoJobs.jobsForBuild(buildJobId);
    assert.equal(list.active.length, 2);
    assert.equal(list.active[0].title, 'Photosynthesis', 'the running job comes first');
    assert.equal(list.active[0].state, 'running');
    assert.ok(list.active[0].worker, 'shows which worker holds it');
    assert.equal(list.active[0].stuck, null, 'just started: not stuck');
    assert.equal(list.workerActive, true);

    // Pretend the stage started 40 minutes ago.
    await GenerationJob.updateOne({ _id: hung._id }, { $set: { 'stageHistory.$[].at': new Date(Date.now() - 40 * 60000) } });
    list = await videoJobs.jobsForBuild(buildJobId);
    assert.match(list.active[0].stuck, /No progress for 40 min \(stage: generating_visuals\)/);

    // A normal cancel is ignored by the hung job; the forced stop frees the worker.
    const res = mockRes();
    await controller.bulkVideoJobs({ params: { jobId: String(buildJobId) }, body: { action: 'force_stop', stuckOnly: true }, user: { role: 'admin', _id: oid() } }, res);
    assert.equal(res.body?.data?.count, 1, JSON.stringify(res.body));
    assert.equal((await GenerationJob.findById(hung._id).lean()).state, 'cancelled');

    const done = await waitFor(async () => {
      const j = await GenerationJob.findById(next._id).lean();
      return j.state === 'completed' && j;
    });
    assert.ok(done, 'the queue moved on to the next video');
    assert.deepEqual(ran, [String(hung._id), String(next._id)]);
    assert.equal((await GenerationJob.findById(hung._id).lean()).state, 'cancelled', 'the hung job stays cancelled');
    assert.equal((await videoJobs.jobsForBuild(buildJobId)).active.length, 0);
  } finally {
    await worker.stop(500);
  }
});

test('a job whose worker died is flagged; failed jobs are listed and retried in bulk', async () => {
  const orphan = await videoJob('Genetics', 'video:test:orphan');
  await GenerationJob.updateOne({ _id: orphan._id }, { $set: { state: 'running', stage: 'assembling', 'lease.owner': 'dead-worker', 'lease.expiresAt': new Date(Date.now() - 60000), startedAt: new Date() } });
  const failed = await videoJob('Ecology', 'video:test:failed');
  await GenerationJob.updateOne({ _id: failed._id }, { $set: { state: 'failed', error: { message: 'TTS quota exceeded', stage: 'generating_audio' }, finishedAt: new Date() } });

  const list = await videoJobs.jobsForBuild(buildJobId);
  const o = list.active.find(j => j.title === 'Genetics');
  assert.match(o.stuck, /worker stopped responding/);
  const f = list.failed.find(j => j.title === 'Ecology');
  assert.equal(f.error.message, 'TTS quota exceeded');
  assert.equal(f.error.stage, 'generating_audio');

  const res = mockRes();
  await controller.bulkVideoJobs({ params: { jobId: String(buildJobId) }, body: { action: 'retry', ids: [String(failed._id)] }, user: { role: 'admin', _id: oid() } }, res);
  assert.equal(res.body.data.count, 1);
  const retried = await GenerationJob.findById(failed._id).lean();
  assert.equal(retried.state, 'queued');
  assert.equal(retried.error, null);

  const bad = mockRes();
  await controller.bulkVideoJobs({ params: { jobId: String(buildJobId) }, body: { action: 'delete' }, user: { role: 'admin', _id: oid() } }, bad);
  assert.equal(bad.statusCode, 400);
});

function mockRes() {
  return {
    statusCode: 200,
    body: null,
    status(c) { this.statusCode = c; return this; },
    json(b) { this.body = b; return this; },
  };
}

test('with MEDIA_WORKER_CONCURRENCY=2 two videos are made at the same time, never the same one twice', async () => {
  const jobs = [];
  for (const t of ['Cells', 'Tissues', 'Organs']) jobs.push(await videoJob(t, `video:test:par:${t}`));
  let running = 0;
  let peak = 0;
  const ran = [];
  const worker = new JobWorker({ pollMs: 30, concurrency: 2, leaseMs: 3000, log: {} });
  worker.register('lesson_video', async (job) => {
    ran.push(String(job._id));
    running++;
    peak = Math.max(peak, running);
    await sleep(400);
    running--;
    return { ok: true };
  });
  await worker.start();
  try {
    await waitFor(async () => (await GenerationJob.countDocuments({ _id: { $in: jobs.map(j => j._id) }, state: 'completed' })) === 3);
    assert.equal(peak, 2, 'two videos in parallel');
    const mine = ran.filter(id => jobs.some(j => String(j._id) === id)); // earlier tests leave jobs in the queue too
    assert.deepEqual(mine.length, 3, 'each video made exactly once');
    assert.equal(new Set(mine).size, 3);
  } finally {
    await worker.stop(500);
  }
});

test('videos made in parallel reserve their cost, so together they cannot overshoot the course budget', async () => {
  const cost = require('../src/services/video/cost.service');
  const course = oid();
  const mk = async (key, extra = {}) => (await GenerationJob.create({ type: 'lesson_video', key, courseId: course, state: 'running', ...extra })).toObject();
  await mk('video:budget:done', { state: 'completed', cost: { actualUsd: 23.5 } });
  const a = await mk('video:budget:a');
  const b = await mk('video:budget:b');
  const buildJob = { options: { videoBudgetUsd: 25 } };

  // A reserves $1 (23.5 + 1 ≤ 25) …
  await cost.assertWithinBudget({ job: a, buildJob, estimateUsd: 1 });
  assert.equal((await GenerationJob.findById(a._id).lean()).cost.estimatedUsd, 1);
  assert.equal(await cost.reservedByOthers(course, b._id), 1);
  // … so B's $1 no longer fits (23.5 + 1 reserved + 1 > 25), and its reservation is released.
  await assert.rejects(() => cost.assertWithinBudget({ job: b, buildJob, estimateUsd: 1 }), /including \$1\.00 reserved by videos being made right now/);
  assert.equal((await GenerationJob.findById(b._id).lean()).cost.estimatedUsd, 0);

  // Once A has spent its money it no longer holds a reservation on top.
  await GenerationJob.updateOne({ _id: a._id }, { $set: { state: 'completed', 'cost.actualUsd': 0.9 } });
  assert.equal(await cost.reservedByOthers(course, b._id), 0);
  await cost.assertWithinBudget({ job: b, buildJob, estimateUsd: 0.5 });
});
