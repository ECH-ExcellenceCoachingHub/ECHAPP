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
 *   REKKA_STYLE              whiteboard (default) | chalkboard | crayon
 *   REKKA_FORMAT             landscape (default) | square | portrait
 *   REKKA_LENGTH             short | standard | in_depth (default: from the lesson's target duration)
 *   REKKA_USD_PER_CREDIT     price of one credit, for the spending limits (optional)
 *   REKKA_POLL_MS            default 10 s
 *   REKKA_TIMEOUT_MS         default 12 min — leaves time for the fallback inside VIDEO_JOB_TIMEOUT_MS
 */

const STYLES = ['whiteboard', 'chalkboard', 'crayon', 'retro-reel', 'lyric-reel'];
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

function lengthFor(durationSec) {
  if (process.env.REKKA_LENGTH) return pick(process.env.REKKA_LENGTH, LENGTHS, 'standard');
  if (!durationSec || durationSec <= 150) return 'short';
  return durationSec <= 360 ? 'standard' : 'in_depth';
}

/** Credits a video is expected to cost: 1 + about 1 per 100 s of final length. */
function estimateCredits(durationSec) {
  return 1 + Math.ceil((durationSec || 180) / 100);
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

/** Topic + creative direction for a lesson (topic 3–300 chars, prompt ≤ 2000). */
function buildRequest({ title, content, subject, level, language, durationSec }) {
  const list = (arr, n) => (arr || []).filter(Boolean).slice(0, n).map(x => `- ${typeof x === 'string' ? x : x.term ? `${x.term}: ${x.definition || ''}` : x.title || x.name || ''}`).join('\n');
  const parts = [
    `Teach this lesson to ${level || 'secondary school'} students${subject && subject !== 'general' ? ` studying ${subject.replace('_', ' ')}` : ''}.`,
    language && !/^en/i.test(language) ? `Narrate in ${language}.` : '',
    content.summary ? `Summary: ${content.summary}` : '',
    content.learningObjectives?.length ? `Learning objectives:\n${list(content.learningObjectives, 6)}` : '',
    content.keyPoints?.length ? `Key points:\n${list(content.keyPoints, 8)}` : '',
    content.keyTerms?.length ? `Key terms:\n${list(content.keyTerms, 8)}` : '',
    content.formulas?.length ? `Formulas (show them exactly):\n${content.formulas.slice(0, 5).map(f => `- ${f.name}: ${f.expression}`).join('\n')}` : '',
    'Stay accurate to this material; do not invent facts, numbers or formulas. End with a short recap.',
  ].filter(Boolean);
  let topic = String(title || 'Lesson').trim();
  if (topic.length < 3) topic = `${topic} lesson`;
  return {
    topic: topic.slice(0, 300),
    style: pick(process.env.REKKA_STYLE, STYLES, 'whiteboard'),
    format: pick(process.env.REKKA_FORMAT, FORMATS, 'landscape'),
    prompt: parts.join('\n\n').slice(0, 2000),
    length: lengthFor(durationSec),
  };
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
    timeoutMs: 5 * 60 * 1000,
    headers: { Authorization: `Bearer ${apiKey()}` },
  });
}

module.exports = {
  name: 'rekka',
  isEnabled, buildRequest, estimateCredits, usdPerCredit, lengthFor,
  getCredits, createVideo, getVideo, waitForVideo, downloadVideo,
};
