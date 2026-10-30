/**
 * Subject-specific storyboard templates. Every subject uses the same video
 * pipeline; only the allowed scene types, the guidance given to the planner
 * and the default length differ.
 */

const SCENE_TYPES = [
  'title', 'bullets', 'formula', 'graph', 'figure', 'worked_example',
  'table', 'ledger', 'timeline', 'flow', 'dialogue', 'experiment', 'summary',
  'media', // full-screen licensed photo/clip with animated key points
  'check', // "pause and think" question; the app pauses here and asks the student
];

const SUBJECTS = [
  {
    key: 'mathematics',
    match: /\b(math|maths|mathematics|algebra|geometry|calculus|statistics?|trigonometr\w*|arithmetic|probability|vectors?|matrices|quantitative)\b/i,
    scenes: ['title', 'formula', 'graph', 'worked_example', 'figure', 'bullets', 'table', 'summary'],
    durationSec: [180, 330], // worked examples explained slowly, step by step
    guidance: `Teach visually: use "graph" scenes for functions, coordinate planes and geometric relationships; "formula" scenes that transform an expression step by step (one transformation per step, in LaTeX); "worked_example" scenes that solve the lesson's own example line by line keeping its numbers. Highlight the symbol being discussed in the narration. Never round or change numbers from the source.
WHEN THE LESSON HAS A WORKED EXAMPLE, SOLVE IT COMPLETELY so a student can follow every calculation:
  1. Show the question exactly as the lesson states it, on screen, before solving.
  2. One scene per stage of the method (e.g. rewrite, substitute, simplify, solve, final answer). Before each stage the narration says what we are about to do and why.
  3. Put every intermediate line on screen. Never skip arithmetic the student must do: write "2x^2 = 32", then "x^2 = 16", then "x = ±4", not just the result.
  4. End each stage with its result on its own line, and state the final answer clearly.
  5. Check the answer by substituting it back into the original question, with the calculation on screen.
  If a stage needs more lines than one scene allows, continue it in the next scene.
Real-world photos are optional in mathematics: use a "media" scene only for an application the lesson itself describes, never invent one.`,
    mediaOptional: true,
  },
  {
    key: 'physics',
    match: /\b(physics|mechanics|electricity|magnetism|optics|thermodynamics|waves?|kinematics|dynamics|electronics)\b/i,
    scenes: ['title', 'formula', 'graph', 'worked_example', 'figure', 'flow', 'bullets', 'experiment', 'summary'],
    durationSec: [120, 210],
    guidance: `Connect each law to a picture: use textbook figures, "flow" scenes for cause → effect, "graph" scenes for relationships (e.g. v-t graphs), and "formula" scenes with units for every quantity. Worked examples must state units at each step.`,
    science: true,
  },
  {
    key: 'chemistry',
    match: /\b(chemistry|chemical|organic|inorganic|stoichiometry|acids?|bases?|reactions?|periodic table|electrochemistry)\b/i,
    scenes: ['title', 'formula', 'figure', 'flow', 'table', 'worked_example', 'bullets', 'experiment', 'summary'],
    durationSec: [120, 210],
    guidance: `Write chemical equations in LaTeX (\\ce-free plain LaTeX, e.g. "2H_2 + O_2 \\rightarrow 2H_2O") and check they are balanced as given in the source. Use "flow" scenes for reaction steps and "table" scenes for properties. State observations only as described in the source.`,
    science: true,
  },
  {
    key: 'biology',
    match: /\b(biology|cells?|genetics|ecology|anatomy|physiology|botany|zoology|microbiology|organisms?|photosynthesis)\b/i,
    scenes: ['title', 'figure', 'flow', 'table', 'bullets', 'experiment', 'summary'],
    durationSec: [120, 200],
    guidance: `Use labelled textbook diagrams (highlight one structure at a time by its label), "flow" scenes for processes and cycles, and "table" scenes to compare structures and functions.`,
    science: true,
  },
  {
    key: 'accounting',
    match: /\b(accounting|accountancy|cpa|acca|cima|audit(ing)?|tax(ation)?|bookkeeping|financial (reporting|statements|accounting)|ledger|costing|finance)\b/i,
    scenes: ['title', 'ledger', 'table', 'worked_example', 'formula', 'flow', 'bullets', 'summary'],
    durationSec: [120, 210],
    guidance: `Use "ledger" scenes for journal entries and T-accounts (columns such as Date | Account | Debit | Credit) and "table" scenes for extracts of financial statements. Debits must equal credits. Keep every amount from the source; show each calculation step in "worked_example".`,
  },
  {
    key: 'languages',
    match: /\b(english|french|kinyarwanda|swahili|kiswahili|spanish|german|language|grammar|vocabulary|literature|linguistics|pronunciation|writing skills)\b/i,
    scenes: ['title', 'table', 'dialogue', 'bullets', 'flow', 'summary'],
    durationSec: [100, 180],
    guidance: `Use "dialogue" scenes for short realistic conversations that use the lesson's vocabulary, "table" scenes for vocabulary (word | meaning | example), and say each new word clearly in the narration so learners hear its pronunciation.`,
  },
  {
    key: 'business',
    match: /\b(business|management|marketing|entrepreneurship|economics|strategy|human resources|operations|leadership|commerce)\b/i,
    scenes: ['title', 'flow', 'table', 'bullets', 'figure', 'graph', 'summary'],
    durationSec: [100, 180],
    guidance: `Ground the lesson in a short realistic case (from the source when it has one), use "flow" scenes for processes and decision steps and "table" scenes for comparisons. Use "graph" only for curves the source describes (e.g. supply and demand).`,
  },
  {
    key: 'geography',
    match: /\b(geography|maps?|climate|weather|landforms?|rivers?|population|earth science|environment)\b/i,
    scenes: ['title', 'figure', 'flow', 'table', 'timeline', 'bullets', 'summary'],
    durationSec: [100, 180],
    guidance: `Prefer textbook maps and labelled diagrams (highlight places/features by label), "flow" scenes for geographical processes (e.g. the water cycle) and "table" scenes for data stated in the source.`,
  },
  {
    key: 'history',
    match: /\b(history|historical|civili[sz]ations?|wars?|colonial|independence|empires?|revolution)\b/i,
    scenes: ['title', 'timeline', 'figure', 'bullets', 'table', 'summary'],
    durationSec: [100, 180],
    guidance: `Use "timeline" scenes for chronology and textbook maps/figures for places. Any imagined scene must be described as an illustrative reconstruction in the on-screen labels.`,
  },
];

