const crypto = require('crypto');
const fsp = require('fs/promises');
const path = require('path');
const storage = require('../storage.service');
const { PROVIDERS } = require('./providers');
const { downloadToFile } = require('./http');

/**
 * Finds licensed photos and video clips that match what the narrator is
 * saying in a scene, downloads them once into our own storage and normalises
 * them for compositing (photos → JPEG, clips → 1280×720 H.264 without sound).
 *
 * The planner gives each scene that needs real-world imagery a short search
 * query ("scene.media"). Candidates from every enabled provider are ranked by
 * how many query words appear in their title/tags/description, then by size
 * and shape. Anything below VIDEO_STOCK_MIN_MATCH is rejected rather than
 * showing an unrelated picture. Textbook figures remain the source of truth
 * for diagrams; stock media is only used for context and illustration.
 */

const STOP = new Set(('a an and are as at be by for from has have how in into is it its of on or that the their this to was were what when where which who why with without your you we our they them these those can will about over under between showing shows show using used use').split(' '));

function config() {
  const int = (v, d) => (Number.isFinite(parseInt(v, 10)) ? parseInt(v, 10) : d);
  return {
    enabled: String(process.env.VIDEO_STOCK_MEDIA || 'true').toLowerCase() !== 'false',
    providers: String(process.env.VIDEO_STOCK_PROVIDERS || 'pexels,pixabay,wikimedia').split(',').map(s => s.trim().toLowerCase()).filter(n => PROVIDERS[n]),
    maxItems: int(process.env.VIDEO_STOCK_MAX_ITEMS, 8),
    maxImageBytes: 15 * 1024 * 1024,
    maxVideoBytes: int(process.env.VIDEO_STOCK_MAX_VIDEO_MB, 60) * 1024 * 1024,
    minMatch: Number.isFinite(parseFloat(process.env.VIDEO_STOCK_MIN_MATCH)) ? parseFloat(process.env.VIDEO_STOCK_MIN_MATCH) : 0.5,
    maxClipSeconds: int(process.env.VIDEO_STOCK_MAX_CLIP_SECONDS, 30),
  };
}

function availableProviders(cfg = config()) {
  return cfg.providers.filter(n => PROVIDERS[n].available());
}

function tokens(s) {
  return String(s || '').toLowerCase().normalize('NFKD').replace(/[̀-ͯ]/g, '')
    .split(/[^a-z0-9]+/).filter(t => t.length > 2 && !STOP.has(t))
    .map(t => (t.length > 4 && t.endsWith('ies') ? `${t.slice(0, -3)}y` : t.length > 4 && t.endsWith('s') && !t.endsWith('ss') ? t.slice(0, -1) : t));
}

/** Share of the query's words found in the candidate's text (0..1). */
function relevance(query, text) {
  const q = [...new Set(tokens(query))];
  if (!q.length) return 0;
  const t = new Set(tokens(text));
  return q.filter(w => t.has(w)).length / q.length;
}

function scoreCandidate(c, query, cfg = config()) {
  const rel = relevance(query, c.text);
  let score = rel;
  if (c.width >= 1280) score += 0.1;
  else if (c.width < 900) score -= 0.3;
  if (c.height > c.width) score -= 0.3; // portrait does not fill a 16:9 frame
  if (c.kind === 'video') {
    if (!c.durationSec || c.durationSec < 3) score -= 0.5;
    if (c.bytes && c.bytes > cfg.maxVideoBytes) score = -1;
  }
  return { rel, score };
}

const sha1 = (s) => crypto.createHash('sha1').update(s).digest('hex');

/** Provider search with a 24-hour cache in storage (Pixabay requires caching; it also saves rate limit). */
async function cachedSearch(provider, query, kind, { signal } = {}) {
  const key = `stock-media/search/${provider.name}/${kind}/${sha1(query.toLowerCase().trim())}.json`;
  try {
    if (await storage.exists(key)) {
      const cached = JSON.parse(String(await storage.get(key)));
      if (Date.now() - cached.at < 24 * 3600 * 1000) return cached.results;
    }
  } catch (_) { /* cache miss */ }
  const results = await provider.search(query, { kind, signal });
  // Empty answers are not cached: they are cheap to repeat and may be transient.
  if (results.length) await storage.put(key, Buffer.from(JSON.stringify({ at: Date.now(), query, results })), 'application/json').catch(() => {});
  return results;
}

// Lesson-title words too general to identify what a picture must show.
const GENERIC = new Set('introduction lesson chapter unit part basic basics types type methods method estimating estimate size simple overview study studies principles concept concepts'.split(' '));

