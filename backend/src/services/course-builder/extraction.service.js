const path = require('path');
const mammoth = require('mammoth');

// Polyfill for DOMMatrix in Node.js environment (pdfjs needs it)
if (typeof DOMMatrix === 'undefined') {
  global.DOMMatrix = require('dommatrix');
}

// A page with fewer characters than this is treated as an image-only page.
const SCANNED_PAGE_CHARS = 40;
// Pseudo-page size for formats that have no real pages (DOCX / TXT).
const SEGMENT_CHARS = 3500;
const MAX_HEADINGS = 2500;

const HEADING_PATTERN = /^(chapter|unit|part|module|lesson|section|topic)\s+([0-9]+|[ivxlc]+)\b/i;
const NUMBERED_HEADING_PATTERN = /^(\d{1,2})(\.\d{1,2}){0,2}\.?\s+[A-Z]/;

/**
 * Extract a book into pages + structural hints.
 *
 * @param {Buffer} buffer
 * @param {string} mimeType
 * @param {(done:number,total:number)=>void} onProgress
 * @returns {Promise<{pages:{n:number,text:string}[], bookmarks:any[], headings:any[], pageUnit:string, isScanned:boolean}>}
 */
async function extractBook(buffer, mimeType, fileName = '', onProgress = () => {}) {
  const lower = (mimeType || '').toLowerCase();
  const name = (fileName || '').toLowerCase();

  if (lower.includes('pdf') || name.endsWith('.pdf')) {
    return extractPdf(buffer, onProgress);
  }
  if (lower.includes('officedocument') || lower.includes('msword') || name.endsWith('.docx') || name.endsWith('.doc')) {
    return extractDocx(buffer, onProgress);
  }
  // Plain text / markdown
  return segmentPlainText(buffer.toString('utf8'), onProgress);
}

// ─── PDF ──────────────────────────────────────────────────────────────────────

async function extractPdf(buffer, onProgress) {
  const { getDocument } = await import('pdfjs-dist/legacy/build/pdf.mjs');
  const pdf = await getDocument({
    data: new Uint8Array(buffer),
    isEvalSupported: false,
    standardFontDataUrl: `${path.join(path.dirname(require.resolve('pdfjs-dist/package.json')), 'standard_fonts').split(path.sep).join('/')}/`,
  }).promise;

  const pages = [];
  const lineCandidates = []; // {page, text, size}
  const sizeHistogram = new Map(); // font size → chars

  for (let i = 1; i <= pdf.numPages; i++) {
    const page = await pdf.getPage(i);
    const content = await page.getTextContent();
    const lines = buildLines(content.items);
    for (const line of lines) {
      const key = Math.round(line.size * 2) / 2;
      sizeHistogram.set(key, (sizeHistogram.get(key) || 0) + line.text.length);
      if (line.text.length >= 1 && line.text.length <= 140) {
        lineCandidates.push({ page: i, text: line.text, size: line.size });
      }
    }
    pages.push({ n: i, text: lines.map(l => l.text).join('\n') });
    page.cleanup();
    if (i % 5 === 0 || i === pdf.numPages) onProgress(i, pdf.numPages);
  }

  const bookmarks = await readBookmarks(pdf).catch(() => []);
  await pdf.destroy();

  const bodySize = modeOf(sizeHistogram) || 10;
  const headings = scoreHeadings(lineCandidates, bodySize);

  const textPages = pages.filter(p => p.text.replace(/\s/g, '').length >= SCANNED_PAGE_CHARS).length;
  const isScanned = pages.length > 0 && textPages / pages.length < 0.3;

  return { pages, bookmarks, headings, pageUnit: 'page', isScanned };
}

/** Rebuild visual lines from pdfjs text items (they arrive as fragments). */
function buildLines(items) {
  const lines = [];
  let current = null;
  for (const item of items) {
    if (typeof item.str !== 'string') continue;
    const y = item.transform ? item.transform[5] : 0;
    const size = Math.abs(item.height || (item.transform ? item.transform[3] : 0)) || 0;
    if (!current || Math.abs(current.y - y) > Math.max(2, size * 0.5)) {
      if (current && current.text.trim()) lines.push(finishLine(current));
      current = { y, text: '', size: 0 };
    }
    current.text += item.str;
    if (item.str.trim()) current.size = Math.max(current.size, size);
    if (item.hasEOL) {
      if (current.text.trim()) lines.push(finishLine(current));
      current = null;
    }
  }
  if (current && current.text.trim()) lines.push(finishLine(current));
  return lines;
}

function finishLine(l) {
  return { text: l.text.replace(/\s+/g, ' ').trim(), size: l.size };
}

function modeOf(histogram) {
  let best = null;
  let bestCount = -1;
  for (const [k, v] of histogram) {
    if (v > bestCount) { best = k; bestCount = v; }
  }
  return best;
}

