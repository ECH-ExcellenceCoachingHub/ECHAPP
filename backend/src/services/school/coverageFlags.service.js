/**
 * Checks a lesson a teacher marked as taught and raises flags when it looks
 * like it was not really taught. Flags never block the teacher; they put the
 * mark in the school admin's review list.
 *
 *   FUTURE_DATE      taught date is in the future                    (high)
 *   BULK_MARKING     many lessons marked for the class within minutes (high)
 *   STUDENTS_DISPUTE most students who answered say it was not taught (high)
 *   WEEKEND          taught on Saturday/Sunday                        (medium)
 *   OUTSIDE_TERM     taught date is outside every term of the school  (medium)
 *   TOO_MANY_IN_DAY  more lessons on one day than is realistic        (medium)
 *   LATE_MARKING     marked more than 14 days after the taught date   (low)
 *   NO_EVIDENCE      no notes/photo, no live class, no homework around that day (low)
 *
 * Status becomes "flagged" when there is a high flag, or two or more other flags.
 */
const LessonCoverage = require('../../models/LessonCoverage');
const SchoolTerm = require('../../models/SchoolTerm');
const Assessment = require('../../models/Assessment');
const LiveSession = require('../../models/LiveSession');

const DAY = 24 * 3600 * 1000;
const BULK_WINDOW_MS = 15 * 60 * 1000;
const BULK_COUNT = 4; // this mark + 3 others in the window
const MAX_PER_DAY = 3;
const LATE_DAYS = 14;
const DISPUTE_MIN_ANSWERS = 3;

const startOfDay = (d) => { const x = new Date(d); x.setHours(0, 0, 0, 0); return x; };

async function computeFlags(cov, now = new Date()) {
  const flags = [];
  const taughtOn = new Date(cov.taughtOn);
  const markedAt = cov.createdAt ? new Date(cov.createdAt) : now;

  if (startOfDay(taughtOn) > startOfDay(now)) {
    flags.push({ code: 'FUTURE_DATE', severity: 'high', message: 'Marked as taught on a future date.' });
  }

  const day = taughtOn.getDay();
  if (day === 0 || day === 6) {
    flags.push({ code: 'WEEKEND', severity: 'medium', message: 'Marked as taught on a weekend.' });
  }

  const terms = await SchoolTerm.find({ schoolId: cov.schoolId }).select('startDate endDate').lean();
  if (terms.length && !terms.some((t) => startOfDay(t.startDate) <= taughtOn && taughtOn <= new Date(startOfDay(t.endDate).getTime() + DAY))) {
    flags.push({ code: 'OUTSIDE_TERM', severity: 'medium', message: 'The date is outside the school terms.' });
  }

  const bulk = await LessonCoverage.countDocuments({
    _id: { $ne: cov._id },
    teacherId: cov.teacherId,
    classroomId: cov.classroomId,
    createdAt: { $gte: new Date(markedAt - BULK_WINDOW_MS), $lte: new Date(markedAt.getTime() + BULK_WINDOW_MS) },
  });
  if (bulk + 1 >= BULK_COUNT) {
    flags.push({ code: 'BULK_MARKING', severity: 'high', message: `${bulk + 1} lessons were marked for this class within 15 minutes.` });
  }

  const sameDay = await LessonCoverage.countDocuments({
    _id: { $ne: cov._id },
    classSubjectId: cov.classSubjectId,
    taughtOn: { $gte: startOfDay(taughtOn), $lt: new Date(startOfDay(taughtOn).getTime() + DAY) },
  });
  if (sameDay + 1 > MAX_PER_DAY) {
    flags.push({ code: 'TOO_MANY_IN_DAY', severity: 'medium', message: `${sameDay + 1} lessons of this subject marked on the same day.` });
  }

  if (markedAt - taughtOn > LATE_DAYS * DAY) {
    flags.push({ code: 'LATE_MARKING', severity: 'low', message: `Marked ${Math.floor((markedAt - taughtOn) / DAY)} days after the lesson date.` });
  }

  const hasOwnEvidence = (cov.notes && cov.notes.trim().length >= 15) || (cov.attachments && cov.attachments.length > 0);
  if (!hasOwnEvidence) {
    const from = new Date(startOfDay(taughtOn).getTime() - DAY);
    const to = new Date(startOfDay(taughtOn).getTime() + 2 * DAY);
    const [homework, live] = await Promise.all([
      Assessment.exists({ classSubjectId: cov.classSubjectId, createdAt: { $gte: from, $lt: to } }),
      LiveSession.exists({ teacherId: cov.teacherId, scheduledAt: { $gte: from, $lt: to }, status: { $in: ['live', 'ended'] } }),
    ]);
    if (!homework && !live) {
      flags.push({ code: 'NO_EVIDENCE', severity: 'low', message: 'No notes, photo, live class or homework around this date.' });
    }
  }

  const checks = cov.studentChecks || [];
  if (checks.length >= DISPUTE_MIN_ANSWERS) {
    const no = checks.filter((c) => c.taught === false).length;
    if (no / checks.length > 0.5) {
      flags.push({ code: 'STUDENTS_DISPUTE', severity: 'high', message: `${no} of ${checks.length} students say this lesson was not taught.` });
    }
  }

  return flags;
}

function statusFromFlags(flags, currentStatus) {
  // An admin decision stays unless students start disputing afterwards.
  if (currentStatus === 'confirmed') return 'confirmed';
  if (currentStatus === 'dismissed' && !flags.some((f) => f.code === 'STUDENTS_DISPUTE')) return 'dismissed';
  const high = flags.some((f) => f.severity === 'high');
  const others = flags.filter((f) => f.severity !== 'high' && f.severity !== 'low').length + Math.min(1, flags.filter((f) => f.severity === 'low').length);
  return high || others >= 2 ? 'flagged' : 'ok';
}

/** Recomputes and saves flags/status of a coverage document. */
async function evaluate(cov) {
  cov.flags = await computeFlags(cov);
  cov.status = statusFromFlags(cov.flags, cov.status);
  await cov.save();
  return cov;
}

/** A bulk mark also makes the earlier marks of that burst suspicious. */
async function reevaluateBurst(cov) {
  const markedAt = cov.createdAt || new Date();
  const others = await LessonCoverage.find({
    _id: { $ne: cov._id },
    teacherId: cov.teacherId,
    classroomId: cov.classroomId,
    createdAt: { $gte: new Date(markedAt - BULK_WINDOW_MS) },
  });
  for (const o of others) await evaluate(o);
}

module.exports = { computeFlags, statusFromFlags, evaluate, reevaluateBurst };
