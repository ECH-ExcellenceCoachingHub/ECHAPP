const { fetchJson } = require('./http');

/**
 * Licensed stock-media sources with official APIs. Every provider returns
 * candidates in one normalised shape:
 *
 *   { provider, id, kind: 'image'|'video', downloadUrl, width, height,
 *     durationSec, title, text, author, authorUrl, sourceUrl,
 *     license, licenseUrl, attributionRequired, bytes }
 *
 *   wikimedia — Wikimedia Commons (MediaWiki API). No key. Only CC0 / public
 *               domain / CC BY (and CC BY-SA when VIDEO_STOCK_ALLOW_SHARE_ALIKE=true).
 *   pexels    — Pexels API (PEXELS_API_KEY). Pexels licence: free to use, credit appreciated.
 *   pixabay   — Pixabay API (PIXABAY_API_KEY). Pixabay content licence; files must be
 *               downloaded to our storage (no hotlinking).
 *
 * Pinterest and similar sites are deliberately not supported: they have no
 * licence that allows reuse of other people's pins.
 */

const stripHtml = (s) => String(s || '').replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();
const slugText = (url) => {
  const m = String(url || '').match(/\/(?:photo|video)s?\/([a-z0-9-]+?)(?:-\d+)?\/?$/i);
  return m ? m[1].replace(/-/g, ' ') : '';
};

// ─── Wikimedia Commons ───────────────────────────────────────────────────────

/** Classify a Commons licence; null = not allowed for reuse in lessons. */
function commonsLicense(shortName, allowShareAlike) {
  const s = String(shortName || '').trim();
  if (/^cc0\b/i.test(s) || /public domain|^pd\b|^pd-/i.test(s)) return { license: s || 'Public domain', attributionRequired: false };
  if (/\b(nc|nd)\b/i.test(s)) return null; // non-commercial / no-derivatives
  if (/^cc[ -]by[ -]sa\b/i.test(s)) return allowShareAlike ? { license: s, attributionRequired: true, shareAlike: true } : null;
  if (/^cc[ -]by\b/i.test(s)) return { license: s, attributionRequired: true };
  return null;
}

function normalizeCommonsPage(page, kind, { allowShareAlike = false } = {}) {
  const info = page?.imageinfo?.[0];
  if (!info) return null;
  const meta = info.extmetadata || {};
  const v = (k) => meta[k]?.value;
  const lic = commonsLicense(v('LicenseShortName'), allowShareAlike);
  if (!lic) return null;
  const isVideo = /^video\//.test(info.mime || '') || info.mime === 'application/ogg';
  if ((kind === 'video') !== isVideo) return null;
  const title = String(page.title || '').replace(/^File:/, '').replace(/\.[a-z0-9]+$/i, '').replace(/_/g, ' ');
  return {
    provider: 'wikimedia',
    id: String(page.pageid),
    kind,
    downloadUrl: isVideo ? info.url : (info.thumburl || info.url),
    width: isVideo ? info.width : (info.thumbwidth || info.width),
    height: isVideo ? info.height : (info.thumbheight || info.height),
    durationSec: isVideo ? Number(info.duration) || null : null,
    bytes: info.size || null,
    title,
    text: [title, stripHtml(v('ObjectName')), stripHtml(v('ImageDescription')).slice(0, 400), stripHtml(v('Categories')).replace(/\|/g, ' ')].join(' '),
    author: stripHtml(v('Artist')).slice(0, 120) || 'Unknown author',
    authorUrl: null,
    sourceUrl: info.descriptionurl,
    licenseUrl: v('LicenseUrl') || null,
    providerLabel: 'Wikimedia Commons',
    ...lic,
  };
}

const wikimedia = {
  name: 'wikimedia',
  available: () => true,
  async search(query, { kind = 'image', perPage = 20, signal } = {}) {
    const params = new URLSearchParams({
      action: 'query', format: 'json', formatversion: '2',
      generator: 'search', gsrsearch: `${query} filetype:${kind === 'video' ? 'video' : 'bitmap'}`,
      gsrnamespace: '6', gsrlimit: String(perPage),
      prop: 'imageinfo', iiprop: 'url|size|mime|extmetadata', iiurlwidth: '1280',
      iiextmetadatafilter: 'LicenseShortName|LicenseUrl|Artist|ImageDescription|AttributionRequired|Categories|ObjectName',
    });
    // The MediaWiki API reports throttling and overload with HTTP 200 and an
    // "error" body; those are retried once after a pause, then reported as 429.
    let data;
    for (let attempt = 0; ; attempt++) {
      data = await fetchJson(`https://commons.wikimedia.org/w/api.php?${params}`, { signal });
      if (!data?.error) break;
      const code = String(data.error.code || 'error');
      const busy = /ratelimit|maxlag|throttl|busy/i.test(code);
      if (busy && attempt < 1) {
        await new Promise(r => setTimeout(r, parseInt(process.env.VIDEO_STOCK_BUSY_RETRY_MS || '3000', 10)));
        continue;
      }
      throw Object.assign(new Error(`Wikimedia API error: ${code}`), { status: busy ? 429 : 502 });
    }
    const allowShareAlike = String(process.env.VIDEO_STOCK_ALLOW_SHARE_ALIKE || 'false').toLowerCase() === 'true';
    return (data?.query?.pages || [])
      .sort((a, b) => (a.index || 0) - (b.index || 0))
      .map(p => normalizeCommonsPage(p, kind, { allowShareAlike }))
      .filter(Boolean);
  },
};

