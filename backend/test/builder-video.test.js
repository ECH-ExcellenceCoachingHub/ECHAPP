/**
 * Course builder ↔ video job integration (no rendering): job creation after
 * lesson persistence, duplicate prevention, stale detection, publish sync,
 * teacher-video protection, review gating and student-facing sanitising.
 */
const { startDb, stopDb, clearDb, oid, silenceLogs } = require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');

const Course = require('../src/models/Course');
const CourseBuildJob = require('../src/models/CourseBuildJob');
const CourseBuildItem = require('../src/models/CourseBuildItem');
const Lesson = require('../src/models/Lesson');
const GenerationJob = require('../src/models/GenerationJob');
const ai = require('../src/services/course-builder/ai.service');
const runner = require('../src/services/course-builder/runner.service');
const { publishApproved } = require('../src/services/course-builder/publisher.service');
const videoJobs = require('../src/services/video/video-jobs.service');
const queue = require('../src/services/jobs/queue.service');

let restoreLogs;
test.before(async () => { restoreLogs = silenceLogs(); await startDb(); });
test.after(async () => { await stopDb(); restoreLogs(); });
test.beforeEach(clearDb);

const LESSON_CONTENT = {
  summary: 'Titration finds the concentration of an acid.',
  learningObjectives: ['Describe a titration'],
  notes: '## Titration\nIn this experiment a burette delivers sodium hydroxide into hydrochloric acid in a conical flask. Procedure: add indicator, titrate until the colour changes. Observe the end point. '.repeat(3),
  keyPoints: ['Use a burette', 'Swirl the flask'],
  keyTerms: [{ term: 'burette', definition: 'graduated tube', page: 1 }],
  examples: [{ title: 'Moles', body: 'n = c × V = 0.1 × 0.025 = 0.0025 mol', page: 1 }],
  formulas: [{ name: 'Moles', expression: 'n = c × V', variables: [{ symbol: 'c', meaning: 'concentration' }, { symbol: 'V', meaning: 'volume' }] }],
  flashcards: [], activities: [{ type: 'order', title: 'Order', items: ['a', 'b', 'c'] }], visuals: [], imageRequests: [], examTips: [], commonMistakes: [],
  sources: [{ page: 1, section: '4.3' }], estimatedMinutes: 15,
};

async function seed({ subject = 'Chemistry', generateVideos = true } = {}) {
  const userId = oid();
  const course = await Course.create({ title: `Senior 4 ${subject}`, description: `${subject} course`, createdBy: userId, price: 0, duration: 10, level: 'intermediate' });
  const job = await CourseBuildJob.create({
    courseId: course._id, createdBy: userId, status: 'generating',
    source: { fileName: 'chem.pdf', mimeType: 'application/pdf', pageUnit: 'page' },
    options: { mode: 'full', questionsPerLesson: 0, generateVideos },
    outline: { bookTitle: 'Chemistry Book', subject, level: 'intermediate', chapters: [{ index: 0, title: 'Acids', pageStart: 1, pageEnd: 2, lessons: [{ title: 'Titration', pageStart: 1, pageEnd: 2 }] }] },
  });
  const item = await CourseBuildItem.create({ jobId: job._id, courseId: course._id, kind: 'lesson', chapterIndex: 0, order: 0, title: 'Titration', pageStart: 1, pageEnd: 2 });
  return { course, job, item, userId };
}

function stubAi() {
  const orig = { lesson: ai.generateLessonContent, q: ai.generateQuestions };
  ai.generateLessonContent = async () => JSON.parse(JSON.stringify(LESSON_CONTENT));
  ai.generateQuestions = async () => [];
  return () => { ai.generateLessonContent = orig.lesson; ai.generateQuestions = orig.q; };
}

const pages = [{ n: 1, text: 'Titration with a burette and conical flask. Hydrochloric acid and sodium hydroxide. ' }, { n: 2, text: 'Observe the end point.' }];

