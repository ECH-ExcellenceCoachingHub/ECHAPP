const CourseBuildItem = require('../../models/CourseBuildItem');
const Lesson = require('../../models/Lesson');
const ai = require('../course-builder/ai.service');
const { contentText } = require('../course-builder/integrity.service');
const youtube = require('./youtube.service');

/**
 * Guided experiment demonstrations: a teacher picks a real YouTube video for
 * a science lesson; the lesson's own procedure steps are shown beside it and
 * the app pauses at each step for an explanation and an optional check.
 *
 * Steps come from the LESSON (never from the video), so students are taught
 * the textbook procedure. Timestamps come from the video's chapters when it
 * has them, otherwise the teacher marks each step while watching.
 */

const MAX_STEPS = 8;
const str = (v, n) => String(v ?? '').replace(/\s+/g, ' ').trim().slice(0, n);

function defaultQuery(title) {
  const t = str(title, 90).replace(/^(lesson|topic|unit|practical|experiment)\s*\d*[:.\-–]?\s*/i, '');
  return `${t} experiment practical demonstration`;
}

async function suggest(item, { query } = {}) {
  const q = str(query, 120) || item.demo?.query || defaultQuery(item.title);
  const suggestions = await youtube.search(q);
  const demo = { ...(item.demo?.toObject?.() || item.demo || {}), query: q, suggestions, searchedAt: new Date(), updatedAt: new Date() };
  await CourseBuildItem.updateOne({ _id: item._id }, { $set: { demo } });
  return demo;
}

/** Validated steps from the planner's answer. */
function cleanSteps(raw, chapters = [], durationSec = null) {
  const steps = [];
  for (const s of (Array.isArray(raw) ? raw : []).slice(0, MAX_STEPS)) {
    const text = str(s?.text, 160);
    if (!text) continue;
    let at = null;
    let source = null;
    if (Number.isInteger(s.chapterIndex) && chapters[s.chapterIndex]) {
      at = chapters[s.chapterIndex].at;
      source = 'chapter';
    } else if (Number.isFinite(Number(s.at)) && s.at !== null && s.at !== '') {
      at = Math.max(0, Math.round(Number(s.at)));
      source = s.source === 'chapter' ? 'chapter' : 'teacher';
    }
    if (at !== null && durationSec && at >= durationSec) { at = null; source = null; }
    let check = null;
    const c = s?.check;
    if (c && str(c.question, 200) && Array.isArray(c.choices)) {
      const choices = c.choices.map(x => str(x, 100)).filter(Boolean).slice(0, 4);
      const answerIndex = Number(c.answerIndex);
      if (choices.length >= 2 && Number.isInteger(answerIndex) && answerIndex >= 0 && answerIndex < choices.length) {
        check = { question: str(c.question, 200), choices, answerIndex, explanation: str(c.explanation, 260) };
      }
    }
    steps.push({ text, at, source, explain: str(s?.explain, 600), check });
  }
  // Placed steps must play in order; a step placed before the previous one is unplaced again.
  let last = -1;
  for (const s of steps) {
    if (s.at === null) continue;
    if (s.at <= last) { s.at = null; s.source = null; } else last = s.at;
  }
  return steps;
}

async function planSteps(title, content, video) {
  const chapters = video.chapters || [];
  const prompt = `A student will watch a real video of this practical: "${video.title}".
Beside the video the app shows the practical's procedure steps, and pauses after each step so a teacher's voice can explain it.

From the LESSON below, list the hands-on procedure steps of the practical, in order (3-${MAX_STEPS} steps).
For each step give:
- "text": the step as a short instruction (max 15 words), using the lesson's own procedure;
- "explain": 2-3 short, simple sentences a warm teacher says after the student has watched the step: what was done and WHY. Beginners in English: everyday words, max 15 words per sentence;
- "check" (only for 1-2 key steps, otherwise null): { "question", "choices": [3-4 short options], "answerIndex", "explanation" }, answerable from the lesson.
${chapters.length ? `- "chapterIndex": index of the VIDEO CHAPTER where this step is shown, or null when no chapter matches.

VIDEO CHAPTERS:
${chapters.map((c, i) => `${i}: ${c.title}`).join('\n')}` : ''}

Use ONLY the lesson. If the lesson has no hands-on procedure, return { "steps": [] }.

LESSON: ${title}
${contentText(content).slice(0, 7000)}

Return JSON: { "steps": [ { "text": "...", "explain": "...", "check": null${chapters.length ? ', "chapterIndex": null' : ''} } ] }`;
  const raw = await ai.completeJson(prompt, {
    maxTokens: 3000,
    temperature: 0.2,
    system: 'You are an experienced science teacher. You only use facts from the lesson provided. You answer with one valid JSON object.',
  });
  return cleanSteps(raw?.steps, chapters, video.durationSec);
}

/** Pick a video; the lesson's steps are planned (and placed on chapters when the video has them). */
async function select(item, videoId) {
  const id = str(videoId, 20);
  if (!/^[A-Za-z0-9_-]{6,20}$/.test(id)) throw Object.assign(new Error('Invalid YouTube video id'), { status: 400 });
  const [video] = await youtube.details([id]);
  if (!video) throw Object.assign(new Error('That YouTube video was not found'), { status: 404 });
  if (!video.embeddable) throw Object.assign(new Error('The owner of that video does not allow it to be embedded in other apps'), { status: 400 });
  const { embeddable, madeForKids, ...selected } = video;
  const steps = await planSteps(item.title, item.content, selected);
  if (!steps.length) throw Object.assign(new Error('This lesson has no hands-on procedure to follow along with'), { status: 400 });
  return save(item, { selected, steps });
}

/** Teacher edits: step text, explanations, checks and timestamps. */
async function saveSteps(item, steps) {
  if (!item.demo?.selected) throw Object.assign(new Error('Choose a video first'), { status: 400 });
  const clean = cleanSteps(steps, [], item.demo.selected.durationSec);
  if (!clean.length) throw Object.assign(new Error('Add at least one step'), { status: 400 });
  return save(item, { steps: clean });
}

async function remove(item) {
  return save(item, { selected: null, steps: [] });
}

async function save(item, patch) {
  const demo = { ...(item.demo?.toObject?.() || item.demo || {}), ...patch, updatedAt: new Date() };
  await CourseBuildItem.updateOne({ _id: item._id }, { $set: { demo } });
  // An already-published lesson follows its draft straight away.
  if (item.published?.lessonId) await Lesson.updateOne({ _id: item.published.lessonId }, { $set: { demo: lessonDemo(demo) } });
  return demo;
}

/** What a lesson keeps: the chosen video and its steps (no search results). */
function lessonDemo(demo) {
  if (!demo?.selected || !demo.steps?.length) return null;
  return { selected: demo.selected, steps: demo.steps, updatedAt: demo.updatedAt || new Date() };
}

/** What students receive: only a demo whose steps are all placed in the video. */
function publicDemo(demo) {
  const d = lessonDemo(demo);
  if (!d || d.steps.some(s => s.at === null || s.at === undefined)) return null;
  const { chapters, ...video } = d.selected;
  return { video, steps: d.steps.map(({ source, ...s }) => s) };
}

module.exports = { suggest, select, saveSteps, remove, lessonDemo, publicDemo, cleanSteps, defaultQuery, planSteps };
