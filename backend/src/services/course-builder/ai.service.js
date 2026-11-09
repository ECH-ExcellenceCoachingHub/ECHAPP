const GrokService = require('../grok_service');
const { sleep, runPool } = require('./extraction.service');

// Upper bound of source characters sent with a single generation request.
const LESSON_SOURCE_CHARS = 14000;
// Book text per lesson-writing request. Longer lessons are written in parts,
// so every page is sent in full instead of being trimmed.
const SECTION_SOURCE_CHARS = 12000;
const OUTLINE_INPUT_CHARS = 24000;

const VISUAL_TYPES = ['flow', 'comparison', 'timeline', 'hierarchy', 'chart', 'cycle'];
const QUESTION_TYPES = ['mcq', 'true_false', 'short_answer', 'calculation', 'scenario'];

// ─── Low-level JSON completion with retry / rate-limit handling ──────────────

let jsonModeSupported = true;

async function completeJson(prompt, { maxTokens = 4096, temperature = 0.3, system, onUsage } = {}) {
  if (!GrokService.isConfigured()) {
    throw new Error('AI is not configured on the server (GROQ_API_KEY missing).');
  }
  const messages = [];
  messages.push({
    role: 'system',
    content: system || 'You are an expert instructional designer and examiner. You only use facts from the provided source text. You always answer with a single valid JSON object and nothing else.',
  });
  messages.push({ role: 'user', content: prompt });

  let lastError;
  for (let attempt = 1; attempt <= 5; attempt++) {
    const model = await GrokService.pickModel();
    if (!model) {
      throw new Error('All AI models have reached their daily usage limit. Please try again later.');
    }
    try {
      const params = {
        model,
        messages,
        temperature,
        max_tokens: maxTokens,
      };
      if (jsonModeSupported) params.response_format = { type: 'json_object' };
      const completion = await GrokService._createCompletion(params);
      if (typeof onUsage === 'function' && completion.usage) {
        try { onUsage({ ...completion.usage, model: params.model, requestId: completion.id || null }); } catch (_) { /* never break generation */ }
      }
      const raw = completion.choices?.[0]?.message?.content || '';
      if (!raw.trim()) throw new Error('Empty response from AI');
      return parseJson(raw);
    } catch (err) {
      lastError = err;
      const status = err.status || err.statusCode;
      if (status === 400 && jsonModeSupported && /response_format|json/i.test(err.message || '')) {
        jsonModeSupported = false; // model doesn't support JSON mode — retry without it
        continue;
      }
      if (status === 404 || /decommissioned|model_not_found|does not exist/i.test(err.message || '')) {
        GrokService.markExhausted(model, 24 * 60 * 60 * 1000);
        continue;
      }
      if (status === 429 || status >= 500 || /rate limit|timeout|ECONNRESET|Empty response|JSON/i.test(err.message || '')) {
        const retryAfterMs = retryAfterOf(err);
        // A daily quota (or any long wait) won't clear by retrying — move on to the next model
        if (status === 429 && (/per day/i.test(err.message || '') || retryAfterMs > 45000)) {
          GrokService.markExhausted(model, retryAfterMs || 60 * 60 * 1000);
          continue;
        }
        await sleep(retryAfterMs ? Math.min(retryAfterMs, 45000) : Math.min(1500 * 2 ** (attempt - 1), 30000));
        continue;
      }
      throw err;
    }
  }
  throw lastError;
}

/** Wait requested by a 429, in ms: the Retry-After header, else Groq's "try again in 9m40.17s". */
function retryAfterOf(err) {
  const header = Number(err.headers?.['retry-after']);
  if (Number.isFinite(header) && header > 0) return header * 1000;
  const m = /try again in (?:(\d+)h)?(?:(\d+)m)?(?:([\d.]+)s)?/i.exec(err.message || '');
  if (!m || !(m[1] || m[2] || m[3])) return 0;
  return ((Number(m[1]) || 0) * 3600 + (Number(m[2]) || 0) * 60 + (Number(m[3]) || 0)) * 1000;
}

function parseJson(raw) {
  try { return JSON.parse(raw); } catch (_) { /* fall through */ }
  const stripped = raw.replace(/^```(?:json)?\s*/i, '').replace(/\s*```\s*$/, '').trim();
  try { return JSON.parse(stripped); } catch (_) { /* fall through */ }
  const start = stripped.indexOf('{');
  const end = stripped.lastIndexOf('}');
  if (start >= 0 && end > start) {
    return JSON.parse(stripped.slice(start, end + 1));
  }
  throw new Error('AI returned invalid JSON');
}

// ─── Source text helpers ─────────────────────────────────────────────────────

/** Join pages with [[Page n]] markers, fitting into maxChars by trimming each page evenly. */
function pagesToSource(pages, maxChars = LESSON_SOURCE_CHARS, unit = 'page') {
  if (!pages.length) return '';
  const label = unit === 'segment' ? 'Part' : 'Page';
  const total = pages.reduce((s, p) => s + p.text.length, 0);
  const perPage = total > maxChars ? Math.floor(maxChars / pages.length) : Infinity;
  return pages
    .map(p => `[[${label} ${p.n}]]\n${perPage === Infinity ? p.text : p.text.slice(0, perPage)}`)
    .join('\n\n');
}

function difficultyCounts(count, mix) {
  const weights = { easy: mix?.easy ?? 30, medium: mix?.medium ?? 50, hard: mix?.hard ?? 20 };
  const sum = weights.easy + weights.medium + weights.hard || 1;
  const raw = Object.entries(weights).map(([k, w]) => ({ k, v: (count * w) / sum }));
  const counts = Object.fromEntries(raw.map(r => [r.k, Math.floor(r.v)]));
  let left = count - Object.values(counts).reduce((a, b) => a + b, 0);
  raw.sort((a, b) => (b.v % 1) - (a.v % 1));
  for (const r of raw) { if (left <= 0) break; counts[r.k]++; left--; }
  return counts;
}

