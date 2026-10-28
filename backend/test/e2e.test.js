/**
 * End-to-end: textbook PDF → figure extraction (PyMuPDF) → lesson generation
 * with textbook figures → automatic video jobs → real rendering (Puppeteer +
 * KaTeX + FFmpeg) → validation → storage → publish → student playback.
 *
 * External AI is stubbed (deterministic LLM answers, silent narration);
 * everything else is the production code path. Requires Python with PyMuPDF
 * (backend/python/.venv), ffmpeg/ffprobe and Puppeteer's Chromium.
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
const Lesson = require('../src/models/Lesson');
const GenerationJob = require('../src/models/GenerationJob');
const FigureAsset = require('../src/models/FigureAsset');
const storage = require('../src/services/video/storage.service');
const figures = require('../src/services/course-builder/figures.service');
const ai = require('../src/services/course-builder/ai.service');
const runner = require('../src/services/course-builder/runner.service');
const { publishApproved } = require('../src/services/course-builder/publisher.service');
const videoJobs = require('../src/services/video/video-jobs.service');
const { runLessonVideo } = require('../src/services/video/pipeline.service');
const { JobWorker } = require('../src/services/jobs/worker.service');
const { probe } = require('../src/services/video/render/assembler');
const { validateVideo } = require('../src/services/video/validator');

const sleep = (ms) => new Promise(r => setTimeout(r, ms));
let restoreLogs;
let worker;
let llmCalls = 0;
const original = { completeJson: ai.completeJson, lesson: ai.generateLessonContent, questions: ai.generateQuestions };

async function waitFor(fn, label, timeoutMs = 240000) {
  const end = Date.now() + timeoutMs;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > end) throw new Error(`Timed out waiting for ${label}`);
    await sleep(250);
  }
}

const LESSON = {
  summary: 'A titration measures how much alkali neutralises an acid.',
  learningObjectives: ['Describe how to carry out an acid–alkali titration', 'Calculate moles from concentration and volume'],
  notes: '## Apparatus\nA burette delivers sodium hydroxide into 25 cm3 of hydrochloric acid in a conical flask.\n\n## Procedure\nIn this experiment add indicator, then titrate until the indicator turns pink. Observe the end point and record the volume.\n\n## Calculation\nMoles of acid: n = c × V = 0.1 × 0.025 = 0.0025 mol.\n'.repeat(2),
  keyPoints: ['Rinse the burette with the alkali', 'Swirl the conical flask', 'Stop at the first permanent colour change'],
  keyTerms: [{ term: 'burette', definition: 'a graduated tube with a tap', page: 1 }, { term: 'end point', definition: 'the point where the indicator changes colour', page: 1 }],
  examples: [{ title: 'Moles of acid', body: 'n = c × V = 0.1 × 0.025 = 0.0025 mol', page: 1 }],
  formulas: [{ name: 'Moles', expression: 'n = c × V', variables: [{ symbol: 'c', meaning: 'concentration (mol/dm3)' }, { symbol: 'V', meaning: 'volume (dm3)' }], explanation: '', page: 1 }],
  flashcards: [], activities: [{ type: 'order', title: 'Order the steps', items: ['Fill burette', 'Add indicator', 'Titrate'] }],
  visuals: [], imageRequests: [], examTips: [], commonMistakes: [], sources: [{ page: 1, section: '4.3' }], estimatedMinutes: 15,
};

/** Deterministic stand-in for the planning model; uses the figure ids it is offered. */
function storyboardStub(prompt) {
  llmCalls++;
  const ids = [...prompt.matchAll(/- id: ([a-f0-9]{24}) \| page \d+ \| (Fig\. 4\.3|Figure 4\.3)/g)].map(m => m[1]);
  const figId = ids[0];
  if (/EXPERIMENT DEMONSTRATION/.test(prompt)) {
    return {
      title: 'Titration demonstration',
      scenes: [
        { type: 'title', heading: 'Titration: a demonstration', narration: 'Let us walk through a titration.' },
        { type: 'experiment', phase: 'apparatus', heading: 'What you need', items: ['Burette', 'Conical flask', 'Indicator'], narration: 'You need a burette, a conical flask and an indicator.' },
        ...(figId ? [{ type: 'figure', heading: 'The set-up', figureId: figId, highlightLabels: ['burette', 'conical flask'], narration: 'The burette is clamped above the conical flask.' }] : []),
        { type: 'experiment', phase: 'procedure', heading: 'Procedure', items: ['Add indicator to the acid', 'Open the tap slowly', 'Swirl the flask'], narration: 'Add the indicator, open the tap slowly and swirl.' },
        { type: 'experiment', phase: 'observation', heading: 'What you see', items: ['The indicator turns pink', 'The end point is at 23.4 cm3'], narration: 'At the end point the indicator turns pink.' },
        { type: 'formula', heading: 'Calculation', steps: [{ latex: 'n = c \\times V', text: 'n = c × V' }, { latex: 'n = 0.1 \\times 0.025 = 0.0025\\,\\text{mol}', text: 'n = 0.0025 mol' }], narration: 'Moles equal concentration times volume.' },
        { type: 'summary', heading: 'Summary', bullets: ['Indicator shows the end point'], narration: 'The indicator shows the end point.' },
      ],
    };
  }
  return {
    title: 'Titration',
    scenes: [
      { type: 'title', heading: 'Acid–alkali titration', subtitle: 'How much alkali neutralises the acid?', narration: 'In this lesson we learn how a titration works.' },
      ...(figId ? [{ type: 'figure', heading: 'The apparatus', figureId: figId, highlightLabels: ['burette', 'conical flask'], narration: 'Here is the burette, and here is the conical flask.', sourcePages: [1] }] : []),
      { type: 'figure', heading: 'Invented', figureId: 'aaaaaaaaaaaaaaaaaaaaaaaa', narration: 'This figure does not exist.' },
      { type: 'flow', heading: 'Steps', steps: [{ label: 'Fill', detail: 'Fill the burette' }, { label: 'Indicator', detail: 'Add indicator' }, { label: 'Titrate', detail: 'Add alkali slowly' }], narration: 'Fill the burette, add indicator, then titrate.' },
      { type: 'formula', heading: 'Moles', steps: [{ latex: 'n = c \\times V', text: 'n = c × V', explanation: 'definition' }, { latex: 'n = 0.1 \\times 0.025', text: 'n = 0.1 × 0.025' }, { latex: 'n = 0.0025\\,\\text{mol}', text: 'n = 0.0025 mol' }], narration: 'Moles equal concentration times volume, which gives 0.0025 moles.' },
      { type: 'summary', heading: 'Key takeaways', bullets: ['Use a burette', 'Stop at the end point'], narration: 'Use a burette and stop at the end point.' },
    ],
  };
}

