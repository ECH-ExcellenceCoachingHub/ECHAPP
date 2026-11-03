const { downloadToFile } = require('../media/http');

/**
 * Rekka AI (https://rekkaai.com/docs) — primary provider for lesson videos.
 * It makes the whole narrated video from a topic and creative direction; when
 * it is not configured or fails, the pipeline falls back to our own
 * storyboard → TTS → stock media (Wikimedia, …) → render → FFmpeg path.
 *
 *   REKKA_API_KEY            rk_live_… (Settings → API keys). Unset = disabled.
 *   VIDEO_PRIMARY_PROVIDER   rekka (default when a key is set) | pipeline (skip Rekka)
 *   REKKA_API_URL            default https://api.rekkaai.com
 *   REKKA_STYLE              chalkboard | whiteboard | crayon (default: chalkboard for maths/sciences/accounting, else whiteboard)
 *   REKKA_FORMAT             landscape (default) | square | portrait
 *   REKKA_CHAPTERS           chapters per video (default: what fits VIDEO_MAX_SECONDS, ~100 s each → 2 for 4 min)
 *   REKKA_LENGTH             short | standard | in_depth instead of chapters (not length-bounded)
 *   REKKA_MIN_SHORT_SIDE     smallest acceptable frame side in px (default 720); lower-quality videos fall back
 *   REKKA_MIN_SECONDS        shortest acceptable video (default 60)
 *   VIDEO_MAX_SECONDS        longest lesson video (default 240); Rekka videos over it (+20 s) fall back
 *   REKKA_USD_PER_CREDIT     price of one credit, for the spending limits (optional)
 *   REKKA_POLL_MS            default 10 s
 *   REKKA_TIMEOUT_MS         default 12 min — leaves time for the fallback inside VIDEO_JOB_TIMEOUT_MS
 */

// Teaching styles only: retro-reel / lyric-reel are 9:16 social clips (lyric-reel is silent).
const STYLES = ['whiteboard', 'chalkboard', 'crayon'];
const FORMATS = ['square', 'landscape', 'portrait'];
const LENGTHS = ['short', 'standard', 'in_depth'];
const MAX_VIDEO_BYTES = 500 * 1024 * 1024;

const sleep = (ms, signal) => new Promise((resolve, reject) => {
  const t = setTimeout(resolve, ms);
  signal?.addEventListener('abort', () => { clearTimeout(t); reject(signal.reason || new Error('aborted')); }, { once: true });
});

function apiKey() {
  return (process.env.REKKA_API_KEY || '').trim();
}

function baseUrl() {
  return (process.env.REKKA_API_URL || 'https://api.rekkaai.com').replace(/\/+$/, '');
}

function isEnabled() {
  const primary = (process.env.VIDEO_PRIMARY_PROVIDER || 'rekka').toLowerCase();
  return primary === 'rekka' && !!apiKey();
}

function pick(value, allowed, fallback) {
  const v = String(value || '').toLowerCase();
  return allowed.includes(v) ? v : fallback;
}

/** Subject templates give a [min, max] range; plain numbers are accepted too. */
function seconds(durationSec) {
  const v = Array.isArray(durationSec) ? Math.max(...durationSec) : Number(durationSec);
  return Number.isFinite(v) && v > 0 ? v : null;
}

function lengthFor(durationSec) {
  if (process.env.REKKA_LENGTH) return pick(process.env.REKKA_LENGTH, LENGTHS, 'standard');
  const s = seconds(durationSec);
  if (!s || s <= 150) return 'short';
  return s <= 360 ? 'standard' : 'in_depth';
}

/**
 * Credits a video is expected to cost: 1 + about 1 per 100 s of final length.
 * A chapter runs about 100 s (measured: 7 chapters → 694 s, 7 credits).
 */
function estimateCredits(durationSec, chapters) {
  if (chapters) return 1 + chapters;
  return 1 + Math.ceil((seconds(durationSec) || 180) / 100);
}

/** Science and maths read best as a teacher working on a chalkboard. */
const BOARD_SUBJECTS = ['mathematics', 'physics', 'chemistry', 'accounting', 'general_science'];

function styleFor(subject) {
  if (process.env.REKKA_STYLE) return pick(process.env.REKKA_STYLE, STYLES, 'whiteboard');
  return BOARD_SUBJECTS.includes(subject) ? 'chalkboard' : 'whiteboard';
}