// ─── Outline ─────────────────────────────────────────────────────────────────

// Books of any length are outlined in two passes so no request ever has to
// hold the whole book: pass 1 finds every chapter from a budgeted digest of the
// WHOLE book (bookmarks, strongest headings, table of contents); pass 2 designs
// the lessons of each chapter from that chapter's own headings.

const CHAPTER_PATTERN = /\b(chapter|unit|module|part|topic|theme)\s+([0-9]{1,3}|[ivxlc]{1,7})\b/i;
const CHAPTER_LESSON_CHARS = 12000;
const OUTLINE_CONCURRENCY = 3;

/**
 * Keep the highest-priority items that fit in maxChars, returned in page order.
 * Unlike cutting a page-sorted list, this never drops the end of the book.
 */
function fitByPriority(items, maxChars, toLine, priority) {
  const ranked = items
    .map((item, i) => ({ item, i, line: toLine(item), p: priority(item) }))
    .sort((a, b) => b.p - a.p || a.i - b.i);
  const chosen = [];
  let size = 0;
  for (const r of ranked) {
    if (size + r.line.length + 1 > maxChars) continue;
    chosen.push(r);
    size += r.line.length + 1;
  }
  return chosen.sort((a, b) => a.i - b.i).map(r => r.line).join('\n');
}

function romanToInt(s) {
  const v = { i: 1, v: 5, x: 10, l: 50, c: 100 };
  let total = 0;
  const t = s.toLowerCase();
  for (let i = 0; i < t.length; i++) {
    const cur = v[t[i]]; const next = v[t[i + 1]] || 0;
    if (!cur) return null;
    total += cur < next ? -cur : cur;
  }
  return total || null;
}

/** "Unit 11: …" / "CHAPTER XI" / "11. …" → 11 */
function chapterNumber(title) {
  const m = CHAPTER_PATTERN.exec(title || '');
  if (m) return /^\d+$/.test(m[2]) ? Number(m[2]) : romanToInt(m[2]);
  const d = /^\s*(\d{1,3})(?:[.:)\s]|$)(?!\d)/.exec(title || '');
  return d ? Number(d[1]) : null;
}

/** Table-of-contents pages: "Contents" or many lines ending in a page number. */
function findTocPages(pages) {
  const scan = pages.slice(0, Math.min(pages.length, 40));
  const toc = scan.filter((p) => {
    const lines = (p.text || '').split('\n');
    const numbered = lines.filter(l => /(\.{3,}|…|\s)\s*\d{1,4}\s*$/.test(l) && /[a-z]{3}/i.test(l)).length;
    return /\b(table of )?contents\b/i.test(p.text || '') ? numbered >= 3 : numbered >= 6;
  });
  // A TOC spans consecutive pages — include the ones between the first and last hit.
  if (!toc.length) return [];
  const first = toc[0].n; const last = toc[toc.length - 1].n;
  return pages.filter(p => p.n >= first && p.n <= Math.min(last, first + 12));
}

async function generateOutline({ fileName, pages, bookmarks, headings, unit, log = () => {} }) {
  const skeleton = await generateChapterSkeleton({ fileName, pages, bookmarks, headings, unit });
  let chapters = (Array.isArray(skeleton.chapters) ? skeleton.chapters : [])
    .filter(c => c && c.title && Number.isFinite(Number(c.pageStart)))
    .map(c => ({ title: String(c.title).trim(), summary: String(c.summary || '').trim(), pageStart: Math.round(Number(c.pageStart)) }))
    .sort((a, b) => a.pageStart - b.pageStart);

  const added = addMissingChapters(chapters, headings, pages.length);
  if (added.length) {
    log(`Added ${added.length} chapter(s) the AI missed: ${added.map(c => c.title).join(' | ')}`, 'warn');
    chapters = [...chapters, ...added].sort((a, b) => a.pageStart - b.pageStart);
  }
  if (!chapters.length) return { ...skeleton, chapters: [] };
  log(`Found ${chapters.length} chapters — designing lessons chapter by chapter`);

  await runPool(chapters.map((c, i) => i), OUTLINE_CONCURRENCY, async (i) => {
    const c = chapters[i];
    const pageEnd = i + 1 < chapters.length ? Math.max(c.pageStart, chapters[i + 1].pageStart - 1) : pages.length;
    try {
      c.lessons = await generateChapterLessons({ chapter: c, pageEnd, pages, bookmarks, headings, unit, skeleton });
    } catch (err) {
      log(`Lessons for "${c.title}" fell back to detected headings (${err.message})`, 'warn');
      c.lessons = numberedSections(headings, c.pageStart, pageEnd + 1);
    }
  });

  return { ...skeleton, chapters };
}

