const { detectHazards, contentText } = require('../course-builder/integrity.service');
const { subjectByKey } = require('./subjects');

/**
 * Decides whether a science lesson gets an experiment-demonstration video,
 * and whether that video needs human review before students can see it.
 */

const PRACTICAL_RE = /\b(experiments?|practicals?|investigations?|apparatus|procedure|titrat\w*|set up the|measur(e|ing) the|observ(e|ation)s?|test tubes?|beakers?|burettes?|microscopes?|circuits?|pendulums?|bunsen|thermometers?|ammeters?|voltmeters?|specimens?)\b/gi;

const SIMULATION_DISCLOSURE = 'Simulated demonstration — illustrative only, not recorded experimental data.';

function practicalScore(content) {
  const text = contentText(content);
  return (text.match(PRACTICAL_RE) || []).length;
}

/**
 * @returns {{experiment: boolean, hazards: Array, reviewRequired: boolean, reasons: string[]}}
 */
function assessExperiment(subjectKey, content) {
  const subject = subjectByKey(subjectKey);
  const hazards = detectHazards(contentText(content));
  const score = practicalScore(content);
  const experiment = !!subject.science && score >= parseInt(process.env.VIDEO_EXPERIMENT_MIN_SIGNALS || '3', 10);
  const reasons = [];
  if (hazards.length) reasons.push(`Hazards mentioned: ${hazards.map(h => `${h.category} (${h.terms.join(', ')})`).join('; ')}`);
  const reviewAll = String(process.env.VIDEO_REQUIRE_REVIEW || 'false').toLowerCase() === 'true';
  const reviewExperiments = String(process.env.VIDEO_REVIEW_EXPERIMENTS || 'true').toLowerCase() !== 'false';
  if (reviewAll) reasons.push('All generated videos require review (VIDEO_REQUIRE_REVIEW=true)');
  return {
    experiment,
    score,
    hazards,
    reviewRequired: reviewAll || (experiment && (hazards.length > 0 || reviewExperiments)),
    reasons,
  };
}

module.exports = { assessExperiment, practicalScore, SIMULATION_DISCLOSURE };
