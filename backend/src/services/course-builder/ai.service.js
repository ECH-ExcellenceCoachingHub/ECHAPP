const GrokService = require('../grok_service');
const { sleep } = require('./extraction.service');

// Upper bound of source characters sent with a single generation request.
const LESSON_SOURCE_CHARS = 14000;
const OUTLINE_INPUT_CHARS = 24000;

const VISUAL_TYPES = ['flow', 'comparison', 'timeline', 'hierarchy', 'chart', 'cycle'];
const QUESTION_TYPES = ['mcq', 'true_false', 'short_answer', 'calculation', 'scenario'];

// ─── Low-level JSON completion with retry / rate-limit handling ──────────────

let jsonModeSupported = true;

async function completeJson(prompt, { maxTokens = 4096, temperature = 0.3, system } = {}) {
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
    try {
      const params = {
        model: await GrokService.resolveModel(),
        messages,
        temperature,
        max_tokens: maxTokens,
      };
      if (jsonModeSupported) params.response_format = { type: 'json_object' };
      const completion = await GrokService._createCompletion(params);
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
      if (status === 429 || status >= 500 || /rate limit|timeout|ECONNRESET|Empty response|JSON/i.test(err.message || '')) {
        const retryAfter = Number(err.headers?.['retry-after']);
        const wait = Number.isFinite(retryAfter) && retryAfter > 0
          ? Math.min(retryAfter * 1000, 45000)
          : Math.min(1500 * 2 ** (attempt - 1), 30000);
        await sleep(wait);
        continue;
      }
      throw err;
    }
  }
  throw lastError;
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

async function generateOutline({ fileName, pages, bookmarks, headings, unit }) {
  const label = unit === 'segment' ? 'Part' : 'Page';
  const lastPage = pages.length;

  const bookmarkText = bookmarks.length
    ? bookmarks.slice(0, 400).map(b => `${'  '.repeat(b.depth)}- ${b.title} (${label.toLowerCase()} ${b.page})`).join('\n')
    : '(none)';
  const headingText = headings
    .slice()
    .sort((a, b) => a.page - b.page)
    .map(h => `p${h.page} [s${h.score}] ${h.text}`)
    .join('\n')
    .slice(0, OUTLINE_INPUT_CHARS / 2);
  const frontMatter = pagesToSource(pages.slice(0, 8), OUTLINE_INPUT_CHARS / 3, unit);

  const prompt = `Analyse the structure of this book and design a course outline from it.

FILE: ${fileName}
TOTAL ${label.toUpperCase()}S: ${lastPage}

PDF BOOKMARKS (most reliable when present):
${bookmarkText}

HEADING CANDIDATES (p = ${label.toLowerCase()} number, s = heading score, higher is more likely a heading):
${headingText || '(none)'}

FRONT MATTER / TABLE OF CONTENTS:
${frontMatter}

TASK:
- Identify the book title, subject and level.
- Identify the real chapters (skip cover, preface, acknowledgements, index, bibliography, answers appendix).
- Inside each chapter, define lessons from its sections/topics. A lesson should cover roughly 2-12 ${label.toLowerCase()}s; merge tiny sections, split huge ones.
- Use the ${label.toLowerCase()} numbers where each chapter/lesson STARTS in this file (not the printed page numbers of the TOC if they differ — prefer the heading candidates' p-numbers).
- Keep the book's own numbering in titles when it exists (e.g. "1.2 Objectives of Financial Management").

Return JSON:
{
  "bookTitle": "...",
  "subject": "...",
  "level": "beginner | intermediate | advanced",
  "description": "2-3 sentence course description",
  "chapters": [
    {
      "title": "Chapter 1: ...",
      "summary": "one sentence",
      "pageStart": 5,
      "lessons": [ { "title": "1.1 ...", "pageStart": 5 } ]
    }
  ]
}`;

  return completeJson(prompt, { maxTokens: 8000, temperature: 0.1 });
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

async function generateLessonContent({ job, chapterTitle, lessonTitle, siblingTitles, pages }) {
  const o = job.options || {};
  const unit = job.source?.pageUnit || 'page';
  const label = unit === 'segment' ? 'Part' : 'Page';
  const prompt = `Create a complete, professional lesson from the SOURCE below.

BOOK: ${job.outline?.bookTitle || job.source?.fileName}
SUBJECT: ${job.outline?.subject || ''}
CHAPTER: ${chapterTitle}
LESSON: ${lessonTitle}
OTHER LESSONS IN THIS CHAPTER (do not cover their topics): ${siblingTitles.join(' | ') || '-'}
LANGUAGE: ${o.language || 'English'}
${o.examStyle ? `LEARNERS ARE PREPARING FOR: ${o.examStyle}` : ''}
${o.instructions ? `TEACHER INSTRUCTIONS: ${o.instructions}` : ''}

RULES:
- Use ONLY information in the SOURCE. Never invent facts, figures, laws or definitions.
- The source contains [[${label} n]] markers; put the ${label.toLowerCase()} number in every "page" field.
- "notes" is detailed markdown (## / ### headings, short paragraphs, bullet lists, **bold** key terms, tables where useful). 400-1200 words. Explain clearly for a student; do not just copy.
- Worked examples must keep the source's numbers and show each step.
- Formulas: plain text expression, e.g. "PV = FV / (1 + r)^n".
- ${o.includeVisuals === false ? 'Return "visuals": [].' : 'Add visuals that make the lesson easier to understand.'}
- ${o.includeFlashcards === false ? 'Return "flashcards": [].' : 'Add 4-10 flashcards.'}
- Always add 2-3 "activities" so the student practises what they just read.
- Empty arrays are fine when the source has nothing of that kind — but "summary", "notes" and "keyPoints" are ALWAYS required.
- Return the object below at the TOP LEVEL (do not wrap it in another key).

Return JSON:
{
  "summary": "2-3 sentences",
  "learningObjectives": ["By the end of this lesson you should be able to ..."],
  "notes": "markdown",
  "keyPoints": ["..."],
  "keyTerms": [ { "term": "...", "definition": "...", "page": 14 } ],
  "examples": [ { "title": "...", "body": "markdown, step by step", "page": 15 } ],
  "formulas": [ { "name": "...", "expression": "...", "variables": [ { "symbol": "r", "meaning": "..." } ], "explanation": "...", "page": 16 } ],
  "flashcards": [ { "front": "...", "back": "..." } ],
  ${VISUAL_SPEC},
  ${ACTIVITY_SPEC},
  ${o.includeVisuals === false ? '"images": [],' : IMAGE_SPEC + ','}
  "sources": [ { "page": 14, "section": "1.2 ..." } ],
  "estimatedMinutes": 15
}

SOURCE:
${pagesToSource(pages, LESSON_SOURCE_CHARS, unit)}`;

  return generateValidContent(prompt, 'lesson');
}

/**
 * Ask for content, and make sure it is not empty. Models sometimes wrap the
 * object in another key or return a skeleton; that must never be saved as a
 * finished lesson.
 */
async function generateValidContent(prompt, what) {
  let lastProblem = '';
  for (let attempt = 1; attempt <= 2; attempt++) {
    const extra = attempt === 1 ? '' : `\n\nIMPORTANT: your previous answer was rejected (${lastProblem}). Return the full object at the top level with non-empty "summary", "notes" and "keyPoints".`;
    const raw = await completeJson(prompt + extra, { maxTokens: 10000, temperature: 0.3 });
    const content = normalizeContent(unwrapContent(raw));
    lastProblem = contentProblem(content, what);
    if (!lastProblem) return content;
  }
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
