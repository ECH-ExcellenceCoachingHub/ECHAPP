/**
 * Creates the indexes for the AI media pipeline collections (non-destructive:
 * uses createIndexes, never drops anything). Safe to run more than once.
 *
 *   node scripts/createMediaIndexes.js
 *
 * Mongoose also builds these automatically on startup (autoIndex), but the
 * unique job key is what prevents duplicate video jobs, so run this once
 * before enabling the worker in production.
 */
require('dotenv').config();
const mongoose = require('mongoose');

(async () => {
  await mongoose.connect(process.env.MONGODB_URI);
  for (const name of ['GenerationJob', 'FigureAsset', 'FigureExtraction']) {
    const Model = require(`../src/models/${name}`);
    await Model.createIndexes();
    const idx = await Model.collection.indexes();
    console.log(`${name}: ${idx.map(i => i.name).join(', ')}`);
  }
  await mongoose.disconnect();
})().catch((e) => { console.error(e.message); process.exit(1); });
