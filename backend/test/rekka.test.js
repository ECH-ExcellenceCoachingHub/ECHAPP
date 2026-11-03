/**
 * Rekka AI as the primary lesson-video provider: full video from Rekka, and
 * fallback to the in-house pipeline (TTS + stock media) when Rekka fails.
 * Rekka's API is mocked; nothing leaves the machine.
 */
const { startDb, stopDb, oid, silenceLogs, TMP } = require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const Course = require('../src/models/Course');
const CourseBuildJob = require('../src/models/CourseBuildJob');
const CourseBuildItem = require('../src/models/CourseBuildItem');
const GenerationJob = require('../src/models/GenerationJob');
const ai = require('../src/services/course-builder/ai.service');
const rekka = require('../src/services/video/providers/rekka');
const pipeline = require('../src/services/video/pipeline.service');
const videoJobs = require('../src/services/video/video-jobs.service');
const { JobWorker } = require('../src/services/jobs/worker.service');

const FFMPEG = process.env.FFMPEG_BIN || 'ffmpeg';
const API = 'https://rekka.test';
const FIX = path.join(TMP, 'rekka-fixtures');
const VIDEO = path.join(FIX, 'rekka.mp4');
const realFetch = global.fetch;
const original = { completeJson: ai.completeJson };
let restoreLogs;
let calls = [];
let finalStatus = 'done';

const sleep = (ms) => new Promise(r => setTimeout(r, ms));
const json = (body, status = 200) => new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