test.before(async () => {
  restoreLogs = silenceLogs();
  await startDb();
  ai.completeJson = async (prompt) => storyboardStub(prompt);
  ai.generateLessonContent = async () => JSON.parse(JSON.stringify(LESSON));
  ai.generateQuestions = async () => [];
  worker = new JobWorker({ pollMs: 100, concurrency: 2, log: { info: () => {}, error: () => {} } });
  worker.register('figure_extraction', figures.runExtraction, { timeoutMs: 120000 });
  worker.register('lesson_video', runLessonVideo, { timeoutMs: 240000 });
  await worker.start();
});

test.after(async () => {
  await worker.stop(1000);
  Object.assign(ai, { completeJson: original.completeJson, generateLessonContent: original.lesson, generateQuestions: original.questions });
  await stopDb();
  restoreLogs();
});

let ctx = {};

test('1. figure extraction runs in the worker and builds the asset library', async () => {
  const pdf = path.join(TMP, 'science.pdf');
  execFileSync(process.env.PYTHON_BIN || 'python', ['-c', `import sys; sys.path.insert(0, 'tests'); import test_figure_extractor as t; t.make_science_book(r'${pdf}')`], { cwd: path.join(__dirname, '..', 'python') });
  const stored = await storage.put('course-builder/science.pdf', pdf, 'application/pdf');
  const userId = oid();
  const course = await Course.create({ title: 'Senior 4 Chemistry', description: 'Chemistry', createdBy: userId, price: 0, duration: 10, level: 'intermediate' });
  const job = await CourseBuildJob.create({
    courseId: course._id, createdBy: userId, status: 'generating',
    source: { fileName: 'science.pdf', mimeType: 'application/pdf', s3Key: stored.key, pageUnit: 'page' },
    options: { mode: 'full', questionsPerLesson: 0 },
    outline: { bookTitle: 'Chemistry Book', subject: 'Chemistry', level: 'intermediate', chapters: [{ index: 0, title: 'Chapter 4 Acids and Bases', pageStart: 1, pageEnd: 2, lessons: [{ title: '4.3 Titration', pageStart: 1, pageEnd: 2 }] }] },
  });
  await figures.requestExtraction(job);
  const done = await waitFor(async () => {
    const j = await CourseBuildJob.findById(job._id).lean();
    if (j.figureExtraction.status === 'failed') throw new Error(`extraction failed: ${j.figureExtraction.error}`);
    return j.figureExtraction.status === 'completed' ? j : null;
  }, 'figure extraction');
  const assets = await FigureAsset.find({ bookHash: done.figureExtraction.bookHash }).lean();
  const fig43 = assets.find(a => a.captionLabel === '4.3');
  assert.ok(fig43, 'figure 4.3 extracted');
  assert.ok(await storage.exists(fig43.storageKey), 'figure image stored in object storage');
  assert.ok(fig43.labels.includes('burette'));
  assert.equal(fig43.chapterTitle, 'Chapter 4 Acids and Bases');
  assert.ok(fig43.labelBoxes.length >= 2);
  assert.equal(assets.find(a => a.captionLabel === '4.4').needsOcr, true, 'raster without text flagged for OCR');
  ctx = { course, job: done, userId, bookHash: done.figureExtraction.bookHash };
});

