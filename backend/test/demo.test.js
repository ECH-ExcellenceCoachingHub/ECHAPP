/**
 * Guided experiment demonstrations (YouTube): chapter parsing, step planning
 * and validation, teacher edits, publishing and what students receive.
 *
 * No network: the YouTube API and the AI planner are stubbed.
 */
const { startDb, stopDb, oid, silenceLogs } = require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');

const Course = require('../src/models/Course');
const CourseBuildJob = require('../src/models/CourseBuildJob');
const CourseBuildItem = require('../src/models/CourseBuildItem');
const Lesson = require('../src/models/Lesson');
const ai = require('../src/services/course-builder/ai.service');
const youtube = require('../src/services/demo/youtube.service');
const demos = require('../src/services/demo/demo.service');
const { publishApproved } = require('../src/services/course-builder/publisher.service');

const original = { completeJson: ai.completeJson, details: youtube.details, search: youtube.search };
let restoreLogs;
let item;

const VIDEO = { videoId: 'abcDEF12345', title: 'Testing a leaf for starch', channel: 'Science', durationSec: 300, thumbnail: null, embeddable: true, madeForKids: false };

test.before(async () => {
  restoreLogs = silenceLogs();
  await startDb();
  const userId = oid();
  const course = await Course.create({ title: 'Biology S2', description: 'Biology', createdBy: userId, price: 0, duration: 10, level: 'beginner' });
  const job = await CourseBuildJob.create({ courseId: course._id, createdBy: userId, status: 'ready', outline: { subject: 'Biology', bookTitle: 'Biology', level: 'S2', chapters: [{ index: 0, title: 'Plants', pageStart: 1, pageEnd: 2, lessons: [{ title: 'Testing a leaf for starch', pageStart: 1, pageEnd: 2 }] }] } });
  item = await CourseBuildItem.create({
    jobId: job._id, courseId: course._id, kind: 'lesson', chapterIndex: 0, title: 'Testing a leaf for starch', status: 'approved', contentVersion: 1,
    content: { summary: 'Leaves store starch.', notes: 'Procedure: boil the leaf, put it in warm alcohol, rinse it, add iodine. Iodine turns blue-black with starch.' },
  });
});

test.after(async () => {
  ai.completeJson = original.completeJson;
  Object.assign(youtube, { details: original.details, search: original.search });
  await stopDb();
  restoreLogs();
});

test('YouTube durations and description chapters', () => {
  assert.equal(youtube.parseDuration('PT4M7S'), 247);
  assert.equal(youtube.parseDuration('PT1H2M'), 3720);
  const chapters = youtube.parseChapters('Great video\n0:00 Intro\n0:45 - Boiling the leaf\n(1:30) Alcohol bath\n2:10 Iodine\nthanks');
  assert.deepEqual(chapters.map(c => c.at), [0, 45, 90, 130]);
  assert.equal(chapters[1].title, 'Boiling the leaf');
  assert.deepEqual(youtube.parseChapters('0:30 a\n1:00 b\n2:00 c'), [], 'YouTube chapters must start at 0:00');
  assert.deepEqual(youtube.parseChapters('0:00 a\n1:00 b'), [], 'at least three chapters');
});

test('steps are validated: order, chapters, bounds and check questions', () => {
  const chapters = [{ at: 0, title: 'Intro' }, { at: 40, title: 'Boil' }, { at: 90, title: 'Alcohol' }];
  const steps = demos.cleanSteps([
    { text: 'Boil the leaf', explain: 'This kills the cells.', chapterIndex: 1, check: { question: 'Why boil?', choices: ['Kill cells', 'Colour'], answerIndex: 0 } },
    { text: 'Warm alcohol', chapterIndex: 2, check: { question: 'Broken', choices: ['only one'], answerIndex: 0 } },
    { text: 'Rinse', at: 50 }, // before the previous step → unplaced
    { text: 'Iodine', at: 999 }, // past the end → unplaced
    { text: '' },
  ], chapters, 300);
  assert.equal(steps.length, 4);
  assert.deepEqual(steps.map(s => s.at), [40, 90, null, null]);
  assert.deepEqual(steps.map(s => s.source), ['chapter', 'chapter', null, null]);
  assert.equal(steps[0].check.answerIndex, 0);
  assert.equal(steps[1].check, null, 'invalid check dropped');
});