function scoreHeadings(rawLines, bodySize) {
  const lines = mergeWrappedHeadings(rawLines, bodySize);
  const out = [];
  for (const l of lines) {
    if (l.text.length < 3) continue;
    let score = 0;
    const ratio = bodySize ? l.size / bodySize : 1;
    if (ratio >= 1.6) score += 3;
    else if (ratio >= 1.25) score += 2;
    else if (ratio >= 1.1) score += 1;
    if (HEADING_PATTERN.test(l.text)) score += 3;
    if (NUMBERED_HEADING_PATTERN.test(l.text)) score += 2;
    if (/[.:;,]$/.test(l.text) && !HEADING_PATTERN.test(l.text)) score -= 1;
    if (/^\d+$/.test(l.text)) score = 0; // page numbers
    if (l.text.split(' ').length > 16) score -= 2;
    if (score >= 2) out.push({ page: l.page, text: l.text, size: Math.round(l.size * 10) / 10, score });
  }
  return dedupeRunningHeaders(out).slice(0, MAX_HEADINGS);
}

/** A long heading set in a large font wraps onto several lines — join them back. */
function mergeWrappedHeadings(lines, bodySize) {
  const out = [];
  for (const l of lines) {
    const prev = out[out.length - 1];
    const large = bodySize && l.size / bodySize >= 1.25;
    if (prev && large && prev.page === l.page && Math.abs(prev.size - l.size) < 0.5 &&
        !HEADING_PATTERN.test(l.text) && !NUMBERED_HEADING_PATTERN.test(l.text) &&
        prev.text.length + l.text.length < 140 && !/[.:;!?]$/.test(prev.text)) {
      prev.text = `${prev.text} ${l.text}`;
      continue;
    }
    out.push({ ...l });
  }
  return out;
}

/** Running headers repeat on most pages — they are not real headings. */
function dedupeRunningHeaders(headings) {
  const counts = new Map();
  for (const h of headings) counts.set(h.text, (counts.get(h.text) || 0) + 1);
  return headings.filter(h => counts.get(h.text) <= 3);
}

async function readBookmarks(pdf) {
  const outline = await pdf.getOutline();
  if (!outline || !outline.length) return [];
  const flat = [];

  const resolvePage = async (dest) => {
    try {
      const explicit = typeof dest === 'string' ? await pdf.getDestination(dest) : dest;
      if (!explicit || !explicit[0]) return null;
      const ref = explicit[0];
      const index = typeof ref === 'number' ? ref : await pdf.getPageIndex(ref);
      return index + 1;
    } catch (_) {
      return null;
    }
  };

  const walk = async (nodes, depth) => {
    for (const node of nodes) {
      if (flat.length > 1500) return;
      const page = node.dest ? await resolvePage(node.dest) : null;
      if (node.title && page) flat.push({ title: node.title.trim(), page, depth });
      if (node.items && node.items.length && depth < 3) await walk(node.items, depth + 1);
    }
  };
  await walk(outline, 0);
  return flat;
}

// ─── DOCX ─────────────────────────────────────────────────────────────────────

async function extractDocx(buffer, onProgress) {
  const { value: html } = await mammoth.convertToHtml({ buffer });
  // Turn block-level HTML into lines, remembering heading levels.
  const blocks = [];
  const re = /<(h[1-6]|p|li|td|th)[^>]*>([\s\S]*?)<\/\1>/gi;
  let m;
  while ((m = re.exec(html)) !== null) {
    const text = decodeEntities(m[2].replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ').trim();
    if (!text) continue;
    const tag = m[1].toLowerCase();
    blocks.push({ text: tag === 'li' ? `• ${text}` : text, heading: tag.startsWith('h') ? Number(tag[1]) : 0 });
  }

  const pages = [];
  const headings = [];
  let buf = [];
  let len = 0;
  const flush = () => {
    if (!buf.length) return;
    pages.push({ n: pages.length + 1, text: buf.join('\n') });
    buf = [];
    len = 0;
  };
  for (const b of blocks) {
    // Start a new segment at top-level headings so chapters don't straddle segments
    if (b.heading && b.heading <= 2 && len > SEGMENT_CHARS * 0.3) flush();
    if (b.heading) {
      headings.push({ page: pages.length + 1, text: b.text, size: 20 - b.heading * 2, score: 6 - b.heading });
    }
    buf.push(b.heading ? `${'#'.repeat(b.heading)} ${b.text}` : b.text);
    len += b.text.length;
    if (len >= SEGMENT_CHARS) flush();
  }
  flush();
  onProgress(pages.length, pages.length);

  if (!pages.length) {
    const { value } = await mammoth.extractRawText({ buffer });
    return segmentPlainText(value, onProgress);
  }
  return { pages, bookmarks: [], headings: headings.slice(0, MAX_HEADINGS), pageUnit: 'segment', isScanned: false };
}

function decodeEntities(s) {
  return s
    .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&nbsp;/g, ' ');
}