const GENERAL = {
  key: 'general',
  scenes: ['title', 'bullets', 'flow', 'table', 'figure', 'worked_example', 'summary'],
  durationSec: [100, 180],
  guidance: 'Explain the key ideas with diagrams, examples and short on-screen points. Avoid slides full of text.',
};

const GENERAL_SCIENCE = {
  key: 'general_science',
  match: /\b(science|integrated science|natural science)\b/i,
  scenes: ['title', 'figure', 'flow', 'formula', 'table', 'bullets', 'experiment', 'summary'],
  durationSec: [120, 200],
  guidance: 'Use labelled diagrams, cause-and-effect flows and simple formulas with units.',
  science: true,
};

// Every subject can use real-world media scenes and in-video checks, and a
// worked calculation (e.g. population density in biology) is shown step by step.
for (const s of [...SUBJECTS, GENERAL, GENERAL_SCIENCE]) {
  if (!s.scenes.includes('worked_example')) s.scenes.splice(s.scenes.indexOf('summary'), 0, 'worked_example');
  s.scenes.splice(s.scenes.indexOf('summary'), 0, 'media', 'check');
}

/** Scene types for experiment demonstration videos. */
const EXPERIMENT_SCENES = ['title', 'experiment', 'figure', 'formula', 'media', 'check', 'summary'];
// Experiment phases where the student should SEE the work being done: these
// scenes ask for a clip and are shown full screen with the steps over it.
const HANDS_ON_PHASES = ['apparatus', 'setup', 'procedure', 'observation'];

/** Detect the subject template from book/course metadata. */
function detectSubject(...texts) {
  const hay = texts.filter(Boolean).join(' \n ');
  for (const s of SUBJECTS) if (s.match.test(hay)) return s;
  if (GENERAL_SCIENCE.match.test(hay)) return GENERAL_SCIENCE;
  return GENERAL;
}

function subjectByKey(key) {
  return SUBJECTS.find(s => s.key === key) || (key === GENERAL_SCIENCE.key ? GENERAL_SCIENCE : GENERAL);
}

module.exports = { SCENE_TYPES, SUBJECTS, EXPERIMENT_SCENES, HANDS_ON_PHASES, detectSubject, subjectByKey };