/** Lesson vocabulary (title, key terms) used to tell what a picture must show. */
function topicTerms(...texts) {
  return [...new Set(texts.flat().flatMap(t => tokens(t)).filter(w => !GENERIC.has(w)))];
}

/** Topic words that appear in a search phrase. */
function topicIn(query, topic = []) {
  const t = new Set(topic);
  return [...new Set(tokens(query))].filter(w => t.has(w));
}

/**
 * The query, the planner's alternatives, then a short fallback: the topic
 * words of the query ("quadrat") or, without a topic, its first two key words.
 */
function queryVariants(request, topic = []) {
  const out = [request.query, ...(request.alternatives || [])].map(q => String(q || '').trim()).filter(Boolean);
  const key = tokens(request.query);
  const subject = topicIn(request.query, topic);
  if (subject.length) out.push(subject.join(' '));
  else if (key.length > 2) out.push(key.slice(0, 2).join(' '));
  return [...new Set(out.map(q => q.toLowerCase()))].slice(0, 4);
}

/**
 * Relevance gate. When the phrase names a lesson topic ("hand holding quadrat
 * frame"), the picture must show that topic — "Hand in hand" is rejected even
 * though half the words match. Otherwise VIDEO_STOCK_MIN_MATCH of the words
 * must appear.
 */
function judge(c, query, subject, cfg) {
  const { rel, score } = scoreCandidate(c, query, cfg);
  if (score <= 0) return null;
  if (subject.length) {
    const text = new Set(tokens(c.text));
    const hits = subject.filter(w => text.has(w)).length;
    if (!hits || rel < Math.min(cfg.minMatch, 0.25)) return null;
    return { rel, score: score + 0.2 * hits };
  }
  return rel >= cfg.minMatch ? { rel, score } : null;
}

// A provider that keeps rate-limiting us is skipped for a while instead of hammered.
const cooldownUntil = new Map();
const COOLDOWN_MS = 60000;

/**
 * Best licensed match for one request ({ query, kind, alternatives }). A
 * request for a video falls back to a photo when no clip is relevant enough.
 * `topic` = lesson vocabulary (see topicTerms).
 */
async function findMedia(request, { signal, exclude = new Set(), cfg = config(), topic = [] } = {}) {
  const names = availableProviders(cfg);
  const errors = [];
  let considered = 0;
  const subject = topicIn(request.query, topic);
  for (const [qi, query] of queryVariants(request, topic).entries()) {
    // Clips are searched with the main phrase only; fallbacks look for photos.
    const kinds = request.kind === 'video' && qi === 0 ? ['video', 'image'] : ['image'];
    for (const kind of kinds) {
      const pool = [];
      for (const name of names) {
        if ((cooldownUntil.get(name) || 0) > Date.now()) continue;
        try {
          pool.push(...await cachedSearch(PROVIDERS[name], query, kind, { signal }));
        } catch (e) {
          if (signal?.aborted) throw e;
          errors.push(`${name}: ${e.message}`);
          if (e.status === 429) cooldownUntil.set(name, Date.now() + COOLDOWN_MS);
        }
      }
      considered += pool.length;
      // Relevance is always judged against the scene's full query, so a
      // relaxed search cannot sneak in a loosely related picture.
      const ranked = pool
        .filter(c => !exclude.has(`${c.provider}:${c.id}`))
        .map(c => ({ c, ...judge(c, request.query, subject, cfg) }))
        .filter(x => x.score > 0)
        .sort((a, b) => b.score - a.score);
      if (ranked.length) return { candidate: ranked[0].c, relevance: Math.round(ranked[0].rel * 100) / 100, errors, considered, query };
    }
  }
  return { candidate: null, relevance: 0, errors, considered };
}

/**
 * Download (or reuse from storage) and normalise one candidate.
 * @returns {{ key, file, durationSec }}
 */