// ─── Pexels ──────────────────────────────────────────────────────────────────

function normalizePexelsPhoto(p) {
  if (!p?.src) return null;
  return {
    provider: 'pexels', id: String(p.id), kind: 'image',
    downloadUrl: p.src.large2x || p.src.large || p.src.original,
    width: p.width, height: p.height, durationSec: null, bytes: null,
    title: p.alt || slugText(p.url), text: `${p.alt || ''} ${slugText(p.url)}`,
    author: p.photographer || 'Pexels contributor', authorUrl: p.photographer_url || null,
    sourceUrl: p.url, license: 'Pexels License', licenseUrl: 'https://www.pexels.com/license/',
    attributionRequired: false, providerLabel: 'Pexels',
  };
}

function normalizePexelsVideo(v) {
  const files = (v?.video_files || []).filter(f => f.file_type === 'video/mp4' && f.link && f.width);
  if (!files.length) return null;
  const hd = files.filter(f => f.width >= 1280).sort((a, b) => a.width - b.width)[0];
  const pick = hd || files.sort((a, b) => b.width - a.width)[0];
  return {
    provider: 'pexels', id: String(v.id), kind: 'video',
    downloadUrl: pick.link, width: pick.width, height: pick.height, durationSec: v.duration || null, bytes: null,
    title: slugText(v.url), text: slugText(v.url),
    author: v.user?.name || 'Pexels contributor', authorUrl: v.user?.url || null,
    sourceUrl: v.url, license: 'Pexels License', licenseUrl: 'https://www.pexels.com/license/',
    attributionRequired: false, providerLabel: 'Pexels',
  };
}

const pexels = {
  name: 'pexels',
  available: () => !!process.env.PEXELS_API_KEY,
  async search(query, { kind = 'image', perPage = 15, signal } = {}) {
    const params = new URLSearchParams({ query, orientation: 'landscape', per_page: String(perPage) });
    if (kind === 'video') params.set('size', 'medium');
    const url = kind === 'video' ? `https://api.pexels.com/v1/videos/search?${params}` : `https://api.pexels.com/v1/search?${params}`;
    const data = await fetchJson(url, { signal, headers: { Authorization: process.env.PEXELS_API_KEY } });
    return kind === 'video'
      ? (data?.videos || []).map(normalizePexelsVideo).filter(Boolean)
      : (data?.photos || []).map(normalizePexelsPhoto).filter(Boolean);
  },
};

// ─── Pixabay ─────────────────────────────────────────────────────────────────

function normalizePixabayImage(h) {
  if (!h?.largeImageURL) return null;
  return {
    provider: 'pixabay', id: String(h.id), kind: 'image',
    downloadUrl: h.largeImageURL, width: h.imageWidth, height: h.imageHeight, durationSec: null, bytes: null,
    title: h.tags || '', text: h.tags || '',
    author: h.user || 'Pixabay contributor', authorUrl: h.user_id ? `https://pixabay.com/users/${h.user}-${h.user_id}/` : null,
    sourceUrl: h.pageURL, license: 'Pixabay Content License', licenseUrl: 'https://pixabay.com/service/license-summary/',
    attributionRequired: false, providerLabel: 'Pixabay',
  };
}

function normalizePixabayVideo(h) {
  const sizes = ['tiny', 'small', 'medium', 'large'].map(k => h?.videos?.[k]).filter(x => x?.url && x.width);
  if (!sizes.length) return null;
  const pick = sizes.filter(x => x.width >= 1280).sort((a, b) => a.width - b.width)[0] || sizes.sort((a, b) => b.width - a.width)[0];
  return {
    provider: 'pixabay', id: String(h.id), kind: 'video',
    downloadUrl: pick.url, width: pick.width, height: pick.height, durationSec: h.duration || null, bytes: pick.size || null,
    title: h.tags || '', text: h.tags || '',
    author: h.user || 'Pixabay contributor', authorUrl: h.user_id ? `https://pixabay.com/users/${h.user}-${h.user_id}/` : null,
    sourceUrl: h.pageURL, license: 'Pixabay Content License', licenseUrl: 'https://pixabay.com/service/license-summary/',
    attributionRequired: false, providerLabel: 'Pixabay',
  };
}

const pixabay = {
  name: 'pixabay',
  available: () => !!process.env.PIXABAY_API_KEY,
  async search(query, { kind = 'image', perPage = 20, signal } = {}) {
    const params = new URLSearchParams({ key: process.env.PIXABAY_API_KEY, q: query.slice(0, 100), safesearch: 'true', per_page: String(Math.max(3, perPage)) });
    if (kind === 'image') { params.set('image_type', 'photo'); params.set('orientation', 'horizontal'); params.set('min_width', '1280'); }
    const url = kind === 'video' ? `https://pixabay.com/api/videos/?${params}` : `https://pixabay.com/api/?${params}`;
    const data = await fetchJson(url, { signal });
    return (data?.hits || []).map(kind === 'video' ? normalizePixabayVideo : normalizePixabayImage).filter(Boolean);
  },
};

const PROVIDERS = { wikimedia, pexels, pixabay };

module.exports = {
  PROVIDERS,
  commonsLicense,
  normalizeCommonsPage,
  normalizePexelsPhoto,
  normalizePexelsVideo,
  normalizePixabayImage,
  normalizePixabayVideo,
};