test.before(async () => {
  restoreLogs = silenceLogs();
  fs.mkdirSync(FIX, { recursive: true });
  execFileSync(FFMPEG, ['-y', '-v', 'error', '-f', 'lavfi', '-i', 'testsrc2=size=960x640:rate=25', '-f', 'lavfi', '-i', 'sine=frequency=440',
    '-t', '12', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-shortest', VIDEO]);
  let polls = 0;
  global.fetch = async (url, opts = {}) => {
    const u = String(url);
    if (!u.startsWith(API)) return realFetch(url, opts);
    const method = opts.method || 'GET';
    calls.push(`${method} ${u.slice(API.length)}`);
    if (opts.headers?.Authorization !== 'Bearer rk_live_test') return json({ error: 'unauthorized' }, 401);
    if (u.endsWith('/v1/credits')) return json({ credits: 40 });
    if (method === 'POST' && u.endsWith('/v1/videos')) { polls = 0; return json({ id: 'vid_1', topic: 'x', status: 'pending', videoUrl: null }, 201); }
    if (u.endsWith('/v1/videos/vid_1')) {
      polls++;
      if (polls < 2) return json({ id: 'vid_1', status: 'processing', videoUrl: null });
      return json({ id: 'vid_1', status: finalStatus, videoUrl: finalStatus === 'done' ? `${API}/videos/vid_1/file` : null });
    }
    if (u.endsWith('/videos/vid_1/file')) {
      const buf = fs.readFileSync(VIDEO);
      return new Response(buf, { status: 200, headers: { 'content-type': 'video/mp4', 'content-length': String(buf.length) } });
    }
    return json({ error: 'not_found' }, 404);
  };
  Object.assign(process.env, { REKKA_API_KEY: 'rk_live_test', REKKA_API_URL: API, REKKA_POLL_MS: '2000' });
  await startDb();
});

test.after(async () => {
  global.fetch = realFetch;
  Object.assign(ai, original);
  for (const k of ['REKKA_API_KEY', 'REKKA_API_URL', 'REKKA_POLL_MS']) delete process.env[k];
  await stopDb();
  restoreLogs();
});

test('request: topic and prompt stay within Rekka limits, length follows the lesson duration', () => {
  const body = rekka.buildRequest({
    title: 'Ti',
    content: { summary: 'x'.repeat(3000), keyPoints: ['a', 'b'], formulas: [{ name: 'Moles', expression: 'n = c × V' }] },
    subject: 'chemistry', level: 'S4', durationSec: 200,
  });
  assert.ok(body.topic.length >= 3 && body.topic.length <= 300);
  assert.ok(body.prompt.length <= 2000);
  assert.equal(body.style, 'whiteboard');
  assert.equal(body.format, 'landscape');
  assert.equal(body.length, 'standard');
  assert.equal(rekka.lengthFor(90), 'short');
  assert.equal(rekka.lengthFor(600), 'in_depth');
  assert.equal(rekka.estimateCredits(250), 4);
});

test('disabled without a key, or when VIDEO_PRIMARY_PROVIDER=pipeline', () => {
  assert.equal(rekka.isEnabled(), true);
  process.env.VIDEO_PRIMARY_PROVIDER = 'pipeline';
  assert.equal(rekka.isEnabled(), false);
  delete process.env.VIDEO_PRIMARY_PROVIDER;
});

async function runVideo() {
  const userId = oid();
  const course = await Course.create({ title: 'Chemistry S4', description: 'Chemistry', createdBy: userId, price: 0, duration: 10, level: 'intermediate' });
  const job = await CourseBuildJob.create({ courseId: course._id, createdBy: userId, status: 'generating', outline: { subject: 'Chemistry', bookTitle: 'Chemistry', level: 'S4' } });
  const item = await CourseBuildItem.create({
    jobId: job._id, courseId: course._id, kind: 'lesson', chapterIndex: 0, title: 'Acids and bases', status: 'draft', contentVersion: 1,
    content: { summary: 'Acids donate protons.', notes: 'An acid donates a proton; a base accepts one.', keyPoints: ['pH below 7 is acidic'] },
  });
  const worker = new JobWorker({ pollMs: 100, concurrency: 1, log: { info: () => {}, error: () => {} } });
  worker.register('lesson_video', pipeline.runLessonVideo, { timeoutMs: 240000 });
  await worker.start();
  try {
    const { job: gj } = await videoJobs.enqueueVideo({ buildJob: job, item, variant: 'explainer' });
    for (let i = 0; i < 1200; i++) {
      const j = await GenerationJob.findById(gj._id).lean();
      if (j.state === 'failed') throw new Error(`video failed: ${j.error?.message}`);
      if (j.state === 'completed') return j;
      await sleep(200);
    }
    throw new Error('video did not complete');
  } finally {
    await worker.stop(1000);
  }
}

test('primary: Rekka makes the whole video — no script, narration or stock media of our own', async () => {
  calls = [];
  finalStatus = 'done';
  let planned = 0;
  ai.completeJson = async () => { planned++; throw new Error('the pipeline must not run'); };
  const done = await runVideo();
  assert.equal(done.output.provider, 'rekka');
  assert.equal(planned, 0);
  assert.equal(done.artifacts.storyboard, undefined);
  assert.equal(done.artifacts.rekka.id, 'vid_1');
  assert.equal(calls.filter(c => c === 'POST /v1/videos').length, 1, 'one paid video');
  assert.ok(Math.abs(done.output.durationSeconds - 12) < 0.5);
  assert.ok(fs.existsSync(path.join(process.env.MEDIA_LOCAL_DIR, done.output.s3Key)));
  assert.ok(done.cost.items.some(c => c.provider === 'rekka' && c.unit === 'credits'));
});

test('fallback: when Rekka reports an error the in-house pipeline makes the video', async () => {
  calls = [];
  finalStatus = 'error';
  ai.completeJson = async () => ({
    title: 'Acids',
    scenes: [
      { type: 'title', heading: 'Acids and bases', subtitle: 'Protons', narration: 'Acids donate protons.' },
      { type: 'summary', heading: 'Key takeaways', bullets: ['pH below 7 is acidic'], narration: 'Below seven is acidic.' },
    ],
  });
  const done = await runVideo();
  assert.notEqual(done.output.provider, 'rekka');
  assert.equal(done.artifacts.rekka.failed, true);
  assert.match(done.artifacts.rekka.reason, /could not make the video/);
  assert.ok(done.artifacts.storyboard, 'storyboard made by the fallback');
});