test('a video job is created automatically after the lesson draft is saved — and only once', async () => {
  const restore = stubAi();
  try {
    const { job, item } = await seed();
    assert.equal(await GenerationJob.countDocuments({}), 0);
    await runner.processItem((await CourseBuildJob.findById(job._id).lean()), await CourseBuildItem.findById(item._id), pages);

    const saved = await CourseBuildItem.findById(item._id).lean();
    assert.ok(saved.content.notes.length > 100, 'lesson content persisted first');
    assert.equal(saved.contentVersion, 1);
    assert.ok(saved.content.integrity, 'integrity report attached');
    const jobs = await GenerationJob.find({ type: 'lesson_video' }).lean();
    // chemistry lesson with a practical → explainer + experiment demonstration
    assert.deepEqual(jobs.map(j => j.variant).sort(), ['experiment', 'explainer']);
    assert.ok(jobs.every(j => j.contentVersion === 1 && String(j.buildItemId) === String(item._id)));
    assert.equal(saved.video.status, 'queued');
    assert.equal(saved.experimentVideo.status, 'queued');

    // Repeated events for the same content version create no duplicates.
    await videoJobs.onLessonContentSaved(job._id, item._id);
    await videoJobs.onLessonContentSaved(job._id, item._id);
    assert.equal(await GenerationJob.countDocuments({ type: 'lesson_video' }), 2);
  } finally { restore(); }
});

test('no video jobs when the build turned videos off', async () => {
  const restore = stubAi();
  try {
    const { job, item } = await seed({ generateVideos: false });
    await runner.processItem((await CourseBuildJob.findById(job._id).lean()), await CourseBuildItem.findById(item._id), pages);
    assert.equal(await GenerationJob.countDocuments({}), 0);
    assert.ok((await CourseBuildItem.findById(item._id).lean()).content);
  } finally { restore(); }
});

test('finished video: swapped in, copied to the lesson on publish, exposed via videoId; edits mark it stale', async () => {
  const restore = stubAi();
  try {
    const { job, item } = await seed({ subject: 'Mathematics' });
    await runner.processItem((await CourseBuildJob.findById(job._id).lean()), await CourseBuildItem.findById(item._id), pages);
    const vjob = await GenerationJob.findOne({ variant: 'explainer' });
    // Simulate the worker finishing the job.
    const claimed = await queue.claim('w', ['lesson_video']);
    assert.equal(String(claimed._id), String(vjob._id));
    await queue.complete(vjob._id, 'w', { output: { s3Key: `ai-videos/c/${item._id}/explainer-v1.mp4`, url: 'https://cdn/x.mp4', captionsKey: 'k.vtt', captionsUrl: 'https://cdn/x.vtt', durationSeconds: 150, transcript: 'hello', provider: 'programmatic+silent' } });
    await videoJobs.applyJobResult(vjob._id);
    let draft = await CourseBuildItem.findById(item._id).lean();
    assert.equal(draft.video.status, 'completed');
    assert.equal(draft.video.contentVersion, 1);
    assert.equal(draft.video.stale, false);

    // Publish → lesson gets the video and plays it through videoId.
    await CourseBuildItem.updateOne({ _id: item._id }, { $set: { status: 'approved' } });
    await publishApproved(job._id);
    draft = await CourseBuildItem.findById(item._id).lean();
    let lesson = await Lesson.findById(draft.published.lessonId).lean();
    assert.equal(lesson.aiVideo.status, 'completed');
    assert.equal(lesson.videoId, `ai-videos/c/${item._id}/explainer-v1.mp4`);
    assert.equal(lesson.contentVersion, 1);

    // Regenerating the lesson content → version 2; current video kept but stale.
    await runner.processItem((await CourseBuildJob.findById(job._id).lean()), await CourseBuildItem.findById(item._id), pages, { part: 'content' });
    draft = await CourseBuildItem.findById(item._id).lean();
    assert.equal(draft.contentVersion, 2);
    assert.equal(draft.video.stale, true);
    assert.equal(draft.video.s3Key, `ai-videos/c/${item._id}/explainer-v1.mp4`, 'valid video not overwritten');
    // Default policy (manual) → no automatic regeneration.
    assert.equal(await GenerationJob.countDocuments({ variant: 'explainer' }), 1);

    // Admin regenerates → new job for version 2; old video stays until the new one passes.
    const { job: v2, created } = await videoJobs.enqueueVideo({ buildJob: await CourseBuildJob.findById(job._id).lean(), item: draft, variant: 'explainer', force: true });
    assert.equal(created, true);
    assert.equal(v2.contentVersion, 2);
    lesson = await Lesson.findById(draft.published.lessonId).lean();
    assert.equal(lesson.videoId, `ai-videos/c/${item._id}/explainer-v1.mp4`);
  } finally { restore(); }
});