// ─── Plain text ───────────────────────────────────────────────────────────────

function segmentPlainText(text, onProgress) {
  const lines = text.split(/\r?\n/);
  const pages = [];
  const headings = [];
  let buf = [];
  let len = 0;
  for (const raw of lines) {
    const line = raw.trim();
    if (!line) continue;
    const md = line.match(/^(#{1,4})\s+(.*)$/);
    if (md || HEADING_PATTERN.test(line) || (NUMBERED_HEADING_PATTERN.test(line) && line.length < 100)) {
      headings.push({ page: pages.length + 1, text: md ? md[2] : line, size: md ? 20 - md[1].length * 2 : 14, score: md ? 6 - md[1].length : 3 });
    }
    buf.push(line);
    len += line.length;
    if (len >= SEGMENT_CHARS) {
      pages.push({ n: pages.length + 1, text: buf.join('\n') });
      buf = [];
      len = 0;
    }
  }
  if (buf.length) pages.push({ n: pages.length + 1, text: buf.join('\n') });
  onProgress(pages.length, pages.length);
  return { pages, bookmarks: [], headings: headings.slice(0, MAX_HEADINGS), pageUnit: 'segment', isScanned: false };
}

// ─── OCR for scanned PDFs (Gemini reads the PDF images directly) ─────────────

const OCR_PAGES_PER_CALL = 12;

/**
 * Transcribe a scanned PDF with Gemini. Requires GEMINI_API_KEY.
 * Returns pages in the same shape as extractPdf.
 */
async function ocrPdfWithGemini(buffer, fileName, pageCount, onProgress = () => {}, log = () => {}) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('This looks like a scanned PDF. Set GEMINI_API_KEY on the server to enable OCR, or upload a text-based PDF/DOCX.');
  }
  const { GoogleGenerativeAI } = require('@google/generative-ai');
  const { GoogleAIFileManager, FileState } = require('@google/generative-ai/server');
  const modelName = process.env.GEMINI_OCR_MODEL || 'gemini-2.5-flash';

  const fileManager = new GoogleAIFileManager(apiKey);
  const upload = await fileManager.uploadFile(buffer, { mimeType: 'application/pdf', displayName: fileName || 'book.pdf' });
  let file = upload.file;
  for (let i = 0; i < 60 && file.state === FileState.PROCESSING; i++) {
    await sleep(2000);
    file = await fileManager.getFile(file.name);
  }
  if (file.state !== FileState.ACTIVE) throw new Error('OCR service could not process the PDF');

  const model = new GoogleGenerativeAI(apiKey).getGenerativeModel({ model: modelName });
  const ranges = [];
  for (let s = 1; s <= pageCount; s += OCR_PAGES_PER_CALL) ranges.push([s, Math.min(pageCount, s + OCR_PAGES_PER_CALL - 1)]);

  const pages = new Map();
  let done = 0;
  const worker = async (range) => {
    const [from, to] = range;
    const prompt = `Transcribe pages ${from} to ${to} of this PDF exactly as written (OCR). ` +
      `Start each page with a line "=== PAGE n ===" where n is the PDF page number. ` +
      `Keep headings on their own lines, keep tables as plain rows separated by " | ", ` +
      `write formulas in plain text. Do not summarise, translate or add commentary.`;
    let text = '';
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        const result = await model.generateContent([
          { fileData: { mimeType: file.mimeType, fileUri: file.uri } },
          { text: prompt },
        ]);
        text = result.response.text();
        break;
      } catch (e) {
        log(`OCR pages ${from}-${to} attempt ${attempt} failed: ${e.message}`, 'warn');
        await sleep(3000 * attempt);
      }
    }
    const parts = text.split(/^=== PAGE (\d+) ===\s*$/m);
    for (let i = 1; i < parts.length; i += 2) {
      const n = Number(parts[i]);
      if (n >= from && n <= to) pages.set(n, (parts[i + 1] || '').trim());
    }
    done += to - from + 1;
    onProgress(done, pageCount);
  };
  await runPool(ranges, 3, worker);
  fileManager.deleteFile(file.name).catch(() => {});

  const out = [];
  for (let n = 1; n <= pageCount; n++) out.push({ n, text: pages.get(n) || '' });
  const lineCandidates = [];
  for (const p of out) {
    for (const line of p.text.split('\n')) {
      const t = line.trim();
      if (t.length >= 3 && t.length <= 140) lineCandidates.push({ page: p.n, text: t, size: 10 });
    }
  }
  return { pages: out, headings: scoreHeadings(lineCandidates, 10) };
}

async function runPool(items, concurrency, fn) {
  let i = 0;
  const workers = Array.from({ length: Math.min(concurrency, items.length) }, async () => {
    while (i < items.length) {
      const item = items[i++];
      await fn(item);
    }
  });
  await Promise.all(workers);
}

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

module.exports = { extractBook, ocrPdfWithGemini, runPool, sleep };