function usdPerCredit() {
  const n = parseFloat(process.env.REKKA_USD_PER_CREDIT);
  return Number.isFinite(n) && n >= 0 ? n : null;
}

async function request(method, pathname, { body, signal, timeoutMs = 30000 } = {}) {
  const t = AbortSignal.timeout(timeoutMs);
  const res = await fetch(`${baseUrl()}${pathname}`, {
    method,
    headers: { Authorization: `Bearer ${apiKey()}`, Accept: 'application/json', ...(body ? { 'Content-Type': 'application/json' } : {}) },
    body: body ? JSON.stringify(body) : undefined,
    signal: signal ? AbortSignal.any([signal, t]) : t,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const detail = data?.details?.fieldErrors ? ` ${JSON.stringify(data.details.fieldErrors)}` : '';
    throw Object.assign(new Error(`Rekka ${method} ${pathname}: HTTP ${res.status} ${data?.error || ''}${detail}`.trim()), { status: res.status, code: 'REKKA_HTTP', body: data });
  }
  return data;
}

const PROMPT_MAX = 2000;
const clean = (s) => String(s || '').replace(/[*_`#>|]/g, '').replace(/\s+/g, ' ').trim();
const clip = (s, n) => (s.length > n ? `${s.slice(0, n - 1).trimEnd()}…` : s);

/**
 * The teaching steps of a lesson, in order: the "## headings" of the notes
 * (each with its first sentence), else the key points, else the objectives.
 * Each step becomes one Rekka chapter.
 */
function teachingSteps(content) {
  const steps = [];
  const sections = String(content.notes || '').split(/^#{2,3}\s+/m).slice(1);
  for (const sec of sections) {
    const [head, ...body] = sec.split('\n');
    const first = clean(body.join(' ')).split(/(?<=[.!?])\s/)[0] || '';
    if (clean(head)) steps.push(first ? `${clean(head)} — ${clip(first, 110)}` : clean(head));
  }
  if (steps.length < 2) {
    const fallback = (content.keyPoints?.length ? content.keyPoints : content.learningObjectives || []).map(clean).filter(Boolean);
    if (fallback.length > steps.length) return fallback.slice(0, 10);
  }
  return steps.slice(0, 10);
}

/** About 100 s of video per Rekka chapter (measured: 7 chapters → 694 s). */
const SECONDS_PER_CHAPTER = 100;

/** Chapters that fit the target length: 2 for a 4-minute lesson (≈ 3½ min). */
function chaptersFor(durationSec) {
  const n = parseInt(process.env.REKKA_CHAPTERS || '', 10);
  if (n > 0) return Math.min(60, n);
  const max = seconds(durationSec) || 240;
  return Math.max(1, Math.floor((max - 20) / SECONDS_PER_CHAPTER));
}

/**
 * Topic + creative direction for a lesson (topic 3–300 chars, prompt ≤ 2000).
 * The prompt asks for a short beginner lesson taught like a real teacher at
 * the board: the idea in plain words, then the worked example line by line,
 * with the book's exact numbers, inside the length limit.
 * Sections are added in priority order while they fit.
 */
function buildRequest({ title, content, subject, level, language, durationSec }) {
  const steps = teachingSteps(content).slice(0, 4);
  const subj = subject && subject !== 'general' ? subject.replace('_', ' ') : '';
  const chapters = chaptersFor(durationSec);
  const minutes = Math.floor((seconds(durationSec) || 240) / 60);
  const plan = chapters === 1
    ? 'Use one chapter: the idea in plain words, then the worked example line by line, then a one-sentence recap.'
    : `Use ${chapters} chapters: first the idea in plain words, ${chapters > 2 ? 'then the key steps, ' : ''}then the worked example solved line by line, ending with a one-sentence recap.`;
  const sections = [
    `You are a patient, friendly ${subj ? `${subj} ` : ''}teacher at the board, teaching ${level || 'secondary school'} students who are complete beginners in this topic. The whole video must be under ${minutes} minutes, so teach only the essentials below and explain them really well. ${plan}`,
    'Teach for a beginner: simple everyday words, short sentences, one small idea at a time. Say what each new word or symbol means the first time you use it. Give one real-life comparison. Write each line on the board as you say it, say why you do each step, and never skip a step of the working. Ask "you" one quick question and answer it.',
    language && !/^en/i.test(language) ? `Speak in ${language}.` : '',
    steps.length ? `Cover these points, in order:\n${steps.map((s, i) => `${i + 1}. ${s}`).join('\n')}` : '',
    content.formulas?.length ? `Write these formulas exactly:\n${content.formulas.slice(0, 5).map(f => `- ${clean(f.name)}: ${clean(f.expression)}`).join('\n')}` : '',
    content.examples?.length ? `Worked example to solve on the board with these exact numbers:\n${clip(`${clean(content.examples[0].title)}: ${clean(content.examples[0].body)}`, 420)}` : '',
    content.keyTerms?.length ? `Key terms: ${content.keyTerms.slice(0, 6).map(t => clean(t.term)).filter(Boolean).join(', ')}.` : '',
    content.commonMistakes?.length ? `Warn about: ${clip(clean(content.commonMistakes[0]), 120)}.` : '',
    content.summary && !steps.length ? `Summary: ${clip(clean(content.summary), 400)}` : '',
  ].filter(Boolean);
  const closing = `Use only facts, numbers and formulas from this lesson. Keep the whole video under ${minutes} minutes.`;

  let prompt = '';
  for (const s of sections) {
    const next = prompt ? `${prompt}\n\n${s}` : s;
    if (next.length + closing.length + 2 <= PROMPT_MAX) prompt = next;
  }
  prompt = `${prompt}\n\n${closing}`.slice(0, PROMPT_MAX);

  let topic = clean(title) || 'Lesson';
  if (topic.length < 3) topic = `${topic} lesson`;
  const body = {
    topic: topic.slice(0, 300),
    style: styleFor(subject),
    format: pick(process.env.REKKA_FORMAT, FORMATS, 'landscape'),
    prompt,
  };
  // `chapters` sets the length precisely (`length: short` alone is not bounded).
  if (process.env.REKKA_LENGTH) body.length = lengthFor(durationSec);
  else body.chapters = chapters;
  return body;
}

async function getCredits({ signal } = {}) {
  const r = await request('GET', '/v1/credits', { signal });
  return typeof r.credits === 'number' ? r.credits : null;
}

async function createVideo(body, { signal } = {}) {
  return request('POST', '/v1/videos', { body, signal });
}

async function getVideo(id, { signal } = {}) {
  return request('GET', `/v1/videos/${encodeURIComponent(id)}`, { signal });
}

/** Poll until the video is done; throws on `error` or timeout. */
async function waitForVideo(id, { signal, onPoll } = {}) {
  const pollMs = Math.max(2000, parseInt(process.env.REKKA_POLL_MS || '10000', 10) || 10000);
  const timeoutMs = parseInt(process.env.REKKA_TIMEOUT_MS || String(12 * 60 * 1000), 10);
  const deadline = Date.now() + timeoutMs;
  let failures = 0;
  for (;;) {
    let v;
    try {
      v = await getVideo(id, { signal });
      failures = 0;
    } catch (e) {
      if (signal?.aborted || e.status === 404 || e.status === 401) throw e;
      if (++failures >= 5) throw e; // transient network / 5xx errors are retried a few times
    }
    if (v) {
      await onPoll?.(v);
      if (v.status === 'done' && v.videoUrl) return v;
      if (v.status === 'error') throw Object.assign(new Error(`Rekka could not make the video (job ${id})`), { code: 'REKKA_FAILED' });
    }
    if (Date.now() > deadline) throw Object.assign(new Error(`Rekka did not finish within ${Math.round(timeoutMs / 60000)} min (job ${id})`), { code: 'REKKA_TIMEOUT' });
    await sleep(pollMs, signal);
  }
}

/** The video link is private: it needs the same bearer token. */
async function downloadVideo(video, file, { signal } = {}) {
  const url = video.videoUrl.startsWith('http') ? video.videoUrl : `${baseUrl()}${video.videoUrl}`;
  return downloadToFile(url, file, {
    signal,
    maxBytes: MAX_VIDEO_BYTES,
    accept: /^(video\/|application\/octet-stream)/,
    timeoutMs: 10 * 60 * 1000, // the file host is slow: 19 MB took over a minute
    headers: { Authorization: `Bearer ${apiKey()}` },
  });
}

module.exports = {
  name: 'rekka',
  isEnabled, buildRequest, teachingSteps, estimateCredits, usdPerCredit, lengthFor, styleFor, chaptersFor,
  getCredits, createVideo, getVideo, waitForVideo, downloadVideo,
};