test('a teacher-uploaded video is never replaced by a generated one', async () => {
  const restore = stubAi();
  try {
    const { job, item } = await seed({ subject: 'Mathematics' });
    await runner.processItem((await CourseBuildJob.findById(job._id).lean()), await CourseBuildItem.findById(item._id), pages);
    await CourseBuildItem.updateOne({ _id: item._id }, { $set: { status: 'approved' } });
    await publishApproved(job._id);
    const draft = await CourseBuildItem.findById(item._id).lean();
    await Lesson.updateOne({ _id: draft.published.lessonId }, { $set: { videoId: 'videos/teacher-upload.mp4' } });
    const vjob = await GenerationJob.findOne({ variant: 'explainer' });
    await queue.claim('w', ['lesson_video']);
    await queue.complete(vjob._id, 'w', { output: { s3Key: 'ai-videos/c/x/explainer.mp4', url: 'u', durationSeconds: 100 } });
    await videoJobs.applyJobResult(vjob._id);
    const lesson = await Lesson.findById(draft.published.lessonId).lean();
    assert.equal(lesson.aiVideo.status, 'completed');
    assert.equal(lesson.videoId, 'videos/teacher-upload.mp4');
  } finally { restore(); }
});

test('videos that need review are hidden from students until approved', async () => {
  const restore = stubAi();
  try {
    const { job, item, userId } = await seed({ subject: 'Mathematics' });
    await runner.processItem((await CourseBuildJob.findById(job._id).lean()), await CourseBuildItem.findById(item._id), pages);
    await CourseBuildItem.updateOne({ _id: item._id }, { $set: { status: 'approved' } });
    await publishApproved(job._id);
    const lessonId = (await CourseBuildItem.findById(item._id).lean()).published.lessonId;
    const vjob = await GenerationJob.findOne({ variant: 'explainer' });
    await GenerationJob.updateOne({ _id: vjob._id }, { $set: { review: { required: true, status: 'pending', reasons: ['test'] } } });
    await queue.claim('w', ['lesson_video']);
    await queue.complete(vjob._id, 'w', { output: { s3Key: 'ai-videos/c/x/review.mp4', url: 'u', captionsUrl: 'c', transcript: 't', durationSeconds: 100 } });
    await videoJobs.applyJobResult(vjob._id);

    let lesson = await Lesson.findById(lessonId);
    assert.equal(lesson.aiVideo.reviewStatus, 'pending');
    assert.equal(lesson.videoId, null, 'not playable before approval');

    // Student-facing serialisation hides the file but keeps the status.
    const ctrl = require('../src/controllers/lesson.controller');
    const res = mockRes();
    await ctrl.getLessonById({ params: { lessonId: String(lessonId) }, user: { role: 'admin', id: String(userId) } }, res);
    assert.equal(res.body.data.aiVideo.status, 'completed');
    assert.equal(res.body.data.aiVideo.url, null);
    assert.equal(res.body.data.aiVideo.previous, undefined);

    await videoJobs.reviewVideo(vjob._id, 'approved', userId);
    lesson = await Lesson.findById(lessonId).lean();
    assert.equal(lesson.aiVideo.reviewStatus, 'approved');
    assert.equal(lesson.videoId, 'ai-videos/c/x/review.mp4');

    await videoJobs.reviewVideo(vjob._id, 'rejected', userId);
    lesson = await Lesson.findById(lessonId).lean();
    assert.equal(lesson.videoId, null, 'rejected video removed from playback');
  } finally { restore(); }
});