/** Pass 1: every chapter of the whole book, with its start page. */
async function generateChapterSkeleton({ fileName, pages, bookmarks, headings, unit }) {
  const label = unit === 'segment' ? 'Part' : 'Page';
  const lc = label.toLowerCase();
  const budget = OUTLINE_INPUT_CHARS;

  const bookmarkText = bookmarks.length
    ? fitByPriority(bookmarks, budget * 0.3, b => `${'  '.repeat(b.depth)}- ${b.title} (${lc} ${b.page})`, b => -b.depth)
    : '';
  // Chapter-like headings ("Unit 12 …") always make it in, wherever they are in the book.
  const headingText = fitByPriority(
    headings.slice().sort((a, b) => a.page - b.page),
    bookmarkText ? budget * 0.3 : budget * 0.45,
    h => `p${h.page} [s${h.score}] ${h.text}`,
    h => h.score + (CHAPTER_PATTERN.test(h.text) ? 10 : 0),
  );
  const tocPages = findTocPages(pages);
  const front = tocPages.length ? [...pages.slice(0, 2).filter(p => p.n < tocPages[0].n), ...tocPages] : pages.slice(0, 8);
  const frontMatter = pagesToSource(front, budget * 0.35, unit);

  const prompt = `Analyse the structure of this book and list ALL of its chapters.

FILE: ${fileName}
TOTAL ${label.toUpperCase()}S: ${pages.length}

PDF BOOKMARKS (most reliable when present):
${bookmarkText || '(none)'}

HEADING CANDIDATES FROM THE WHOLE BOOK (p = ${lc} number, s = heading score, higher is more likely a heading):
${headingText || '(none)'}

FRONT MATTER / TABLE OF CONTENTS:
${frontMatter}

TASK:
- Identify the book title, subject and level.
- List EVERY real chapter / unit / module from the first to the last one in the book — the book is ${pages.length} ${lc}s long, so chapters continue until near the end. Do not stop early and do not merge chapters. If the table of contents lists 13 units, return 13 chapters.
- Skip cover, preface, acknowledgements, index, bibliography, glossary and answers appendix.
- pageStart is the ${lc} number in THIS FILE where the chapter starts. The printed numbers in the table of contents are often offset from file ${lc}s — prefer the heading candidates' p-numbers, and when only the TOC has a chapter, apply the same offset you see for the other chapters.
- Keep the book's own numbering and wording in titles (e.g. "Unit 11: Public Finance").

Return JSON:
{
  "bookTitle": "...",
  "subject": "...",
  "level": "beginner | intermediate | advanced",
  "description": "2-3 sentence course description",
  "chapters": [ { "title": "Unit 1: ...", "summary": "one sentence", "pageStart": 5 } ]
}`;

  return completeJson(prompt, { maxTokens: 6000, temperature: 0.1 });
}

/** Pass 2: the lessons of one chapter, from that chapter's own headings. */
async function generateChapterLessons({ chapter, pageEnd, pages, bookmarks, headings, unit, skeleton }) {
  const label = unit === 'segment' ? 'Part' : 'Page';
  const lc = label.toLowerCase();
  const inRange = x => x.page >= chapter.pageStart && x.page <= pageEnd;

  const marks = bookmarks.filter(inRange);
  const bookmarkText = marks.length
    ? fitByPriority(marks, CHAPTER_LESSON_CHARS * 0.3, b => `${'  '.repeat(b.depth)}- ${b.title} (${lc} ${b.page})`, b => -b.depth)
    : '';
  const headingText = fitByPriority(
    headings.filter(inRange).sort((a, b) => a.page - b.page),
    CHAPTER_LESSON_CHARS * 0.55,
    h => `p${h.page} [s${h.score}] ${h.text}`,
    h => h.score,
  );
  const opening = pagesToSource(pages.slice(chapter.pageStart - 1, chapter.pageStart + 1), CHAPTER_LESSON_CHARS * 0.15, unit);

  const prompt = `Design the lessons of ONE chapter of a course built from a book.

BOOK: ${skeleton.bookTitle || ''} (${skeleton.subject || ''})
CHAPTER: ${chapter.title}
CHAPTER ${label.toUpperCase()}S: ${chapter.pageStart}-${pageEnd}

BOOKMARKS IN THIS CHAPTER:
${bookmarkText || '(none)'}

HEADING CANDIDATES IN THIS CHAPTER (p = ${lc} number, s = heading score):
${headingText || '(none)'}

CHAPTER OPENING:
${opening}

TASK:
- Define the lessons of this chapter from its sections/topics, in order. A lesson should cover roughly 2-12 ${lc}s; merge tiny sections, split huge ones.
- Every pageStart must be between ${chapter.pageStart} and ${pageEnd}; use the heading candidates' p-numbers.
- Keep the book's own numbering in titles when it exists (e.g. "11.2 Sources of Government Revenue").
- Skip end-of-chapter exercises/assessment sections as separate lessons.

Return JSON: { "lessons": [ { "title": "...", "pageStart": ${chapter.pageStart} } ] }`;

  const raw = await completeJson(prompt, { maxTokens: 3000, temperature: 0.1 });
  return (Array.isArray(raw.lessons) ? raw.lessons : []).filter(l => l && l.title);
}

/**
 * Safety net: chapter-like headings ("Unit 12 …") whose number is missing from
 * the AI's chapter list are added back, so a long book never loses its end.
 */
function addMissingChapters(chapters, headings, pageCount) {
  const heads = headings.filter(h => h.score >= 4 && CHAPTER_PATTERN.test(h.text));
  if (heads.length < 2) return [];
  // Only the keyword the book actually uses for chapters ("Unit", "Chapter" …)
  const counts = {};
  for (const h of heads) { const k = CHAPTER_PATTERN.exec(h.text)[1].toLowerCase(); counts[k] = (counts[k] || 0) + 1; }
  const keyword = Object.entries(counts).sort((a, b) => b[1] - a[1])[0][0];
  const afterToc = chapters.length ? Math.min(...chapters.map(c => c.pageStart)) : 1;

  const known = new Set(chapters.map(c => chapterNumber(c.title)).filter(n => n != null));
  const best = new Map();
  for (const h of heads) {
    if (CHAPTER_PATTERN.exec(h.text)[1].toLowerCase() !== keyword || h.page < afterToc) continue;
    const n = chapterNumber(h.text);
    if (n == null || known.has(n)) continue;
    const cur = best.get(n);
    if (!cur || h.score > cur.score || (h.score === cur.score && h.page > cur.page)) best.set(n, h);
  }
  const taken = new Set(chapters.map(c => c.pageStart));
  return [...best.values()]
    .filter(h => !taken.has(h.page) && h.page <= pageCount)
    .map(h => ({ title: h.text.slice(0, 200), summary: '', pageStart: h.page }));
}