test('2. the same book version is never extracted twice', async () => {
  const again = await CourseBuildJob.create({
    courseId: ctx.course._id, createdBy: ctx.userId, status: 'outline_ready',
    source: { fileName: 'science-copy.pdf', mimeType: 'application/pdf', s3Key: 'course-builder/science.pdf' },
  });
  await figures.requestExtraction(again);
  const fresh = await CourseBuildJob.findById(again._id).lean();
  assert.equal(fresh.figureExtraction.status, 'completed');
  assert.equal(await GenerationJob.countDocuments({ type: 'figure_extraction' }), 1);
});

test('3. lesson generation uses textbook figures and queues videos automatically', async () => {
  const item = await CourseBuildItem.create({ jobId: ctx.job._id, courseId: ctx.course._id, kind: 'lesson', chapterIndex: 0, order: 0, title: '4.3 Titration', pageStart: 1, pageEnd: 2 });
  const pages = [{ n: 1, text: 'In this experiment we titrate hydrochloric acid with sodium hydroxide using a burette.' }, { n: 2, text: 'Colour change of the indicator.' }];
  await runner.processItem(ctx.job, await CourseBuildItem.findById(item._id), pages);
  const saved = await CourseBuildItem.findById(item._id).lean();
  const tf = saved.content.figures.find(f => f.captionLabel === '4.3');
  assert.ok(tf, 'figure selected for the lesson');
  assert.ok(tf.usage.includes('notes'));
  assert.ok(saved.content.images.some(i => i.kind === 'textbook_figure' && /page 1/.test(i.license)), 'figure shown in notes with page reference');
  const jobs = await GenerationJob.find({ type: 'lesson_video', buildItemId: item._id }).lean();
  assert.deepEqual(jobs.map(j => j.variant).sort(), ['experiment', 'explainer']);
  ctx.item = saved;
});

