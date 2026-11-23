/**
 * Checks every recent iTechPay payment that isn't completed against iTechPay
 * and applies the ones that were actually paid (the webhook never arrived and
 * nobody was watching). The server already does this every 2 minutes; this is
 * for running it by hand.
 *
 *   node scripts/reconcilePayments.js --dry-run   # only show what iTechPay says
 *   node scripts/reconcilePayments.js             # apply paid ones
 *
 * Safe to re-run: a payment is fulfilled at most once.
 */
require('dotenv').config();
const mongoose = require('mongoose');

(async () => {
  const dryRun = process.argv.includes('--dry-run');
  await mongoose.connect(process.env.MONGODB_URI);
  for (const m of ['User', 'Course', 'Enrollment', 'TeacherAssignment', 'School', 'SchoolTerm', 'Notification']) require(`../src/models/${m}`);
  const { sweep } = require('../src/services/payments/checkout.service');
  const r = await sweep({ dryRun, log: (l) => console.log(' ', l) });
  console.log(`\nchecked=${r.checked} paid=${r.completed} failed=${r.failed} pending=${r.pending} errors=${r.errors}${dryRun ? ' (dry run — nothing written)' : ''}`);
  await mongoose.disconnect();
})().catch((e) => {
  console.error('Reconcile failed:', e);
  process.exit(1);
});