function numberedSections(headings, from, to) {
  return headings
    .filter(x => x.page >= from && x.page < to && /^\d+\.\d+\s/.test(x.text) && !/^\d+\.\d+\.\d+/.test(x.text))
    .map(x => ({ title: x.text, pageStart: x.page }));
}

// ─── Lesson content ──────────────────────────────────────────────────────────

const VISUAL_SPEC = `"visuals": [   // 0-3 items. Only when the source genuinely supports it. Pick the best fitting type:
    { "type": "flow", "title": "...", "steps": [ { "label": "...", "detail": "..." } ] },              // processes, procedures, sequences
    { "type": "cycle", "title": "...", "steps": [ { "label": "...", "detail": "..." } ] },             // repeating cycles
    { "type": "comparison", "title": "...", "columns": ["Aspect","A","B"], "rows": [["...","...","..."]] }, // compare / contrast, classifications
    { "type": "timeline", "title": "...", "events": [ { "label": "1990", "detail": "..." } ] },       // history, chronology
    { "type": "hierarchy", "title": "...", "root": "...", "children": [ { "label": "...", "children": [ { "label": "..." } ] } ] }, // concept maps, types/categories
    { "type": "chart", "title": "...", "chartType": "bar | pie | line", "labels": ["..."], "series": [ { "name": "...", "values": [1,2] } ], "caption": "..." } // ONLY with numbers stated in the source
  ]`;

const ACTIVITY_SPEC = `"activities": [   // 2-3 short interactive practice activities built ONLY from this lesson's content. Mix the types:
    { "type": "match", "title": "Match each term to its meaning", "pairs": [ { "left": "term", "right": "meaning" } ] },            // 3-6 pairs
    { "type": "order", "title": "Put the steps in the right order", "items": ["first", "second", "third"] },                        // 3-7 items IN THE CORRECT ORDER
    { "type": "categorize", "title": "Sort each item into the right group", "categories": [ { "name": "Group A", "items": ["...", "..."] } ] }, // 2-4 groups, 2-5 items each
    { "type": "fill_blanks", "title": "Complete the sentences", "text": "The [[north]] is opposite the [[south]].", "distractors": ["east"] } // 2-5 blanks in [[double brackets]]
  ]`;

const IMAGE_SPEC = `"images": [   // 1-3 real photos/maps/diagrams a student would benefit from seeing. They are searched on Wikimedia Commons.
    { "query": "2-5 concrete English search words, e.g. compass rose cardinal directions", "caption": "what the student should notice", "afterHeading": "exact ## heading in notes it belongs under" }
  ]`;

/** Split pages into parts of at most maxChars, keeping whole pages (a huge page is cut at paragraph breaks). */
function splitIntoParts(pages, maxChars = SECTION_SOURCE_CHARS) {
  const parts = [];
  let current = [];
  let size = 0;
  for (const p of pages) {
    for (const text of chunkText(p.text || '', maxChars)) {
      if (current.length && size + text.length > maxChars) {
        parts.push(current);
        current = [];
        size = 0;
      }
      current.push({ n: p.n, text });
      size += text.length;
    }
  }
  if (current.length) parts.push(current);
  return parts;
}

function chunkText(text, maxChars) {
  const chunks = [];
  let rest = text;
  while (rest.length > maxChars) {
    let cut = rest.lastIndexOf('\n', maxChars);
    if (cut < maxChars / 2) cut = rest.lastIndexOf(' ', maxChars);
    if (cut < maxChars / 2) cut = maxChars;
    chunks.push(rest.slice(0, cut));
    rest = rest.slice(cut).trimStart();
  }
  chunks.push(rest);
  return chunks;
}

function wordCount(text) {
  return (String(text || '').match(/\S+/g) || []).length;
}

/** The notes should be roughly as long as the book text they teach — a full lesson, not a summary. */
function minNotesWords(pages) {
  const words = pages.reduce((n, p) => n + wordCount(p.text), 0);
  return Math.max(500, Math.min(2800, Math.round(words * 0.9)));
}

function lessonHeader(job, chapterTitle, lessonTitle, siblingTitles) {
  const o = job.options || {};
  return `BOOK: ${job.outline?.bookTitle || job.source?.fileName}
SUBJECT: ${job.outline?.subject || ''}
CHAPTER: ${chapterTitle}
LESSON: ${lessonTitle}
OTHER LESSONS IN THIS CHAPTER (do not cover their topics): ${siblingTitles.join(' | ') || '-'}
LANGUAGE: ${o.language || 'English'}
${o.examStyle ? `LEARNERS ARE PREPARING FOR: ${o.examStyle}` : ''}
${o.instructions ? `TEACHER INSTRUCTIONS: ${o.instructions}` : ''}`;
}