async function materialize(c, workDir, { signal, ffmpeg, cfg = config() } = {}) {
  const assembler = require('../render/assembler');
  const run = ffmpeg || assembler.run;
  const bin = process.env.FFMPEG_BIN || 'ffmpeg';
  const safeId = String(c.id).replace(/[^a-zA-Z0-9_-]/g, '_');
  const key = `stock-media/${c.provider}/${safeId}.${c.kind === 'video' ? '720p.mp4' : 'jpg'}`;
  const local = path.join(workDir, `stock_${c.provider}_${safeId}.${c.kind === 'video' ? 'mp4' : 'jpg'}`);

  if (await storage.exists(key)) {
    await storage.download(key, local);
  } else {
    const raw = path.join(workDir, `raw_${c.provider}_${safeId}`);
    await downloadToFile(c.downloadUrl, raw, { maxBytes: c.kind === 'video' ? cfg.maxVideoBytes : cfg.maxImageBytes, signal });
    try {
      if (c.kind === 'image') {
        await run(bin, ['-y', '-v', 'error', '-i', raw, '-frames:v', '1', '-vf', "scale='min(1920,iw)':-2", '-q:v', '3', local], { signal });
      } else {
        await run(bin, ['-y', '-v', 'error', '-i', raw, '-t', String(cfg.maxClipSeconds), '-an',
          '-vf', 'scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720,fps=25,format=yuv420p',
          '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '24', '-movflags', '+faststart', local], { signal });
      }
    } finally {
      await fsp.rm(raw, { force: true });
    }
    await storage.put(key, local, c.kind === 'video' ? 'video/mp4' : 'image/jpeg');
    await storage.put(`${key}.json`, Buffer.from(JSON.stringify(creditOf(c), null, 2)), 'application/json').catch(() => {});
  }
  const durationSec = c.kind === 'video' ? await assembler.mediaDuration(local, { signal }) : null;
  return { key, file: local, durationSec };
}

function creditOf(a) {
  return {
    provider: a.provider, providerLabel: a.providerLabel, id: a.id, kind: a.kind,
    title: a.title, author: a.author, authorUrl: a.authorUrl, sourceUrl: a.sourceUrl,
    license: a.license, licenseUrl: a.licenseUrl, attributionRequired: !!a.attributionRequired,
  };
}

/** Short on-screen credit, e.g. "Photo: Jane Doe / Wikimedia Commons · CC BY 4.0". */
function creditLine(a) {
  const what = a.kind === 'video' ? 'Video' : 'Photo';
  // On screen: the name only ("Olivier Dugornay (IFREMER, address…)" → "Olivier Dugornay").
  // The full author text stays in the credits slide and in the app.
  let author = String(a.author || '').replace(/\s*[([].*$/, '').trim() || a.author;
  if (author.length > 48) author = `${author.slice(0, 47)}…`;
  return `${what}: ${author} / ${a.providerLabel}${a.attributionRequired || /^cc/i.test(a.license) ? ` · ${a.license}` : ''}`;
}

/**
 * Find media for every scene that asked for it (up to VIDEO_STOCK_MAX_ITEMS).
 * Never throws for "nothing found" or provider outages — the scene is then
 * rendered without media and a warning is returned.
 *
 * @returns {{ assets: Map<number, object>, warnings: string[] }}
 */
async function prepareStoryboardMedia(storyboard, workDir, { signal, log = () => {}, topic = [] } = {}) {
  const cfg = config();
  const assets = new Map();
  const warnings = [];
  if (!cfg.enabled) return { assets, warnings };
  const names = availableProviders(cfg);
  if (!names.length) {
    warnings.push('No stock-media provider is available (set VIDEO_STOCK_PROVIDERS / provider API keys)');
    return { assets, warnings };
  }
  const used = new Set();
  const wanted = storyboard.scenes.filter(s => s.media?.query).slice(0, cfg.maxItems);
  for (const scene of wanted) {
    if (signal?.aborted) throw signal.reason || new Error('aborted');
    const { candidate, relevance: rel, errors } = await findMedia(scene.media, { signal, exclude: used, cfg, topic });
    if (errors.length) log(`stock media: ${errors.join('; ')}`);
    if (!candidate) {
      warnings.push(`Scene ${scene.n}: no licensed ${scene.media.kind} matched "${scene.media.query}"`);
      continue;
    }
    try {
      const m = await materialize(candidate, workDir, { signal, cfg });
      used.add(`${candidate.provider}:${candidate.id}`);
      assets.set(scene.n, { ...creditOf(candidate), ...m, query: scene.media.query, relevance: rel, credit: creditLine(candidate) });
    } catch (e) {
      if (signal?.aborted) throw e;
      warnings.push(`Scene ${scene.n}: ${candidate.provider} ${candidate.kind} could not be used (${e.message})`);
    }
  }
  return { assets, warnings };
}

module.exports = {
  _resetCooldowns: () => cooldownUntil.clear(),
  config,
  availableProviders,
  tokens,
  relevance,
  scoreCandidate,
  queryVariants,
  topicTerms,
  topicIn,
  findMedia,
  materialize,
  prepareStoryboardMedia,
  creditOf,
  creditLine,
};
