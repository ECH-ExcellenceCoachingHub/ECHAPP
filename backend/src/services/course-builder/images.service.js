const axios = require('axios');

/**
 * Finds real, freely-licensed pictures for lesson image requests on
 * Wikimedia Commons (no API key needed). Each image keeps its licence and
 * author so the lesson can show proper attribution. Teachers review and can
 * remove or replace any image before publishing.
 */

const API = 'https://commons.wikimedia.org/w/api.php';
const USER_AGENT = 'ExcellenceCoachingHub-CourseBuilder/1.0 (https://excellencecoachinghub.com; education platform)';
const ALLOWED_MIME = /^image\/(jpeg|png|gif|webp|svg\+xml)$/;
const BLOCKED = /\b(logo|flag of|coat of arms|signature|icon|portrait of|nude|naked)\b/i;

function stripHtml(html) {
  return String(html || '').replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
}

async function searchImage(query, exclude = new Set()) {
  const { data } = await axios.get(API, {
    timeout: 8000,
    headers: { 'User-Agent': USER_AGENT },
    params: {
      action: 'query',
      format: 'json',
      generator: 'search',
      gsrsearch: `${query} filetype:bitmap|drawing`,
      gsrnamespace: 6,
      gsrlimit: 8,
      prop: 'imageinfo',
      iiprop: 'url|mime|size|extmetadata',
      iiurlwidth: 960,
      origin: '*',
    },
  });
  const pages = Object.values(data?.query?.pages || {}).sort((a, b) => (a.index || 0) - (b.index || 0));
  for (const p of pages) {
    const info = p.imageinfo?.[0];
    if (!info || !ALLOWED_MIME.test(info.mime || '')) continue;
    if ((info.width || 0) < 300) continue;
    if (BLOCKED.test(p.title || '')) continue;
    const url = info.thumburl || info.url;
    if (!url || exclude.has(url)) continue;
    const meta = info.extmetadata || {};
    return {
      url,
      width: info.thumbwidth || info.width,
      height: info.thumbheight || info.height,
      sourceUrl: info.descriptionurl,
      title: stripHtml(meta.ObjectName?.value) || String(p.title || '').replace(/^File:/, '').replace(/\.[a-z]+$/i, ''),
      author: stripHtml(meta.Artist?.value).slice(0, 120),
      license: stripHtml(meta.LicenseShortName?.value),
    };
  }
  return null;
}

/**
 * Resolve image requests into images. Never throws — a lesson without
 * pictures is better than a failed lesson.
 */
async function resolveImages(requests = []) {
  const out = [];
  const used = new Set();
  await Promise.all(requests.slice(0, 3).map(async (req, i) => {
    try {
      let img = await searchImage(req.query, used);
      // Retry with a shorter query (first 3 words) when nothing matched
      if (!img && req.query.split(/\s+/).length > 3) {
        img = await searchImage(req.query.split(/\s+/).slice(0, 3).join(' '), used);
      }
      if (img && !used.has(img.url)) {
        used.add(img.url);
        out[i] = { ...img, caption: req.caption, afterHeading: req.afterHeading, query: req.query };
      }
    } catch (err) {
      console.warn(`[CourseBuilder] image search failed for "${req.query}": ${err.message}`);
    }
  }));
  return out.filter(Boolean);
}

module.exports = { resolveImages, searchImage };
