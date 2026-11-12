/**
 * Built-in lab scenarios (services/labs/scenarios/*.json). Inserted once as
 * published labs; never overwrites a scenario an admin has edited.
 */
const fs = require('fs');
const path = require('path');
const LabScenario = require('../../models/LabScenario');
const { validateScenario } = require('./validator');

const DIR = path.join(__dirname, 'scenarios');
let seeded = null;

function loadSeedDefinitions() {
  return fs.readdirSync(DIR).filter((f) => f.endsWith('.json')).sort().map((f) => {
    const raw = JSON.parse(fs.readFileSync(path.join(DIR, f), 'utf8'));
    const result = validateScenario(raw);
    if (!result.ok) throw new Error(`Seed lab ${f} is invalid:\n- ${result.errors.join('\n- ')}`);
    return result.value;
  });
}

async function seedNow() {
  const defs = loadSeedDefinitions();
  let inserted = 0;
  for (const def of defs) {
    const res = await LabScenario.updateOne(
      { slug: def.id },
      {
        $setOnInsert: {
          slug: def.id, title: def.title, summary: def.summary, subject: def.subject, environment: def.environment,
          level: def.level, durationMin: def.durationMin, xp: def.xp, definition: def, version: def.version,
          difficulty: def.difficulty, tags: def.tags,
          status: 'published', source: 'seed', publishedAt: new Date(),
        },
      },
      { upsert: true },
    );
    if (res.upsertedCount) inserted++;
    // Built-in labs that were never edited by staff follow the shipped definition (new versions, hints, fixes).
    else await LabScenario.updateOne(
      { slug: def.id, source: 'seed', version: { $lt: def.version } },
      { $set: { title: def.title, summary: def.summary, definition: def, version: def.version, difficulty: def.difficulty, tags: def.tags, durationMin: def.durationMin, xp: def.xp } },
    );
  }
  return { total: defs.length, inserted };
}

/** Idempotent; runs at most once per process (cheap to call on every list). */
function ensureSeedScenarios() {
  if (!seeded) seeded = seedNow().catch((err) => { seeded = null; throw err; });
  return seeded;
}

module.exports = { ensureSeedScenarios, loadSeedDefinitions, seedNow };