/** What makes the notes faithful to the book and fully explained. */
function fidelityRules(label, minWords) {
  return `- Use ONLY information in the SOURCE. Never invent facts, figures, dates, names, laws or definitions, and keep the book's own terminology.
- Follow the SOURCE in its own order and keep its headings and numbering (e.g. "## 1.2 Objectives of Financial Management"): one ## heading per book section, ### for its sub-sections.
- Cover EVERYTHING in the SOURCE that belongs to this lesson: every section, sub-heading, definition, list item, classification, table, worked example and exercise. Never drop a point because it looks minor.
- Definitions, laws, rules, principles and formulas: first give the book's exact wording as a quote — "> **Definition (${label.toLowerCase()} 14):** exact words from the book" — then explain it in plain words.
- For every concept: what the book says, then a clear explanation of what it means and why it matters, then the book's example. If the book gives no example, add a short everyday illustration labelled "Illustration" that introduces no new facts.
- Lists in the book (types, features, advantages, steps, …) keep ALL their items in the same order, each with 1-3 sentences of explanation.
- Tables in the book become markdown tables with the same rows and columns.
- Worked examples keep the book's numbers exactly and show every step of the working.
- Formulas: plain text expression, e.g. "PV = FV / (1 + r)^n".
- Ignore running headers/footers and printed page numbers in the SOURCE.
- The source contains [[${label} n]] markers; put the ${label.toLowerCase()} number in every "page" field.
- "notes" is markdown (## / ### headings, short paragraphs, bullet lists, **bold** key terms, > quotes, tables) of AT LEAST ${minWords} words — a complete lesson a student can learn from without the book, not a summary.`;
}

const LESSON_PARTS_SPEC = `"notes": "markdown",
  "keyPoints": ["..."],
  "keyTerms": [ { "term": "...", "definition": "the book's definition", "page": 14 } ],
  "examples": [ { "title": "...", "body": "markdown, step by step", "page": 15 } ],
  "formulas": [ { "name": "...", "expression": "...", "variables": [ { "symbol": "r", "meaning": "..." } ], "explanation": "...", "page": 16 } ],
  "sources": [ { "page": 14, "section": "1.2 ..." } ]`;

function practiceRules(o) {
  return `- ${o.includeVisuals === false ? 'Return "visuals": [].' : 'Add visuals that make the lesson easier to understand.'}
- ${o.includeFlashcards === false ? 'Return "flashcards": [].' : 'Add 6-12 flashcards covering the key terms and facts.'}
- Always add 2-3 "activities" so the student practises what they just read.`;
}

function practiceSpec(o) {
  return `"flashcards": [ { "front": "...", "back": "..." } ],
  ${VISUAL_SPEC},
  ${ACTIVITY_SPEC},
  ${o.includeVisuals === false ? '"images": [],' : IMAGE_SPEC + ','}
  "estimatedMinutes": 15`;
}

/**
 * Write a lesson from the book pages. Short lessons are one request; longer
 * ones are written part by part from the full text of every page (nothing is
 * trimmed away), then a final request adds the summary and practice material.
 */
async function generateLessonContent({ job, chapterTitle, lessonTitle, siblingTitles, pages }) {
  const parts = splitIntoParts(pages);
  if (parts.length <= 1) return generateSingleLesson({ job, chapterTitle, lessonTitle, siblingTitles, pages });

  const sections = new Array(parts.length);
  await runPool(parts.map((p, i) => i), 2, async (i) => {
    sections[i] = await generateLessonPart({ job, chapterTitle, lessonTitle, siblingTitles, pages: parts[i], index: i, total: parts.length });
  });
  const notes = sections.map(s => s.notes).join('\n\n');
  const frame = await generateLessonFrame({ job, chapterTitle, lessonTitle, siblingTitles, notes });

  const dedupe = (list, key) => {
    const seen = new Set();
    return list.filter(x => {
      const k = key(x);
      if (seen.has(k)) return false;
      seen.add(k);
      return true;
    });
  };
  const all = (field) => sections.flatMap(s => s[field]);
  return {
    ...frame,
    notes,
    keyPoints: frame.keyPoints.length ? frame.keyPoints : all('keyPoints'),
    keyTerms: dedupe(all('keyTerms'), t => t.term.toLowerCase()),
    examples: all('examples'),
    formulas: dedupe(all('formulas'), f => f.expression.replace(/\s+/g, '')),
    sources: dedupe(all('sources'), s => `${s.page}:${s.section.toLowerCase()}`),
    estimatedMinutes: Math.min(180, Math.max(frame.estimatedMinutes, Math.ceil(wordCount(notes) / 150))),
  };
}

async function generateSingleLesson({ job, chapterTitle, lessonTitle, siblingTitles, pages }) {
  const o = job.options || {};
  const unit = job.source?.pageUnit || 'page';
  const label = unit === 'segment' ? 'Part' : 'Page';
  const minWords = minNotesWords(pages);
  const prompt = `Create a complete, professional lesson that teaches the SOURCE below accurately and in full.

${lessonHeader(job, chapterTitle, lessonTitle, siblingTitles)}

RULES:
${fidelityRules(label, minWords)}
${practiceRules(o)}
- Empty arrays are fine when the source has nothing of that kind — but "summary", "notes" and "keyPoints" are ALWAYS required.
- Return the object below at the TOP LEVEL (do not wrap it in another key).

Return JSON:
{
  "summary": "2-3 sentences",
  "learningObjectives": ["By the end of this lesson you should be able to ..."],
  ${LESSON_PARTS_SPEC},
  ${practiceSpec(o)}
}

SOURCE:
${pagesToSource(pages, Infinity, unit)}`;

  return generateValidContent(prompt, 'lesson', { minWords });
}

async function generateLessonPart({ job, chapterTitle, lessonTitle, siblingTitles, pages, index, total }) {
  const unit = job.source?.pageUnit || 'page';
  const label = unit === 'segment' ? 'Part' : 'Page';
  const minWords = minNotesWords(pages);
  const prompt = `This lesson is long, so it is written in ${total} parts. Write PART ${index + 1} of ${total}: the lesson notes for the SOURCE below only (the other parts cover the rest of the lesson).

${lessonHeader(job, chapterTitle, lessonTitle, siblingTitles)}

RULES:
${fidelityRules(label, minWords)}
- ${index === 0 ? 'Start with a short introduction to the lesson, then the first book section.' : 'Continue straight from the previous part: no introduction, no conclusion — start with the first heading of this SOURCE (if the SOURCE starts mid-section, continue that section under its heading with "(continued)").'}
- Return the object below at the TOP LEVEL (do not wrap it in another key).

Return JSON:
{
  ${LESSON_PARTS_SPEC}
}

SOURCE:
${pagesToSource(pages, Infinity, unit)}`;

  return generateChecked(prompt, {
    hard: c => (!c.notes || c.notes.length < 150 ? 'notes are empty or too short' : ''),
    soft: c => notesTooShort(c, minWords),
    maxTokens: 14000,
  });
}

