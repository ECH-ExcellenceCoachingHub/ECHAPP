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
const LOW_RES = path.join(FIX, 'rekka-360p.mp4');
const realFetch = global.fetch;
const original = { completeJson: ai.completeJson };
let restoreLogs;
let calls = [];
let finalStatus = 'done';
let served = VIDEO;

const sleep = (ms) => new Promise(r => setTimeout(r, ms));
const json = (body, status = 200) => new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

test.before(async () => {
  restoreLogs = silenceLogs();
  fs.mkdirSync(FIX, { recursive: true });
  for (const [size, file] of [['1620x1080', VIDEO], ['540x360', LOW_RES]]) {
    execFileSync(FFMPEG, ['-y', '-v', 'error', '-f', 'lavfi', '-i', `testsrc2=size=${size}:rate=25`, '-f', 'lavfi', '-i', 'sine=frequency=440',
      '-t', '12', '-c:v', 'libx264', '-preset', 'ultrafast', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-shortest', file]);
  }
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
      const buf = fs.readFileSync(served);
      return new Response(buf, { status: 200, headers: { 'content-type': 'video/mp4', 'content-length': String(buf.length) } });
    }
    return json({ error: 'not_found' }, 404);
  };
  Object.assign(process.env, { REKKA_API_KEY: 'rk_live_test', REKKA_API_URL: API, REKKA_POLL_MS: '2000', REKKA_MIN_SECONDS: '10' });
  await startDb();
});

test.after(async () => {
  global.fetch = realFetch;
  Object.assign(ai, original);
  for (const k of ['REKKA_API_KEY', 'REKKA_API_URL', 'REKKA_POLL_MS', 'REKKA_MIN_SECONDS']) delete process.env[k];
  await stopDb();
  restoreLogs();
});

test('request: a teacher-style, step-by-step lesson within Rekka limits', () => {
  const content = {
    summary: 'Acids donate protons.',
    notes: '## What is an acid\nAn acid donates a proton (H+) in water. More text.\n## The pH scale\nThe pH scale runs from 0 to 14. Below 7 is acidic.\n## Neutralisation\nAn acid and a base react to make a salt and water.\n' + 'filler '.repeat(500),
    formulas: [{ name: 'pH', expression: 'pH = -log[H+]' }],
    examples: [{ title: 'pH of 0.01 M HCl', body: '[H+] = 0.01, so pH = -log(0.01) = 2' }],
    keyTerms: [{ term: 'acid' }, { term: 'base' }],
    commonMistakes: ['Thinking pH 7 is always neutral at every temperature'],
  };
  const body = rekka.buildRequest({ title: 'Ti', content, subject: 'chemistry', level: 'S4', durationSec: [120, 210] });
  assert.ok(body.topic.length >= 3 && body.topic.length <= 300);
  assert.ok(body.prompt.length <= 2000);
  assert.equal(body.style, 'chalkboard', 'sciences are taught at the board');
  assert.equal(body.format, 'landscape');
  assert.equal(body.chapters, 5, 'one chapter per step + intro and recap');
  assert.equal(body.length, undefined);
  assert.match(body.prompt, /step by step/);
  assert.match(body.prompt, /1\. What is an acid — An acid donates a proton \(H\+\) in water\./);
  assert.match(body.prompt, /3\. Neutralisation/);
  assert.match(body.prompt, /pH = -log\[H\+\]/);
  assert.match(body.prompt, /pH = -log\(0\.01\) = 2/, 'worked example keeps the exact numbers');
  assert.match(body.prompt, /recap of every step\.$/);
  assert.equal(rekka.styleFor('history'), 'whiteboard');

  // No steps to structure: falls back to a length from the subject's duration range.
  const plain = rekka.buildRequest({ title: 'Long title', content: { summary: 'x'.repeat(3000) }, subject: 'history', durationSec: [100, 180] });
  assert.equal(plain.length, 'standard');
  assert.ok(plain.prompt.length <= 2000);
  assert.equal(rekka.lengthFor(90), 'short');
  assert.equal(rekka.lengthFor([300, 600]), 'in_depth');
  assert.equal(rekka.estimateCredits([120, 210]), 4);
  assert.equal(rekka.estimateCredits(250), 4);
  assert.equal(rekka.estimateCredits([180, 330], 7), 8, 'about one credit per chapter');
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

test('quality gate: a low-resolution Rekka video is rejected and the in-house pipeline is used', async () => {
  calls = [];
  finalStatus = 'done';
  served = LOW_RES;
  ai.completeJson = async () => ({
    title: 'Acids',
    scenes: [
      { type: 'title', heading: 'Acids and bases', subtitle: 'Protons', narration: 'Acids donate protons.' },
      { type: 'summary', heading: 'Key takeaways', bullets: ['pH below 7 is acidic'], narration: 'Below seven is acidic.' },
    ],
  });
  try {
    const done = await runVideo();
    assert.notEqual(done.output.provider, 'rekka');
    assert.equal(done.artifacts.rekka.failed, true);
    assert.match(done.artifacts.rekka.reason, /resolution: 540x360/);
  } finally {
    served = VIDEO;
  }
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