test('4. the worker produces, validates and stores both videos; the lesson stays usable meanwhile', async () => {
  // While processing, the draft has its content and a non-final video status.
  const during = await CourseBuildItem.findById(ctx.item._id).lean();
  assert.ok(during.content.notes);
  assert.notEqual(during.video.status, 'failed');

  const jobs = await waitFor(async () => {
    const js = await GenerationJob.find({ type: 'lesson_video', buildItemId: ctx.item._id }).lean();
    const bad = js.find(j => j.state === 'failed');
    if (bad) throw new Error(`video job failed: ${bad.error?.message}`);
    return js.every(j => j.state === 'completed') ? js : null;
  }, 'video jobs');

  for (const j of jobs) {
    assert.ok(await storage.exists(j.output.s3Key), `${j.variant} video stored`);
    assert.ok(await storage.exists(j.output.captionsKey), `${j.variant} captions stored`);
    // Every check passes except "narration": the test uses silent TTS, and the
    // validator must say so honestly (allowed here via VIDEO_ALLOW_SILENT).
    assert.ok(j.checks.filter(c => c.name !== 'narration').every(c => c.passed), `${j.variant} checks: ${JSON.stringify(j.checks)}`);
    assert.equal(j.checks.find(c => c.name === 'narration').passed, false);
    assert.equal(j.output.narrated, false);
    const info = await probe(path.join(process.env.MEDIA_LOCAL_DIR, j.output.s3Key));
    assert.equal(info.streams.find(s => s.codec_type === 'video').codec_name, 'h264');
    assert.ok(parseFloat(info.format.duration) > 8);
    assert.ok(j.stageHistory.some(h => h.stage === 'generating_visuals'));
  }
  const explainer = jobs.find(j => j.variant === 'explainer');
  assert.ok(explainer.artifacts.storyboard.scenes.some(s => s.type === 'figure' && s.highlightLabels.includes('burette')), 'real textbook figure animated');
  assert.ok(explainer.artifacts.storyboardWarnings.some(w => /unknown figure/.test(w)), 'invented figure id rejected');
  assert.equal(explainer.review.required, false);

  const experiment = jobs.find(j => j.variant === 'experiment');
  const obs = experiment.artifacts.storyboard.scenes.find(s => s.phase === 'observation');
  assert.ok(!obs.items.some(i => /23\.4/.test(i)), 'invented measurement removed');
  assert.ok(experiment.artifacts.storyboard.scenes.some(s => s.phase === 'safety'), 'safety scene present');
  assert.equal(experiment.review.required, true, 'hazardous practical needs review');

  const item = await CourseBuildItem.findById(ctx.item._id).lean();
  assert.equal(item.video.status, 'completed');
  assert.ok(item.video.captionsUrl);
  assert.match(item.video.transcript, /titration/i);
  assert.equal(item.experimentVideo.reviewStatus, 'pending');
  assert.match(item.experimentVideo.disclosure, /Simulated/);
  ctx.explainerKey = item.video.s3Key;
  ctx.explainerJobId = explainer._id;
  ctx.callsAfterFirstRun = llmCalls;
});

test('5. publishing exposes the explainer to students; the unreviewed experiment stays hidden', async () => {
  await CourseBuildItem.updateOne({ _id: ctx.item._id }, { $set: { status: 'approved' } });
  await publishApproved(ctx.job._id);
  const item = await CourseBuildItem.findById(ctx.item._id).lean();
  const lesson = await Lesson.findById(item.published.lessonId).lean();
  assert.equal(lesson.videoId, ctx.explainerKey);
  assert.equal(lesson.aiVideo.status, 'completed');
  assert.equal(lesson.aiExperimentVideo.reviewStatus, 'pending');
  assert.ok(lesson.aiContent.images.some(i => i.kind === 'textbook_figure'));

  const vc = require('../src/controllers/video.controller');
  const res = mockRes();
  await vc.getVideoStreamUrl({ params: { lessonId: String(lesson._id) }, query: { variant: 'experiment' }, user: { role: 'admin', id: String(ctx.userId) } }, res);
  assert.equal(res.statusCode, 404, 'experiment video not streamable before approval');
  ctx.lessonId = lesson._id;
});

