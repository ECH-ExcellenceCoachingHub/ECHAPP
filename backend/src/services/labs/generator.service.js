/**
 * AI lab builder: turns a lesson into a playable lab scenario draft.
 * The model only chooses from the equipment catalog of one environment, and its
 * output must pass validateScenario(); validation errors are fed back for up to
 * two repair rounds. Drafts always need teacher review before publishing.
 */
const ai = require('../course-builder/ai.service');
const { detectSubject } = require('../video/subjects');
const catalog = require('./catalog.json');
const { validateScenario } = require('./validator');
const { FUNCTIONS } = require('./expression');

const SUBJECT_TO_ENV = {
  chemistry: 'ChemLab',
  physics: 'PhysicsLab',
  biology: 'BioLab',
  cybersecurity: 'CyberSOC',
  networking: 'ServerRoom',
  coding: 'CodingBench',
};

const TECH_PATTERNS = [
  ['cybersecurity', /\b(cyber ?security|phishing|firewall|malware|incident response|intrusion|penetration|encryption)\b/i],
  ['networking', /\b(network(ing)?|subnet\w*|router|switch(es)?|tcp\/ip|ip address\w*|ethernet|ping|traceroute)\b/i],
  ['coding', /\b(programming|coding|python|javascript|algorithm\w*|machine learning|data science)\b/i],
];

/** Lab subject for a lesson, or null when no lab family fits. */
function labSubjectFor(...texts) {
  const hay = texts.filter(Boolean).join(' \n ');
  for (const [key, re] of TECH_PATTERNS) if (re.test(hay)) return key;
  const s = detectSubject(hay).key || '';
  if (s.startsWith('chem')) return 'chemistry';
  if (s.startsWith('phys')) return 'physics';
  if (s.startsWith('bio')) return 'biology';
  return null;
}

function slugify(text) {
  return String(text || 'lab').toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60) || 'lab';
}

function buildPrompt({ lesson, subject, environment, errors, previous }) {
  const env = catalog.environments[environment];
  const equipment = Object.fromEntries(Object.entries(catalog.equipment).map(([k, v]) => [k, { intents: v.intents, state: v.state, init: v.init }]));
  const models = Object.fromEntries(Object.entries(catalog.models));
  const notes = String(lesson.notes || lesson.description || '').slice(0, 9000);

  let prompt = `Design an interactive 3D virtual-lab experiment for the lesson below. Students perform it hands-on in a realistic lab (desktop, phone, or VR).

LESSON TITLE: ${lesson.title}
LESSON CONTENT:
"""
${notes}
"""

Return ONE JSON object (the scenario) with this exact shape:
{
  "id": "<kebab-case slug>", "version": 1, "title": "...", "summary": "...",
  "subject": "${subject}", "level": "primary|secondary|university|professional",
  "environment": "${environment}", "durationMin": 10-40,
  "objectives": ["..."],
  "equipment": [{ "id": "camelCaseId", "type": "<catalog type>", "slot": "<slot>", "label": "optional", "init": { <only the type's init keys> } }],
  "variables": { "<name>": { "model": "<model>", "inputs": { "<input>": "<equipment id>" }, "params": {} } },
  "steps": [
    { "id": "s1", "kind": "action", "title": "...", "instruction": "...", "say": "assistant narration (optional)", "hints": ["..."], "focus": "<equipment id>", "points": 5-20,
      "expect": { "intent": "<one of the target's intents>", "target": "<equipment id>", "into": "<receiver id, optional>" }, "until": "<optional condition expression>" },
    { "id": "m1", "kind": "measure", "instruction": "...", "record": { "key": "camelCase", "label": "...", "unit": "...", "truth": "<expression for the true reading>", "tolerance": <absolute> } },
    { "id": "q1", "kind": "checkpoint", "instruction": "Answer the question.", "checkpoint": { "question": { "prompt": "...", "choices": ["...","..."], "answerIndex": 0, "explanation": "..." } } }
  ],
  "hazards": [{ "id": "camelCase", "when": "<expression>", "message": "...", "severity": "warn|fail", "penalty": 0-30 }],
  "results": [{ "key": "<a record key>", "label": "...", "unit": "...", "expected": <number>, "tolerancePct": 1-10, "source": "record.<key>" }],
  "scoring": { "accuracy": n, "procedure": n, "safety": n },   // must add up to 100
  "passScore": 60, "xp": 80-200
}

ENVIRONMENT "${environment}" SLOTS (use each bench slot once; shelf.* and ppe.rack may hold several items): ${env.slots.join(', ')}
EQUIPMENT CATALOG (type → allowed intents, state you can read in expressions, init settings): ${JSON.stringify(equipment)}
SIMULATION MODELS (variables; read outputs as <variable>.<output>): ${JSON.stringify(models)}

EXPRESSIONS: a tiny language with numbers, 'strings', true/false, && || ! == != < <= > >= + - * / %, parentheses, paths like burette1.volumeMl / record.titre / titr.pH, and only these functions: ${FUNCTIONS.join(', ')}. done('stepId') is true once an EARLIER step is complete. Never reference anything not listed above.

RULES:
- Follow the lesson's real procedure, quantities and safety advice; never invent facts that contradict it.
- Start with safety equipment when the experiment needs it (goggles, lab coat, gloves) and add a hazard for skipping it.
- 6-14 steps. Include at least one measure step and one checkpoint question built from the lesson.
- "expected" values must be scientifically correct for the quantities you chose.
- Write for students: short, clear, encouraging instructions.`;

  if (errors && errors.length) {
    prompt += `\n\nYOUR PREVIOUS ANSWER WAS INVALID. Fix every problem and return the full corrected JSON.\nPROBLEMS:\n- ${errors.slice(0, 25).join('\n- ')}\nPREVIOUS ANSWER:\n${JSON.stringify(previous).slice(0, 12000)}`;
  }
  return prompt;
}

/**
 * @returns {Promise<{ ok: boolean, scenario?: object, errors: string[], subject, environment, rounds }>}
 */
async function generateScenario(lesson, { subject: forcedSubject, maxRepairs = 2 } = {}) {
  const subject = forcedSubject || labSubjectFor(lesson.title, lesson.description, lesson.notes);
  if (!subject || !SUBJECT_TO_ENV[subject]) {
    return { ok: false, errors: ['This lesson does not match any virtual-lab family yet (chemistry, physics, biology, cybersecurity, networking, coding).'], subject: subject || null, environment: null, rounds: 0 };
  }
  const environment = SUBJECT_TO_ENV[subject];
  let previous = null;
  let errors = [];
  for (let round = 0; round <= maxRepairs; round++) {
    const raw = await ai.completeJson(buildPrompt({ lesson, subject, environment, errors, previous }), {
      maxTokens: 6000,
      temperature: round === 0 ? 0.4 : 0.2,
      system: 'You are an expert science and technology teacher and a virtual-lab designer. You answer with a single valid JSON object and nothing else.',
    });
    const candidate = { ...(raw && raw.scenario ? raw.scenario : raw) };
    candidate.subject = subject;
    candidate.environment = environment;
    candidate.id = slugify(candidate.id || `${subject}-${lesson.title}`);
    const result = validateScenario(candidate);
    if (result.ok) return { ok: true, scenario: result.value, errors: [], subject, environment, rounds: round + 1 };
    errors = result.errors;
    previous = candidate;
  }
  return { ok: false, errors, scenario: previous, subject, environment, rounds: maxRepairs + 1 };
}

module.exports = { generateScenario, labSubjectFor, SUBJECT_TO_ENV, slugify, buildPrompt };