/** Summary, objectives and practice material for a lesson written in parts — built from its finished notes. */
async function generateLessonFrame({ job, chapterTitle, lessonTitle, siblingTitles, notes }) {
  const o = job.options || {};
  const prompt = `Below are the complete NOTES of a lesson. Write its summary, learning objectives, key points and practice material.

${lessonHeader(job, chapterTitle, lessonTitle, siblingTitles)}

RULES:
- Use ONLY information in the NOTES. Never invent facts.
- Key points: 6-12, covering the whole lesson from start to end.
${practiceRules(o)}
- Image "afterHeading" values must be exact ## headings from the NOTES.
- Return the object below at the TOP LEVEL (do not wrap it in another key).

Return JSON:
{
  "summary": "3-4 sentences covering the whole lesson",
  "learningObjectives": ["By the end of this lesson you should be able to ..."],
  "keyPoints": ["..."],
  ${practiceSpec(o)}
}

NOTES:
${notes.slice(0, OUTLINE_INPUT_CHARS)}`;

  return generateChecked(prompt, {
    hard: c => (!c.summary ? 'summary is empty' : !c.keyPoints.length ? 'keyPoints is empty' : ''),
    maxTokens: 8000,
  });
}

function notesTooShort(c, minWords) {
  const words = wordCount(c.notes);
  return minWords && words < minWords * 0.6
    ? `notes have only ${words} words but must be at least ${minWords} words and cover every point of the SOURCE`
    : '';
}

/**
 * Ask for content, and make sure it is not empty. Models sometimes wrap the
 * object in another key or return a skeleton; that must never be saved as a
 * finished lesson. Notes that are much shorter than the book section are
 * retried once, then accepted.
 */
async function generateValidContent(prompt, what, { minWords = 0 } = {}) {
  return generateChecked(prompt, {
    hard: c => contentProblem(c, what),
    soft: c => notesTooShort(c, minWords),
    what,
    maxTokens: minWords ? 16000 : 10000,
  });
}

async function generateChecked(prompt, { hard, soft = () => '', what = 'answer', maxTokens = 10000 }) {
  let lastProblem = '';
  let acceptable = null;
  for (let attempt = 1; attempt <= 2; attempt++) {
    const extra = attempt === 1 ? '' : `\n\nIMPORTANT: your previous answer was rejected (${lastProblem}). Fix this and return the full object at the top level.`;
    const raw = await completeJson(prompt + extra, { maxTokens, temperature: 0.3 });
    const content = normalizeContent(unwrapContent(raw));
    lastProblem = hard(content);
    if (lastProblem) continue;
    lastProblem = soft(content);
    if (!lastProblem) return content;
    acceptable = content;
  }
  if (acceptable) return acceptable;
  throw new Error(`AI returned an incomplete ${what}: ${lastProblem}`);
}

/** {"lesson": {...}} / {"data": {...}} → the inner object. */
function unwrapContent(raw) {
  let obj = raw;
  for (let depth = 0; depth < 2 && obj && typeof obj === 'object'; depth++) {
    if (obj.notes || obj.summary || obj.keyPoints) return obj;
    const inner = Object.values(obj).filter(v => v && typeof v === 'object' && !Array.isArray(v));
    if (inner.length !== 1) break;
    obj = inner[0];
  }
  return obj || {};
}

function contentProblem(c, what) {
  if (!c.summary) return 'summary is empty';
  if (!c.notes || c.notes.length < (what === 'lesson' ? 250 : 150)) return 'notes are empty or too short';
  if (!c.keyPoints.length) return 'keyPoints is empty';
  return '';
}

async function generateRevisionNotes({ job, chapterTitle, lessonTitles, pages }) {
  const o = job.options || {};
  const unit = job.source?.pageUnit || 'page';
  const label = unit === 'segment' ? 'Part' : 'Page';
  const prompt = `Create concise REVISION NOTES for a whole chapter, for students revising before an exam.

BOOK: ${job.outline?.bookTitle || ''}
CHAPTER: ${chapterTitle}
TOPICS: ${lessonTitles.join(' | ')}
${o.examStyle ? `EXAM: ${o.examStyle}` : ''}
${o.instructions ? `TEACHER INSTRUCTIONS: ${o.instructions}` : ''}

RULES: Use ONLY the SOURCE. Put the ${label.toLowerCase()} number (from [[${label} n]] markers) in every "page" field. Be compact: bullet points, tables, formulas, mnemonics.

Return JSON:
{
  "summary": "...",
  "learningObjectives": [],
  "notes": "markdown revision sheet",
  "keyPoints": ["..."],
  "keyTerms": [ { "term": "...", "definition": "...", "page": 1 } ],
  "examples": [],
  "formulas": [ { "name": "...", "expression": "...", "variables": [ { "symbol": "...", "meaning": "..." } ], "explanation": "...", "page": 1 } ],
  "flashcards": [ { "front": "...", "back": "..." } ],
  "examTips": ["..."],
  "commonMistakes": ["..."],
  ${VISUAL_SPEC},
  ${ACTIVITY_SPEC},
  "sources": [ { "page": 1, "section": "..." } ],
  "estimatedMinutes": 20
}

SOURCE:
${pagesToSource(pages, 18000, unit)}`;

  return generateValidContent(prompt, 'revision sheet');
}