test('selecting a video plans the lesson steps; students see nothing until every step is placed', async () => {
  youtube.details = async ([id]) => [{ ...VIDEO, videoId: id, chapters: [] }];
  ai.completeJson = async (prompt) => {
    assert.match(prompt, /boil the leaf/i, 'the steps come from the lesson');
    return { steps: [
      { text: 'Boil the leaf in water', explain: 'Boiling kills the cells.', check: null },
      { text: 'Put the leaf in warm alcohol', explain: 'Alcohol removes the green colour.', check: { question: 'What does alcohol remove?', choices: ['Chlorophyll', 'Starch'], answerIndex: 0, explanation: 'Chlorophyll is green.' } },
      { text: 'Add iodine', explain: 'Blue-black means starch.' },
    ] };
  };
  const demo = await demos.select(item, VIDEO.videoId);
  assert.equal(demo.selected.videoId, VIDEO.videoId);
  assert.equal(demo.steps.length, 3);
  assert.ok(demo.steps.every(s => s.at === null), 'no chapters → the teacher places the steps');
  assert.equal(demos.publicDemo(demo), null);

  item = await CourseBuildItem.findById(item._id);
  await assert.rejects(() => demos.select(item, 'bad id!'), /Invalid YouTube video id/);
  youtube.details = async () => [{ ...VIDEO, embeddable: false }];
  await assert.rejects(() => demos.select(item, VIDEO.videoId), /does not allow it to be embedded/);
});

test('teacher places the steps; publishing copies the demo and students get a clean version', async () => {
  item = await CourseBuildItem.findById(item._id);
  const placed = item.demo.steps.map((s, i) => ({ ...s.toObject(), at: [12, 75, 160][i], source: 'teacher' }));
  const demo = await demos.saveSteps(item, placed);
  assert.deepEqual(demo.steps.map(s => s.at), [12, 75, 160]);

  const pub = demos.publicDemo(demo);
  assert.equal(pub.video.videoId, VIDEO.videoId);
  assert.equal(pub.steps[1].check.question, 'What does alcohol remove?');
  assert.equal(pub.steps[0].source, undefined, 'internal fields are not sent to students');
  assert.equal(pub.video.chapters, undefined);

  await publishApproved(item.jobId);
  const lesson = await Lesson.findOne({ buildItemId: item._id }).lean();
  assert.equal(lesson.demo.selected.videoId, VIDEO.videoId);
  assert.deepEqual(lesson.demo.suggestions, [], 'search results stay on the draft');

  // Edits after publishing reach the lesson straight away.
  item = await CourseBuildItem.findById(item._id);
  await demos.saveSteps(item, placed.map((s, i) => ({ ...s, at: s.at + i })));
  assert.deepEqual((await Lesson.findById(lesson._id).lean()).demo.steps.map(s => s.at), [12, 76, 162]);

  item = await CourseBuildItem.findById(item._id);
  await demos.remove(item);
  assert.equal((await Lesson.findById(lesson._id).lean()).demo, null);
});

test('searching stores the suggestions and the query on the draft', async () => {
  youtube.search = async () => [{ ...VIDEO, chapters: [] }];
  item = await CourseBuildItem.findById(item._id);
  const demo = await demos.suggest(item, {});
  assert.match(demo.query, /Testing a leaf for starch experiment practical/);
  assert.equal(demo.suggestions.length, 1);
  const saved = await CourseBuildItem.findById(item._id).lean();
  assert.equal(saved.demo.suggestions[0].videoId, VIDEO.videoId);
});
