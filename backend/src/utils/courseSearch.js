/**
 * Course search helpers: partial words, any order, safe regex.
 *
 *   "bio s3"  → matches "Biology S3"     (every word is a prefix/part of the text)
 *   "c++"     → searched literally       (special characters are escaped)
 */

const MAX_WORDS = 6;

const escapeRegex = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** Lower-cased words of a query, short and limited. */
function queryWords(q) {
  return String(q || '')
    .toLowerCase()
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .split(/\s+/)
    .map((w) => w.trim())
    .filter(Boolean)
    .slice(0, MAX_WORDS)
    .map((w) => w.slice(0, 40));
}

/**
 * Mongo filter: every word must appear in one of [fields].
 * Returns null for an empty query.
 */
function searchFilter(q, fields = ['title', 'description', 'instructorName']) {
  const words = queryWords(q);
  if (!words.length) return null;
  return {
    $and: words.map((w) => {
      const re = new RegExp(escapeRegex(w), 'i');
      return { $or: fields.map((f) => ({ [f]: re })) };
    }),
  };
}

/**
 * Relevance of [title] (+ [extra] text) for the query words; 0 = no match.
 * Whole title starting with the query > a title word starting with a word >
 * title containing it > only the extra text containing it.
 */
function relevance(q, title, extra = '') {
  const words = queryWords(q);
  if (!words.length) return 0;
  const norm = (s) => String(s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
  const t = norm(title);
  const e = norm(extra);
  const titleWords = t.split(/[^a-z0-9]+/).filter(Boolean);
  let score = 0;
  for (const w of words) {
    if (titleWords.some((tw) => tw.startsWith(w))) score += 3;
    else if (t.includes(w)) score += 2;
    else if (e.includes(w)) score += 1;
    else return 0; // every word must match somewhere
  }
  if (t.startsWith(words.join(' '))) score += 4;
  return score;
}

module.exports = { escapeRegex, queryWords, searchFilter, relevance };
