/**
 * Source verification: every AI question carries a verbatim "sourceQuote".
 * We check that the quote really exists in the book pages the question was
 * generated from, fix the page number from where it was found, and lower the
 * confidence of anything we can't trace back to the source.
 */

function normalize(text) {
  return String(text || '')
    .toLowerCase()
    .replace(/[‘’]/g, "'")
    .replace(/[“”]/g, '"')
    .replace(/[^a-z0-9%$.]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function words(text) {
  return normalize(text).split(' ').filter(w => w.length > 2);
}

/** Locate a quote in pages. Returns {page, score} with score 0..1. */
function locateQuote(quote, pages, preferredPage = null) {
  const nq = normalize(quote);
  if (nq.length < 12) return { page: null, score: 0 };
  if (preferredPage) {
    const p = pages.find(x => x.n === preferredPage);
    if (p && (p._norm || (p._norm = normalize(p.text))).includes(nq)) return { page: p.n, score: 1 };
  }
  let best = { page: null, score: 0 };
  const qWords = words(quote);
  for (const p of pages) {
    const np = p._norm || (p._norm = normalize(p.text));
    if (np.includes(nq)) return { page: p.n, score: 1 };
    if (!qWords.length) continue;
    const set = p._words || (p._words = new Set(np.split(' ')));
    const hit = qWords.filter(w => set.has(w)).length / qWords.length;
    if (hit > best.score) best = { page: p.n, score: hit };
  }
  return best;
}

/**
 * Verify and annotate questions in place.
 * @returns {{verified:number, unverified:number}}
 */
function verifyQuestions(questions, pages) {
  let verified = 0;
  let unverified = 0;
  for (const q of questions) {
    const { page, score } = locateQuote(q.source?.quote, pages, q.source?.page);
    // Exact match, or nearly every content word present on one page
    q.verified = score >= 0.85;
    if (page && (q.verified || !q.source.page)) q.source.page = page;
    if (q.verified) {
      verified++;
    } else {
      unverified++;
      q.confidence = Math.min(q.confidence || 0, Math.round(40 + score * 30));
    }
  }
  return { verified, unverified };
}

/** Share of key terms that literally appear in the source — a cheap grounding signal. */
function termGrounding(content, pages) {
  const terms = content?.keyTerms || [];
  if (!terms.length) return null;
  const all = pages.map(p => p._norm || (p._norm = normalize(p.text))).join(' ');
  const found = terms.filter(t => all.includes(normalize(t.term))).length;
  return found / terms.length;
}

/** Item-level confidence + warnings shown to the reviewer. */
function scoreItem(item, pages) {
  const warnings = [];
  const qs = item.questions || [];
  const qConf = qs.length ? qs.reduce((s, q) => s + (q.confidence || 0), 0) / qs.length : null;
  const unverified = qs.filter(q => !q.verified).length;
  if (unverified) warnings.push(`${unverified} question(s) could not be matched to the source text — check them.`);

  const grounding = item.content ? termGrounding(item.content, pages) : null;
  if (grounding != null && grounding < 0.6) {
    warnings.push('Some key terms were not found in the source pages — check definitions.');
  }
  if ((item.kind === 'lesson' || item.kind === 'revision') && item.content) {
    const c = item.content;
    if (!c.summary || (c.notes || '').length < 250) {
      warnings.push('Lesson content is empty or very short — regenerate it.');
    } else if ((c.notes || '').length < 400) {
      warnings.push('Lesson notes are short — the source section may be thin.');
    }
    if (item.content && !(c.activities || []).length) warnings.push('No interactive activities — regenerate to add some.');
  }

  const parts = [];
  if (qConf != null) parts.push(qConf);
  if (grounding != null) parts.push(40 + grounding * 60);
  const confidence = parts.length ? Math.round(parts.reduce((a, b) => a + b, 0) / parts.length) : 80;
  return { confidence, warnings };
}

module.exports = { verifyQuestions, scoreItem, locateQuote };