test('student-view preview of a draft plays its generated video (hidden while under review)', async () => {
  const restore = stubAi();
  try {
    const { job, item, userId } = await seed({ subject: 'Mathematics' });
    await runner.processItem((await CourseBuildJob.findById(job._id).lean()), await CourseBuildItem.findById(item._id), pages);
    const vjob = await GenerationJob.findOne({ variant: 'explainer' });
    await queue.claim('w', ['lesson_video']);
    await queue.complete(vjob._id, 'w', { output: { s3Key: 'ai-videos/c/x/draft.mp4', url: 'https://cdn/draft.mp4', transcript: 't', durationSeconds: 100 } });
    await videoJobs.applyJobResult(vjob._id);

    const ctrl = require('../src/controllers/courseBuilder.controller');
    const req = { params: { itemId: String(item._id) }, user: { role: 'admin', id: String(userId), _id: userId } };
    let res = mockRes();
    await ctrl.previewItem(req, res);
    assert.equal(res.statusCode, 200, JSON.stringify(res.body));
    let lesson = res.body.data.lesson;
    assert.equal(lesson.videoId, 'ai-videos/c/x/draft.mp4', 'the preview plays the generated video');
    assert.ok(lesson.videoUrl);
    assert.equal(lesson.aiVideo.status, 'completed');
    assert.equal(lesson.aiVideo.previous, undefined, 'internal fields dropped');

    // Pending review: shown to students as "under review", not playable.
    await CourseBuildItem.updateOne({ _id: item._id }, { $set: { 'video.reviewStatus': 'pending' } });
    res = mockRes();
    await ctrl.previewItem(req, res);
    lesson = res.body.data.lesson;
    assert.equal(lesson.videoId ?? null, null);
    assert.equal(lesson.aiVideo.url, null);
    assert.equal(lesson.aiVideo.reviewStatus, 'pending');
  } finally { restore(); }
});

test('failed job status is mirrored onto the draft and the lesson stays usable', async () => {
  const restore = stubAi();
  try {
    const { job, item } = await seed({ subject: 'Mathematics' });
    await runner.processItem((await CourseBuildJob.findById(job._id).lean()), await CourseBuildItem.findById(item._id), pages);
    const vjob = await queue.claim('w', ['lesson_video']);
    await queue.fail(vjob, 'w', Object.assign(new Error('No text-to-speech provider is available'), { retryable: false }), 'generating_audio');
    await videoJobs.applyJobStatus(vjob._id);
    const draft = await CourseBuildItem.findById(item._id).lean();
    assert.equal(draft.video.status, 'failed');
    assert.match(draft.video.error, /text-to-speech/);
    assert.ok(draft.content.notes, 'lesson content untouched');
    // Retry from the admin panel re-queues the same job (no duplicate).
    const { job: again, requeued } = await videoJobs.enqueueVideo({ buildJob: await CourseBuildJob.findById(job._id).lean(), item: draft, variant: 'explainer', force: true });
    assert.equal(requeued, true);
    assert.equal(String(again._id), String(vjob._id));
    assert.equal(again.state, 'queued');
  } finally { restore(); }
});

function mockRes() {
  const res = { statusCode: 200, body: null };
  res.status = (c) => { res.statusCode = c; return res; };
  res.json = (b) => { res.body = b; return res; };
  return res;
}
