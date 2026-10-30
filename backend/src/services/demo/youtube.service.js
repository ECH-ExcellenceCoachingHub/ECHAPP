const crypto = require('crypto');
const storage = require('../video/storage.service');
const { fetchJson } = require('../video/media/http');

/**
 * YouTube Data API v3 (YOUTUBE_DATA_API_V3_KEY): search for embeddable
 * experiment demonstrations and read their length and chapters.
 *
 * Quota: a search costs 100 units of the default 10,000 a day, so results are
 * cached in storage for 7 days and searches only run when a teacher asks.
 * Videos are only ever shown in YouTube's embedded player (YouTube API terms).
 */

const API = 'https://www.googleapis.com/youtube/v3';
const CACHE_MS = 7 * 24 * 3600 * 1000;

const apiKey = () => process.env.YOUTUBE_DATA_API_V3_KEY || process.env.YOUTUBE_API_KEY || '';
const available = () => !!apiKey();

/** "PT1H2M10S" → 3730 */
function parseDuration(iso) {
  const m = String(iso || '').match(/^P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/);
  if (!m) return null;
  const [, d, h, min, s] = m.map(x => parseInt(x || '0', 10));
  return d * 86400 + h * 3600 + min * 60 + s;
}

/**
 * Chapters from a description: lines starting with a timestamp ("0:00 Intro",
 * "1:05:30 - Results"). YouTube only treats them as chapters when the first is
 * 0:00 and there are at least three, so the same rule is applied here.
 */
function parseChapters(description) {
  const out = [];
  for (const line of String(description || '').split(/\r?\n/)) {
    const m = line.trim().match(/^[([]?((?:\d{1,2}:)?\d{1,2}:\d{2})[)\]]?\s*[-–—:|.]?\s*(.+)$/);
    if (!m) continue;
    const at = m[1].split(':').map(Number).reduce((a, n) => a * 60 + n, 0);
    const title = m[2].trim().slice(0, 120);
    if (title && (!out.length || at > out[out.length - 1].at)) out.push({ at, title });
  }
  return out.length >= 3 && out[0].at === 0 ? out : [];
}

function decode(s) {
  return String(s || '').replace(/&#39;/g, "'").replace(/&quot;/g, '"').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
}

async function call(path, params) {
  const url = `${API}/${path}?${new URLSearchParams({ ...params, key: apiKey() })}`;
  try {
    return await fetchJson(url, { retries: 1 });
  } catch (e) {
    // Never leak the key in error messages.
    throw Object.assign(new Error(String(e.message).replace(apiKey(), '***')), { status: e.status });
  }
}

/** Length, chapters and embeddability of up to 50 videos. */
async function details(ids) {
  if (!ids.length) return [];
  const data = await call('videos', { part: 'snippet,contentDetails,status', id: ids.join(','), maxResults: '50' });
  return (data.items || []).map(v => ({
    videoId: v.id,
    title: decode(v.snippet?.title),
    channel: decode(v.snippet?.channelTitle),
    durationSec: parseDuration(v.contentDetails?.duration),
    thumbnail: v.snippet?.thumbnails?.medium?.url || v.snippet?.thumbnails?.default?.url || null,
    chapters: parseChapters(v.snippet?.description),
    embeddable: v.status?.embeddable !== false && v.status?.privacyStatus !== 'private',
    madeForKids: !!v.status?.madeForKids,
  }));
}

/**
 * Embeddable, safe-search demonstrations for a phrase, best first. Very short
 * clips (under 30 s) and long lectures (over 20 min) are left out.
 */
async function search(query, { max = 8, language = 'en' } = {}) {
  if (!available()) throw Object.assign(new Error('YouTube is not configured on the server (YOUTUBE_DATA_API_V3_KEY missing)'), { status: 503 });
  const q = String(query || '').trim().slice(0, 120);
  const key = `demo-search/${crypto.createHash('sha1').update(`${language}|${q.toLowerCase()}`).digest('hex')}.json`;
  try {
    if (await storage.exists(key)) {
      const cached = JSON.parse(String(await storage.get(key)));
      if (Date.now() - cached.at < CACHE_MS) return cached.results;
    }
  } catch (_) { /* cache miss */ }

  const data = await call('search', {
    part: 'snippet', q, type: 'video', videoEmbeddable: 'true', safeSearch: 'strict',
    relevanceLanguage: language, maxResults: String(Math.min(15, max + 5)),
  });
  const ids = (data.items || []).map(i => i.id?.videoId).filter(Boolean);
  const results = (await details(ids))
    .filter(v => v.embeddable && v.durationSec >= 30 && v.durationSec <= 1200)
    .slice(0, max)
    .map(({ embeddable, madeForKids, ...v }) => v);
  if (results.length) await storage.put(key, Buffer.from(JSON.stringify({ at: Date.now(), query: q, results })), 'application/json').catch(() => {});
  return results;
}

module.exports = { available, search, details, parseDuration, parseChapters };
