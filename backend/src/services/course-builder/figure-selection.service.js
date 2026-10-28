const GrokService = require('../grok_service');
const { figuresForRange } = require('./figures.service');

/**
 * Picks the textbook figures that matter for one lesson and decides how each
 * is used:
 *   notes            show it in the lesson notes
 *   video_reference  show it in the lesson video
 *   animate          highlight / animate it in the video (step-by-step reveal)
 *   supplement       keep it, but the video should add a new diagram as well
 *   exclude          irrelevant / decorative
 *
 * Only real FigureAsset ids are ever used: the AI chooses from the candidate
 * list and any id it returns that is not in that list is discarded.
 */

const USAGES = ['notes', 'video_reference', 'animate', 'supplement', 'exclude'];
const MAX_CANDIDATES = 12;

function candidateCard(a) {
  return {
    id: String(a._id),
    page: a.page,
    caption: a.caption || '(no caption)',
    kind: a.kind,
    labels: (a.labels || []).slice(0, 12),
    nearbyText: (a.surroundingText || '').slice(0, 280),
    quality: a.quality,
  };
}

function heuristicSelection(candidates) {
  return candidates.map(a => {
    const usable = a.caption && a.quality !== 'incomplete';
    return {
      id: String(a._id),
      usage: usable ? ['notes', 'video_reference'] : ['exclude'],
      reason: usable ? 'Captioned figure on the lesson pages' : 'No caption or incomplete extraction',
      afterHeading: '',
    };
  });
}

async function aiSelection({ lessonTitle, objectives, headings, candidates, completeJson }) {
  const prompt = `You are choosing textbook figures for ONE lesson.

LESSON: ${lessonTitle}
OBJECTIVES: ${(objectives || []).join(' | ') || '-'}
NOTE HEADINGS: ${(headings || []).join(' | ') || '-'}

CANDIDATE FIGURES (from the lesson's own pages):
${JSON.stringify(candidates.map(candidateCard), null, 1)}

For EVERY candidate decide its usage (one or more of): ${USAGES.join(', ')}.
- notes: helps a student reading the notes.
- video_reference: worth showing in the lesson video.
- animate: a diagram whose parts should be highlighted step by step in the video.
- supplement: relevant but insufficient — the video should also draw a new, clearer diagram.
- exclude: decorative, unrelated, unreadable or duplicated.
Use ONLY the ids given. Never invent ids, pages or captions.
"afterHeading" = the exact note heading the figure belongs under ("" if unsure).

Return JSON: { "figures": [ { "id": "...", "usage": ["notes","video_reference"], "reason": "short", "afterHeading": "" } ] }`;
  const raw = await completeJson(prompt, { maxTokens: 2000, temperature: 0.1 });
  return Array.isArray(raw?.figures) ? raw.figures : [];
}

/** Keep only valid ids/usages; fill in candidates the AI skipped. */
function validateSelection(selection, candidates) {
  const byId = new Map(candidates.map(c => [String(c._id), c]));
  const out = new Map();
  let invented = 0;
  for (const s of selection || []) {
    const id = String(s?.id || '');
    if (!byId.has(id)) { invented++; continue; }
    let usage = (Array.isArray(s.usage) ? s.usage : [s.usage]).filter(u => USAGES.includes(u));
    if (!usage.length) usage = ['exclude'];
    if (usage.includes('exclude')) usage = ['exclude'];
    out.set(id, { id, usage: [...new Set(usage)], reason: String(s.reason || '').slice(0, 200), afterHeading: String(s.afterHeading || '').slice(0, 160) });
  }
  for (const h of heuristicSelection(candidates)) if (!out.has(h.id)) out.set(h.id, h);
  return { selection: [...out.values()], invented };
}

function headingsOf(notes) {
  return String(notes || '').split('\n').filter(l => /^#{2,3}\s/.test(l)).map(l => l.replace(/^#+\s*/, '').trim()).slice(0, 20);
}

/**
 * Attach selected figures to generated lesson content.
 * Returns a new content object with `figures` (all decisions) and textbook
 * figures added to `images` (so existing app versions display them).
 */
async function attachFigures({ job, item, content, completeJson = null, log = () => {} }) {
  if (!content) return content;
  const fx = job.figureExtraction || {};
  if (fx.status !== 'completed' || !fx.bookHash) return { ...content, figures: content.figures || [] };

  const candidates = (await figuresForRange(fx.bookHash, item.pageStart, item.pageEnd, { limit: MAX_CANDIDATES }))
    .filter(a => a.storageKey);
  if (!candidates.length) return { ...content, figures: [] };

  let raw;
  const complete = completeJson || (GrokService.isConfigured() ? require('./ai.service').completeJson : null);
  try {
    raw = complete ? await aiSelection({
      lessonTitle: item.title,
      objectives: content.learningObjectives,
      headings: headingsOf(content.notes),
      candidates,
      completeJson: complete,
    }) : heuristicSelection(candidates);
  } catch (err) {
    log(`Figure selection AI failed (${err.message}) — using captions only`, 'warn');
    raw = heuristicSelection(candidates);
  }
  const { selection, invented } = validateSelection(raw, candidates);
  if (invented) log(`Discarded ${invented} figure id(s) the AI invented for "${item.title}"`, 'warn');

  const byId = new Map(candidates.map(c => [String(c._id), c]));
  const figures = selection.map(s => {
    const a = byId.get(s.id);
    return {
      assetId: s.id,
      figureId: a.figureId,
      url: a.url,
      caption: a.caption,
      captionLabel: a.captionLabel,
      page: a.page,
      kind: a.kind,
      quality: a.quality,
      usage: s.usage,
      reason: s.reason,
      afterHeading: s.afterHeading,
    };
  });

  const bookName = job.outline?.bookTitle || job.source?.fileName || 'the textbook';
  const textbookImages = figures
    .filter(f => f.usage.includes('notes'))
    .map(f => ({
      kind: 'textbook_figure',
      assetId: f.assetId,
      url: f.url,
      caption: f.caption || '',
      title: f.captionLabel ? `Figure ${f.captionLabel}` : 'Textbook figure',
      author: 'Textbook figure',
      license: `Source: ${bookName}, page ${f.page}`,
      afterHeading: f.afterHeading,
    }));

  const otherImages = (content.images || []).filter(i => i.kind !== 'textbook_figure');
  return { ...content, figures, images: [...textbookImages, ...otherImages] };
}

module.exports = { attachFigures, validateSelection, heuristicSelection, USAGES };