function normalizeContent(raw) {
  const arr = (v) => (Array.isArray(v) ? v : []);
  const str = (v) => (typeof v === 'string' ? v.trim() : v == null ? '' : String(v));
  const num = (v) => (Number.isFinite(Number(v)) ? Number(v) : null);

  const visuals = arr(raw.visuals)
    .filter(v => v && VISUAL_TYPES.includes(v.type))
    .map(v => sanitizeVisual(v))
    .filter(Boolean)
    .slice(0, 4);

  return {
    summary: str(raw.summary),
    learningObjectives: arr(raw.learningObjectives).map(str).filter(Boolean),
    notes: str(raw.notes),
    keyPoints: arr(raw.keyPoints).map(str).filter(Boolean),
    keyTerms: arr(raw.keyTerms).filter(t => t && t.term).map(t => ({ term: str(t.term), definition: str(t.definition), page: num(t.page) })),
    examples: arr(raw.examples).filter(e => e && (e.title || e.body)).map(e => ({ title: str(e.title), body: str(e.body), page: num(e.page) })),
    formulas: arr(raw.formulas).filter(f => f && f.expression).map(f => ({
      name: str(f.name),
      expression: str(f.expression),
      variables: arr(f.variables).filter(v => v && v.symbol).map(v => ({ symbol: str(v.symbol), meaning: str(v.meaning) })),
      explanation: str(f.explanation),
      page: num(f.page),
    })),
    flashcards: arr(raw.flashcards).filter(c => c && c.front && c.back).map(c => ({ front: str(c.front), back: str(c.back) })),
    activities: arr(raw.activities).map(sanitizeActivity).filter(Boolean).slice(0, 4),
    imageRequests: arr(raw.images)
      .filter(i => i && i.query)
      .map(i => ({ query: str(i.query).slice(0, 80), caption: str(i.caption), afterHeading: str(i.afterHeading) }))
      .slice(0, 3),
    examTips: arr(raw.examTips).map(str).filter(Boolean),
    commonMistakes: arr(raw.commonMistakes).map(str).filter(Boolean),
    visuals,
    sources: arr(raw.sources).filter(s => s && s.page != null).map(s => ({ page: num(s.page), section: str(s.section) })),
    estimatedMinutes: Math.max(5, Math.min(180, num(raw.estimatedMinutes) || 15)),
  };
}

function sanitizeActivity(a) {
  const s = (x) => (x == null ? '' : String(x).trim());
  if (!a || typeof a !== 'object') return null;
  switch (a.type) {
    case 'match': {
      const pairs = (a.pairs || []).filter(p => p && p.left && p.right).map(p => ({ left: s(p.left), right: s(p.right) })).slice(0, 6);
      const lefts = new Set(pairs.map(p => p.left.toLowerCase()));
      return pairs.length >= 3 && lefts.size === pairs.length ? { type: 'match', title: s(a.title) || 'Match the pairs', pairs } : null;
    }
    case 'order': {
      const items = [...new Set((a.items || []).map(s).filter(Boolean))].slice(0, 7);
      return items.length >= 3 ? { type: 'order', title: s(a.title) || 'Put these in order', items } : null;
    }
    case 'categorize': {
      const categories = (a.categories || [])
        .filter(c => c && c.name)
        .map(c => ({ name: s(c.name), items: [...new Set((c.items || []).map(s).filter(Boolean))].slice(0, 5) }))
        .filter(c => c.items.length)
        .slice(0, 4);
      return categories.length >= 2 ? { type: 'categorize', title: s(a.title) || 'Sort into groups', categories } : null;
    }
    case 'fill_blanks': {
      const text = s(a.text);
      const blanks = (text.match(/\[\[([^\]]+)\]\]/g) || []).length;
      return blanks >= 1 && blanks <= 8
        ? { type: 'fill_blanks', title: s(a.title) || 'Fill in the blanks', text, distractors: (a.distractors || []).map(s).filter(Boolean).slice(0, 4) }
        : null;
    }
    default:
      return null;
  }
}

function sanitizeVisual(v) {
  const s = (x) => (x == null ? '' : String(x).trim());
  switch (v.type) {
    case 'flow':
    case 'cycle': {
      const steps = (v.steps || []).filter(x => x && x.label).map(x => ({ label: s(x.label), detail: s(x.detail) })).slice(0, 10);
      return steps.length >= 2 ? { type: v.type, title: s(v.title), steps } : null;
    }
    case 'comparison': {
      const columns = (v.columns || []).map(s).slice(0, 5);
      const rows = (v.rows || []).filter(Array.isArray).map(r => columns.map((_, i) => s(r[i]))).slice(0, 12);
      return columns.length >= 2 && rows.length ? { type: 'comparison', title: s(v.title), columns, rows } : null;
    }
    case 'timeline': {
      const events = (v.events || []).filter(x => x && x.label).map(x => ({ label: s(x.label), detail: s(x.detail) })).slice(0, 12);
      return events.length >= 2 ? { type: 'timeline', title: s(v.title), events } : null;
    }
    case 'hierarchy': {
      const clean = (nodes, depth) => (nodes || []).filter(n => n && n.label).slice(0, 8).map(n => ({
        label: s(n.label),
        children: depth < 2 ? clean(n.children, depth + 1) : [],
      }));
      const children = clean(v.children, 0);
      return v.root && children.length ? { type: 'hierarchy', title: s(v.title), root: s(v.root), children } : null;
    }
    case 'chart': {
      const labels = (v.labels || []).map(s).slice(0, 12);
      const series = (v.series || []).map(x => ({
        name: s(x?.name),
        values: (x?.values || []).map(Number).slice(0, labels.length),
      })).filter(x => x.values.length === labels.length && x.values.every(Number.isFinite)).slice(0, 3);
      const chartType = ['bar', 'pie', 'line'].includes(v.chartType) ? v.chartType : 'bar';
      return labels.length >= 2 && series.length ? { type: 'chart', title: s(v.title), chartType, labels, series, caption: s(v.caption) } : null;
    }
    default:
      return null;
  }
}

