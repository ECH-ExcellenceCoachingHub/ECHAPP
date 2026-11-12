/**
 * What happens when a lab attempt is finalised: score it, award XP/badges once,
 * update scenario stats and mark the linked lesson complete in the enrollment.
 */
const Enrollment = require('../../models/Enrollment');
const Lesson = require('../../models/Lesson');
const LabAttempt = require('../../models/LabAttempt');
const LabScenario = require('../../models/LabScenario');
const User = require('../../models/User');
const { scoreAttempt, badgesFor } = require('./scoring.service');

/** Same rule as enrollment.controller updateLessonProgress. */
async function markLessonComplete(userId, lessonId) {
  const lesson = await Lesson.findById(lessonId).select('courseId');
  if (!lesson) return { updated: false, reason: 'lesson-not-found' };
  const enrollment = await Enrollment.findOne({ userId, courseId: lesson.courseId });
  if (!enrollment) return { updated: false, reason: 'not-enrolled' };
  if (enrollment.accessExpirationDate && enrollment.accessExpirationDate < new Date()) return { updated: false, reason: 'expired' };
  if (enrollment.completedLessons.some((id) => id.toString() === lessonId.toString())) return { updated: false, reason: 'already-complete', progress: enrollment.progress };

  enrollment.completedLessons.push(lessonId);
  const totalLessons = await Lesson.countDocuments({ courseId: lesson.courseId });
  enrollment.progress = totalLessons > 0 ? Math.round((enrollment.completedLessons.length / totalLessons) * 100) : 0;
  if (enrollment.progress === 100) {
    enrollment.completionStatus = 'completed';
    enrollment.certificateEligible = true;
  } else if (enrollment.progress > 0 && enrollment.completionStatus !== 'completed') {
    enrollment.completionStatus = 'in-progress';
  }
  await enrollment.save();
  return { updated: true, progress: enrollment.progress };
}

async function finalizeAttempt(attempt, scenario) {
  const def = scenario.definition;
  const outcome = scoreAttempt(def, attempt);

  attempt.score = outcome.score;
  attempt.passed = outcome.passed;
  attempt.status = 'completed';
  attempt.completedAt = attempt.completedAt || new Date();

  // XP and badges only for the first passing attempt of this scenario.
  let xpAwarded = 0;
  let newBadges = [];
  let lesson = null;
  if (outcome.passed) {
    const previousPass = await LabAttempt.exists({ userId: attempt.userId, scenarioId: scenario._id, passed: true, _id: { $ne: attempt._id } });
    if (!previousPass) {
      xpAwarded = Math.round((scenario.xp || def.xp || 100) * outcome.score.total / 100);
      const passedScenarioIds = await LabAttempt.distinct('scenarioId', { userId: attempt.userId, passed: true, _id: { $ne: attempt._id } });
      const passedScenarios = await LabScenario.find({ _id: { $in: passedScenarioIds } }).select('subject');
      const passedSubjects = passedScenarios.reduce((m, s) => { m[s.subject] = (m[s.subject] || 0) + 1; return m; }, {});
      const user = await User.findById(attempt.userId).select('labBadges labXp');
      const owned = new Set((user?.labBadges || []).map((b) => b.key));
      newBadges = badgesFor({ def, outcome, passedSubjects, firstLab: passedScenarioIds.length === 0 }).filter((b) => !owned.has(b));
      await User.updateOne(
        { _id: attempt.userId },
        { $inc: { labXp: xpAwarded }, $push: { labBadges: { $each: newBadges.map((key) => ({ key, awardedAt: new Date() })) } } },
      );
    }
    if (attempt.lessonId) lesson = await markLessonComplete(attempt.userId, attempt.lessonId);
  }
  attempt.xpAwarded = xpAwarded;
  await attempt.save();

  // Running stats for teachers.
  const s = scenario.stats || { attempts: 0, completions: 0, avgScore: 0 };
  const completions = (s.completions || 0) + 1;
  await LabScenario.updateOne({ _id: scenario._id }, {
    $set: { 'stats.completions': completions, 'stats.avgScore': Math.round(((s.avgScore || 0) * (completions - 1) + outcome.score.total) / completions) },
  });

  return { ...outcome, xpAwarded, newBadges, lesson };
}

module.exports = { finalizeAttempt, markLessonComplete };