test('6. regenerating only the visuals reuses the saved script and narration', async () => {
  const draft = await CourseBuildItem.findById(ctx.item._id).lean();
  const { requeued } = await videoJobs.enqueueVideo({ buildJob: ctx.job, item: draft, variant: 'explainer', restartFrom: 'visuals' });
  assert.equal(requeued, true);
  await waitFor(async () => (await GenerationJob.findById(ctx.explainerJobId).lean()).state === 'completed' && (await GenerationJob.findById(ctx.explainerJobId).lean()).finishedAt > draft.updatedAt, 'visual regeneration');
  assert.equal(llmCalls, ctx.callsAfterFirstRun, 'storyboard not regenerated');
  const lesson = await Lesson.findById(ctx.lessonId).lean();
  assert.equal(lesson.aiVideo.status, 'completed');
});

test('7. a failing re-render never replaces the valid video', async () => {
  const draft = await CourseBuildItem.findById(ctx.item._id).lean();
  const fig = draft.content.figures.find(f => f.captionLabel === '4.3');
  const asset = await FigureAsset.findById(fig.assetId).lean();
  await storage.remove(asset.storageKey); // asset disappears from storage
  await GenerationJob.updateOne({ _id: ctx.explainerJobId }, { $set: { maxAttempts: 2 } });
  await videoJobs.enqueueVideo({ buildJob: ctx.job, item: draft, variant: 'explainer', restartFrom: 'visuals' });
  const failed = await waitFor(async () => {
    const j = await GenerationJob.findById(ctx.explainerJobId).lean();
    return j.state === 'failed' ? j : null;
  }, 'failure after retries');
  assert.equal(failed.error.code, 'ASSET_MISSING');
  assert.equal(failed.attempts, 2, 'retried before failing');
  const lesson = await Lesson.findById(ctx.lessonId).lean();
  assert.equal(lesson.aiVideo.status, 'failed');
  assert.equal(lesson.aiVideo.s3Key, ctx.explainerKey, 'previous valid video kept');
  assert.equal(lesson.videoId, ctx.explainerKey, 'students still get the valid video');
  assert.ok(lesson.aiContent.notes, 'lesson content intact');
});

test('8. spending limits stop paid narration before any provider call', async () => {
  Object.assign(process.env, { VIDEO_TTS_PROVIDER: 'elevenlabs', ELEVENLABS_API_KEY: 'test-key-not-used', VIDEO_TTS_COST_PER_1K_CHARS: '50', VIDEO_MAX_COST_PER_LESSON_USD: '0.01' });
  try {
    const draft = await CourseBuildItem.findById(ctx.item._id).lean();
    const { job } = await videoJobs.enqueueVideo({ buildJob: ctx.job, item: draft, variant: 'explainer', force: true });
    const failed = await waitFor(async () => {
      const j = await GenerationJob.findById(job._id).lean();
      return ['failed', 'completed'].includes(j.state) && j.config.tts === 'elevenlabs' ? j : null;
    }, 'budget failure');
    assert.equal(failed.state, 'failed');
    assert.equal(failed.error.code, 'BUDGET_EXCEEDED');
    assert.equal(failed.attempts, 1, 'budget errors are not retried');
    assert.equal((failed.providerRequests || []).filter(p => p.provider === 'elevenlabs').length, 0);
  } finally {
    for (const k of ['ELEVENLABS_API_KEY', 'VIDEO_TTS_COST_PER_1K_CHARS', 'VIDEO_MAX_COST_PER_LESSON_USD']) delete process.env[k];
    process.env.VIDEO_TTS_PROVIDER = 'silent';
  }
});

test('9. invalid video files fail validation', async () => {
  const bad = path.join(TMP, 'bad.mp4');
  fs.writeFileSync(bad, Buffer.alloc(4096, 7));
  const r = await validateVideo({ file: bad, expectedSeconds: 10, sceneCount: 2, captions: { cues: [] }, narrated: true });
  assert.equal(r.ok, false);
  assert.equal(r.checks[0].name, 'readable');
  assert.equal(r.checks[0].passed, false);
});

function mockRes() {
  const res = { statusCode: 200, body: null };
  res.status = (c) => { res.statusCode = c; return res; };
  res.json = (b) => { res.body = b; return res; };
  return res;
}