// ─── Questions ───────────────────────────────────────────────────────────────

async function generateQuestions({ job, scopeTitle, chapterTitle, pages, count, types, purpose }) {
  if (count <= 0) return [];
  const o = job.options || {};
  const unit = job.source?.pageUnit || 'page';
  const label = unit === 'segment' ? 'Part' : 'Page';
  const mix = difficultyCounts(count, o.difficultyMix);
  const allowed = (types && types.length ? types : o.questionTypes || QUESTION_TYPES).filter(t => QUESTION_TYPES.includes(t));

  const prompt = `Write ${count} high-quality assessment questions for: ${scopeTitle}.
PURPOSE: ${purpose}
BOOK: ${job.outline?.bookTitle || ''}
CHAPTER: ${chapterTitle}
${o.examStyle ? `STYLE: write them like real ${o.examStyle} exam questions.` : ''}
${o.instructions ? `TEACHER INSTRUCTIONS: ${o.instructions}` : ''}
LANGUAGE: ${o.language || 'English'}

DIFFICULTY (exact counts): easy ${mix.easy}, medium ${mix.medium}, hard ${mix.hard}
ALLOWED TYPES: ${allowed.join(', ')}
- mcq: 4 options, exactly one correct, plausible distractors, no "all of the above".
- true_false: options ["True","False"].
- calculation: only if the source has formulas/numbers; give 4 numeric options (mcq-style) with the worked solution in "explanation".
- scenario: a short realistic case followed by a question, 4 options (mcq-style).
- short_answer: no options; "answer" is the complete model answer (a key word, or 1-3 sentences). These are marked automatically against it, so in "explanation" list the key points a correct answer must contain.
Vary the types; never repeat a question.

RULES:
- Every question MUST be answerable from the SOURCE alone. Never invent facts.
- "sourceQuote": copy 8-25 words VERBATIM from the SOURCE that prove the answer.
- "page": the ${label.toLowerCase()} number from the nearest [[${label} n]] marker before that quote.
- "explanation": why the answer is right (and why the main distractor is wrong).
- "confidence": 0-100, how sure you are the answer is correct and supported by the source.

Return JSON:
{ "questions": [ {
  "type": "mcq",
  "question": "...",
  "options": ["...","...","...","..."],
  "correctIndex": 0,
  "answer": "text of the correct answer",
  "explanation": "...",
  "difficulty": "easy | medium | hard",
  "section": "section heading",
  "page": 14,
  "sourceQuote": "...",
  "confidence": 90
} ] }

SOURCE:
${pagesToSource(pages, LESSON_SOURCE_CHARS, unit)}`;

  const raw = await completeJson(prompt, { maxTokens: Math.min(8000, 900 + count * 420), temperature: 0.4 });
  return normalizeQuestions(raw.questions, chapterTitle);
}

function normalizeQuestions(list, chapterTitle) {
  const out = [];
  for (const q of Array.isArray(list) ? list : []) {
    if (!q || !q.question) continue;
    let type = QUESTION_TYPES.includes(q.type) ? q.type : 'mcq';
    let options = Array.isArray(q.options) ? q.options.map(o => String(o).trim()).filter(Boolean) : [];
    let correctIndex = Number.isInteger(Number(q.correctIndex)) ? Number(q.correctIndex) : null;

    if (type === 'true_false') {
      options = ['True', 'False'];
      if (correctIndex !== 0 && correctIndex !== 1) {
        const a = String(q.answer || '').toLowerCase();
        correctIndex = a.startsWith('t') ? 0 : a.startsWith('f') ? 1 : null;
      }
      if (correctIndex === null) continue;
    } else if (type === 'short_answer') {
      options = [];
      correctIndex = null;
      if (!q.answer) continue;
    } else {
      // mcq-like: mcq / calculation / scenario
      options = [...new Set(options)];
      if (options.length < 2) {
        if (type === 'mcq' || !q.answer) continue;
        type = 'short_answer';
        options = [];
        correctIndex = null;
      } else {
        if (correctIndex === null || correctIndex < 0 || correctIndex >= options.length) {
          const idx = options.findIndex(o => o.toLowerCase() === String(q.answer || '').trim().toLowerCase());
          if (idx < 0) continue;
          correctIndex = idx;
        }
      }
    }

    out.push({
      type,
      question: String(q.question).trim(),
      options,
      correctIndex,
      answer: String(q.answer || (correctIndex != null ? options[correctIndex] : '') || '').trim(),
      explanation: String(q.explanation || '').trim(),
      difficulty: ['easy', 'medium', 'hard'].includes(q.difficulty) ? q.difficulty : 'medium',
      source: {
        chapter: chapterTitle,
        section: String(q.section || '').trim(),
        page: Number.isFinite(Number(q.page)) ? Number(q.page) : null,
        quote: String(q.sourceQuote || '').trim(),
      },
      confidence: Math.max(0, Math.min(100, Number(q.confidence) || 70)),
    });
  }
  return out;
}

module.exports = {
  completeJson,
  unwrapContent,
  normalizeContent,
  generateOutline,
  generateLessonContent,
  generateRevisionNotes,
  generateQuestions,
  difficultyCounts,
  QUESTION_TYPES,
};
