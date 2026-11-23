/**
 * Super admin analytics overview: one call that returns every platform KPI
 * for a period, the same KPI for the previous period of equal length (so the
 * dashboard can show real deltas), gap-filled time series and breakdowns.
 *
 * GET /api/admin/analytics/overview?days=7|30|90|365
 *
 * Sections the admin has no access to (admin limits, area 'none') are left
 * out: revenue needs 'payments', people needs 'users', schools needs
 * 'schools', learning needs 'courses'.
 */
const User = require('../models/User');
const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const Payment = require('../models/Payment');
const Result = require('../models/Result');
const Certificate = require('../models/Certificate');
const { sendSuccess, sendError } = require('../utils/response.utils');
const { hasArea, describe: describeAdminLimits } = require('../services/adminLimits.service');

const TZ = 'Africa/Kigali';
const DAY = 24 * 60 * 60 * 1000;
const PAID = ['completed', 'approved'];
const ALLOWED_DAYS = [7, 30, 90, 365];

const optionalModel = (name) => {
  try { return require(`../models/${name}`); } catch (_) { return null; }
};

const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : 0);
const round1 = (v) => Math.round(num(v) * 10) / 10;

/** Kigali calendar key for a date: YYYY-MM-DD (daily) or YYYY-MM (monthly). */
function bucketKey(date, monthly) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: TZ, year: 'numeric', month: '2-digit', day: '2-digit',
  }).formatToParts(date).reduce((acc, p) => ({ ...acc, [p.type]: p.value }), {});
  return monthly ? `${parts.year}-${parts.month}` : `${parts.year}-${parts.month}-${parts.day}`;
}

/** Every bucket key between from and to, so charts have no gaps. */
function bucketKeys(from, to, monthly) {
  const keys = [];
  const seen = new Set();
  const step = monthly ? DAY * 27 : DAY;
  for (let t = from.getTime(); t <= to.getTime() + DAY; t += step) {
    const k = bucketKey(new Date(Math.min(t, to.getTime())), monthly);
    if (!seen.has(k)) { seen.add(k); keys.push(k); }
  }
  return keys;
}

/** Groups a collection by date bucket; `fields` are extra $group accumulators. */
async function series(Model, { match, dateField, monthly, fields }) {
  const dateExpr = typeof dateField === 'string' ? `$${dateField}` : dateField;
  const rows = await Model.aggregate([
    { $match: match },
    {
      $group: {
        _id: { $dateToString: { format: monthly ? '%Y-%m' : '%Y-%m-%d', date: dateExpr, timezone: TZ } },
        count: { $sum: 1 },
        ...(fields || {}),
      },
    },
  ]);
  const map = {};
  for (const r of rows) map[r._id] = r;
  return map;
}

function fill(keys, map, pick) {
  return keys.map((k) => ({ date: k, value: map[k] ? num(pick(map[k])) : 0 }));
}

async function countBy(Model, match, field) {
  const rows = await Model.aggregate([
    { $match: match },
    { $group: { _id: `$${field}`, count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);
  return rows.map((r) => ({ label: r._id == null || r._id === '' ? 'unknown' : String(r._id), value: r.count }));
}

const getAnalyticsOverview = async (req, res) => {
  try {
    const requested = parseInt(req.query.days, 10);
    const days = ALLOWED_DAYS.includes(requested) ? requested : 30;
    const monthly = days > 90;

    const to = new Date();
    const from = new Date(to.getTime() - days * DAY);
    const prevFrom = new Date(from.getTime() - days * DAY);
    const inRange = { $gte: from, $lte: to };
    const inPrev = { $gte: prevFrom, $lt: from };
    const keys = bucketKeys(from, to, monthly);

    const user = req.user;
    const can = {
      users: hasArea(user, 'users', 'view'),
      courses: hasArea(user, 'courses', 'view'),
      payments: hasArea(user, 'payments', 'view'),
      schools: hasArea(user, 'schools', 'view'),
    };

    const out = {
      range: { days, from, to, bucket: monthly ? 'month' : 'day', timezone: TZ },
      access: describeAdminLimits(user),
      generatedAt: new Date(),
    };

    const jobs = [];

    // ---------------------------------------------------------------- people
    if (can.users) {
      jobs.push((async () => {
        const [
          byRole, studentsTotal, newStudents, newStudentsPrev, newUsers, newUsersPrev,
          dau, wau, mau, mauPrev, privateStudents, schoolStudents, verified, inactiveAccounts,
          gender, sessionAgg, signupMap, studentSignupMap, activeMap, provinces,
        ] = await Promise.all([
          countBy(User, {}, 'role'),
          User.countDocuments({ role: 'student' }),
          User.countDocuments({ role: 'student', createdAt: inRange }),
          User.countDocuments({ role: 'student', createdAt: inPrev }),
          User.countDocuments({ createdAt: inRange }),
          User.countDocuments({ createdAt: inPrev }),
          User.countDocuments({ role: 'student', lastActive: { $gte: new Date(to - DAY) } }),
          User.countDocuments({ role: 'student', lastActive: { $gte: new Date(to - 7 * DAY) } }),
          User.countDocuments({ role: 'student', lastActive: { $gte: new Date(to - 30 * DAY) } }),
          User.countDocuments({ role: 'student', lastActive: { $gte: new Date(to - 60 * DAY), $lt: new Date(to - 30 * DAY) } }),
          User.countDocuments({ role: 'student', $or: [{ schoolId: null }, { schoolId: { $exists: false } }] }),
          User.countDocuments({ role: 'student', schoolId: { $ne: null } }),
          User.countDocuments({ isVerified: true }),
          User.countDocuments({ isActive: false }),
          countBy(User, { role: 'student' }, 'gender'),
          User.aggregate([
            { $match: { role: 'student' } },
            { $group: { _id: null, seconds: { $sum: '$totalSessionTime' }, sessions: { $sum: '$sessionCount' } } },
          ]),
          series(User, { match: { createdAt: inRange }, dateField: 'createdAt', monthly }),
          series(User, { match: { role: 'student', createdAt: inRange }, dateField: 'createdAt', monthly }),
          series(User, { match: { role: 'student', lastActive: inRange }, dateField: 'lastActive', monthly }),
          countBy(User, { role: 'student', 'address.province': { $nin: [null, ''] } }, 'address.province'),
        ]);

        const roleCount = (r) => (byRole.find((x) => x.label === r) || {}).value || 0;
        const seconds = num(sessionAgg[0] && sessionAgg[0].seconds);
        const sessions = num(sessionAgg[0] && sessionAgg[0].sessions);

        out.people = {
          totalUsers: byRole.reduce((s, r) => s + r.value, 0),
          students: studentsTotal,
          teachers: roleCount('instructor'),
          parents: roleCount('parent'),
          schoolAdmins: roleCount('school_admin'),
          admins: roleCount('admin'),
          byRole,
          newStudents: { value: newStudents, previous: newStudentsPrev },
          newUsers: { value: newUsers, previous: newUsersPrev },
          privateStudents,
          schoolStudents,
          verified,
          inactiveAccounts,
          gender,
          provinces: provinces.slice(0, 8),
          signupSeries: fill(keys, signupMap, (r) => r.count),
          studentSignupSeries: fill(keys, studentSignupMap, (r) => r.count),
        };

        out.engagement = {
          dau,
          wau,
          mau: { value: mau, previous: mauPrev },
          stickiness: mau > 0 ? round1((dau / mau) * 100) : 0,
          activeRate: studentsTotal > 0 ? round1((mau / studentsTotal) * 100) : 0,
          totalStudyHours: Math.round(seconds / 3600),
          avgSessionMinutes: sessions > 0 ? Math.round(seconds / sessions / 60) : 0,
          totalSessions: sessions,
          lastActiveSeries: fill(keys, activeMap, (r) => r.count),
        };
      })());
    }

    // -------------------------------------------------------------- learning
    if (can.courses) {
      jobs.push((async () => {
        const [
          coursesTotal, coursesPublished, newCourses, enrollAgg, newEnroll, newEnrollPrev,
          completedInRange, completedPrev, enrollStatus, completionStatus, certTotal, certRange, certPrev,
          enrollMap, completionMap, topCourses, levelMix, categoryMix, ratingAgg,
          examAgg, examRange, examPrev, examMap, topStudents,
        ] = await Promise.all([
          Course.countDocuments({}),
          Course.countDocuments({ isPublished: true }),
          Course.countDocuments({ createdAt: inRange }),
          Enrollment.aggregate([
            {
              $group: {
                _id: null,
                total: { $sum: 1 },
                avgProgress: { $avg: '$progress' },
                completed: { $sum: { $cond: [{ $eq: ['$completionStatus', 'completed'] }, 1, 0] } },
                learners: { $addToSet: '$userId' },
              },
            },
            { $project: { total: 1, avgProgress: 1, completed: 1, learners: { $size: '$learners' } } },
          ]),
          Enrollment.countDocuments({ enrollmentDate: inRange }),
          Enrollment.countDocuments({ enrollmentDate: inPrev }),
          Enrollment.countDocuments({ completionStatus: 'completed', updatedAt: inRange }),
          Enrollment.countDocuments({ completionStatus: 'completed', updatedAt: inPrev }),
          countBy(Enrollment, {}, 'status'),
          countBy(Enrollment, {}, 'completionStatus'),
          Certificate.countDocuments({}),
          Certificate.countDocuments({ issuedDate: inRange }),
          Certificate.countDocuments({ issuedDate: inPrev }),
          series(Enrollment, { match: { enrollmentDate: inRange }, dateField: 'enrollmentDate', monthly }),
          series(Enrollment, { match: { completionStatus: 'completed', updatedAt: inRange }, dateField: 'updatedAt', monthly }),
          Enrollment.aggregate([
            { $match: { enrollmentDate: inRange } },
            {
              $group: {
                _id: '$courseId',
                enrollments: { $sum: 1 },
                completed: { $sum: { $cond: [{ $eq: ['$completionStatus', 'completed'] }, 1, 0] } },
                avgProgress: { $avg: '$progress' },
              },
            },
            { $sort: { enrollments: -1 } },
            { $limit: 8 },
            { $lookup: { from: 'courses', localField: '_id', foreignField: '_id', as: 'course' } },
            { $unwind: { path: '$course', preserveNullAndEmptyArrays: true } },
            {
              $project: {
                enrollments: 1, completed: 1, avgProgress: 1,
                title: { $ifNull: ['$course.title', 'Deleted course'] },
                price: '$course.price', rating: '$course.averageRating',
              },
            },
          ]),
          countBy(Course, {}, 'level'),
          Course.aggregate([
            { $group: { _id: '$category', count: { $sum: 1 } } },
            { $lookup: { from: 'categories', localField: '_id', foreignField: '_id', as: 'cat' } },
            { $project: { count: 1, name: { $ifNull: [{ $arrayElemAt: ['$cat.name', 0] }, 'Uncategorised'] } } },
            { $sort: { count: -1 } },
            { $limit: 8 },
          ]),
          Enrollment.aggregate([
            { $match: { rating: { $gte: 1 } } },
            { $group: { _id: null, avg: { $avg: '$rating' }, count: { $sum: 1 } } },
          ]),
          Result.aggregate([
            {
              $group: {
                _id: null,
                total: { $sum: 1 },
                passed: { $sum: { $cond: ['$passed', 1, 0] } },
                avgPct: {
                  $avg: {
                    $cond: [{ $gt: ['$totalScore', 0] }, { $multiply: [{ $divide: ['$score', '$totalScore'] }, 100] }, null],
                  },
                },
              },
            },
          ]),
          Result.aggregate([
            { $match: { submittedAt: inRange } },
            { $group: { _id: null, total: { $sum: 1 }, passed: { $sum: { $cond: ['$passed', 1, 0] } } } },
          ]),
          Result.countDocuments({ submittedAt: inPrev }),
          series(Result, {
            match: { submittedAt: inRange },
            dateField: 'submittedAt',
            monthly,
            fields: { passed: { $sum: { $cond: ['$passed', 1, 0] } } },
          }),
          Enrollment.aggregate([
            {
              $group: {
                _id: '$userId',
                enrollments: { $sum: 1 },
                completed: { $sum: { $cond: [{ $eq: ['$completionStatus', 'completed'] }, 1, 0] } },
                avgProgress: { $avg: '$progress' },
              },
            },
            { $sort: { completed: -1, avgProgress: -1, enrollments: -1 } },
            { $limit: 8 },
            { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'user' } },
            { $unwind: '$user' },
            {
              $project: {
                enrollments: 1, completed: 1, avgProgress: 1,
                name: '$user.fullName', email: '$user.email',
              },
            },
          ]),
        ]);

        const e = enrollAgg[0] || {};
        const ex = examAgg[0] || {};
        const exR = examRange[0] || {};
        out.learning = {
          courses: coursesTotal,
          publishedCourses: coursesPublished,
          draftCourses: coursesTotal - coursesPublished,
          newCourses,
          enrollments: num(e.total),
          learners: num(e.learners),
          newEnrollments: { value: newEnroll, previous: newEnrollPrev },
          completions: { value: completedInRange, previous: completedPrev },
          completedTotal: num(e.completed),
          completionRate: e.total ? round1((e.completed / e.total) * 100) : 0,
          avgProgress: round1(e.avgProgress),
          enrollmentsPerLearner: e.learners ? round1(e.total / e.learners) : 0,
          // Enrollments from before `status` existed are active.
          enrollmentStatus: Object.entries(enrollStatus.reduce((acc, s) => {
            const k = s.label === 'unknown' ? 'active' : s.label;
            acc[k] = (acc[k] || 0) + s.value;
            return acc;
          }, {})).map(([label, value]) => ({ label, value })).sort((a, b) => b.value - a.value),
          completionStatus,
          certificates: { total: certTotal, value: certRange, previous: certPrev },
          rating: { average: round1(ratingAgg[0] && ratingAgg[0].avg), count: num(ratingAgg[0] && ratingAgg[0].count) },
          levelMix,
          categoryMix: categoryMix.map((c) => ({ label: c.name, value: c.count })),
          topCourses: topCourses.map((c) => ({
            id: c._id, title: c.title, enrollments: c.enrollments, completed: c.completed,
            avgProgress: round1(c.avgProgress), price: num(c.price), rating: round1(c.rating),
          })),
          topStudents: topStudents.map((s) => ({
            id: s._id, name: s.name || 'Unknown', email: s.email || '',
            enrollments: s.enrollments, completed: s.completed, avgProgress: round1(s.avgProgress),
          })),
          enrollmentSeries: fill(keys, enrollMap, (r) => r.count),
          completionSeries: fill(keys, completionMap, (r) => r.count),
        };
        out.exams = {
          total: num(ex.total),
          passed: num(ex.passed),
          passRate: ex.total ? round1((ex.passed / ex.total) * 100) : 0,
          avgScore: round1(ex.avgPct),
          submissions: { value: num(exR.total), previous: examPrev },
          passRateInRange: exR.total ? round1((exR.passed / exR.total) * 100) : 0,
          series: fill(keys, examMap, (r) => r.count),
          passedSeries: fill(keys, examMap, (r) => r.passed),
        };

        // Live classes and virtual labs are optional modules.
        const LiveSession = optionalModel('LiveSession');
        const LabAttempt = optionalModel('LabAttempt');
        const [liveStatus, liveRange, liveUpcoming, labAgg] = await Promise.all([
          LiveSession ? countBy(LiveSession, {}, 'status') : [],
          LiveSession ? LiveSession.countDocuments({ scheduledAt: inRange }) : 0,
          LiveSession ? LiveSession.countDocuments({ status: 'scheduled', scheduledAt: { $gte: to } }) : 0,
          LabAttempt
            ? LabAttempt.aggregate([
              { $match: { startedAt: inRange } },
              {
                $group: {
                  _id: null,
                  attempts: { $sum: 1 },
                  completed: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
                  passed: { $sum: { $cond: ['$passed', 1, 0] } },
                  avgScore: { $avg: '$score.total' },
                  learners: { $addToSet: '$userId' },
                },
              },
              { $project: { attempts: 1, completed: 1, passed: 1, avgScore: 1, learners: { $size: '$learners' } } },
            ])
            : [],
        ]);
        const lab = labAgg[0] || {};
        out.live = {
          status: liveStatus,
          liveNow: (liveStatus.find((s) => s.label === 'live') || {}).value || 0,
          inRange: liveRange,
          upcoming: liveUpcoming,
        };
        out.labs = {
          attempts: num(lab.attempts),
          completed: num(lab.completed),
          passed: num(lab.passed),
          learners: num(lab.learners),
          avgScore: round1(lab.avgScore),
          completionRate: lab.attempts ? round1((lab.completed / lab.attempts) * 100) : 0,
        };
      })());
    }

    // --------------------------------------------------------------- revenue
    if (can.payments) {
      jobs.push((async () => {
        const paidDate = { $ifNull: ['$paymentDate', '$createdAt'] };
        const paidIn = (range) => ({
          status: { $in: PAID },
          $expr: {
            $and: [
              ...(range.$gte ? [{ $gte: [paidDate, range.$gte] }] : []),
              ...(range.$lte ? [{ $lte: [paidDate, range.$lte] }] : []),
              ...(range.$lt ? [{ $lt: [paidDate, range.$lt] }] : []),
            ],
          },
        });
        const sumOf = async (match) => {
          const r = await Payment.aggregate([{ $match: match }, { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }]);
          return { total: num(r[0] && r[0].total), count: num(r[0] && r[0].count) };
        };

        const [
          allTime, range, prev, statusMix, byMethod, byPurpose, revMap, topCourses,
          attemptsRange, failedRange, pendingReview, recent, payers,
        ] = await Promise.all([
          sumOf({ status: { $in: PAID } }),
          sumOf(paidIn(inRange)),
          sumOf(paidIn(inPrev)),
          countBy(Payment, { createdAt: inRange }, 'status'),
          Payment.aggregate([
            { $match: paidIn(inRange) },
            { $group: { _id: '$paymentMethod', total: { $sum: '$amount' }, count: { $sum: 1 } } },
            { $sort: { total: -1 } },
          ]),
          Payment.aggregate([
            { $match: paidIn(inRange) },
            { $group: { _id: { $ifNull: ['$purpose', 'course'] }, total: { $sum: '$amount' }, count: { $sum: 1 } } },
            { $sort: { total: -1 } },
          ]),
          series(Payment, {
            match: paidIn(inRange),
            dateField: paidDate,
            monthly,
            fields: { amount: { $sum: '$amount' } },
          }),
          Payment.aggregate([
            { $match: { ...paidIn(inRange), courseId: { $ne: null } } },
            { $group: { _id: '$courseId', total: { $sum: '$amount' }, count: { $sum: 1 } } },
            { $sort: { total: -1 } },
            { $limit: 6 },
            { $lookup: { from: 'courses', localField: '_id', foreignField: '_id', as: 'course' } },
            { $project: { total: 1, count: 1, title: { $ifNull: [{ $arrayElemAt: ['$course.title', 0] }, 'Deleted course'] } } },
          ]),
          Payment.countDocuments({ createdAt: inRange, paymentMethod: { $ne: 'free' } }),
          Payment.countDocuments({ createdAt: inRange, status: { $in: ['failed', 'cancelled'] } }),
          Payment.aggregate([
            { $match: { status: { $in: ['pending', 'admin_review'] } } },
            { $group: { _id: '$status', count: { $sum: 1 }, total: { $sum: '$amount' } } },
          ]),
          Payment.find({ status: { $in: PAID } })
            .sort({ paymentDate: -1, createdAt: -1 })
            .limit(8)
            .populate('userId', 'fullName email')
            .populate('courseId', 'title')
            .populate('schoolId', 'name')
            .select('amount currency paymentMethod purpose paymentDate createdAt status userId courseId schoolId')
            .lean(),
          Payment.distinct('userId', paidIn(inRange)),
        ]);

        const paidPaidRange = range.count;
        const review = (s) => pendingReview.find((p) => p._id === s) || { count: 0, total: 0 };
        out.revenue = {
          currency: 'RWF',
          allTime: allTime.total,
          paidPayments: allTime.count,
          total: { value: range.total, previous: prev.total },
          transactions: { value: range.count, previous: prev.count },
          averageOrder: range.count ? Math.round(range.total / range.count) : 0,
          payingUsers: payers.length,
          arpu: payers.length ? Math.round(range.total / payers.length) : 0,
          successRate: attemptsRange ? round1((paidPaidRange / Math.max(attemptsRange, paidPaidRange)) * 100) : 0,
          failed: failedRange,
          pending: review('pending'),
          awaitingReview: review('admin_review'),
          statusMix,
          byMethod: byMethod.map((m) => ({ label: m._id || 'unknown', value: m.total, count: m.count })),
          byPurpose: byPurpose.map((m) => ({ label: m._id || 'course', value: m.total, count: m.count })),
          topCourses: topCourses.map((c) => ({ id: c._id, title: c.title, revenue: c.total, sales: c.count })),
          series: fill(keys, revMap, (r) => r.amount),
          countSeries: fill(keys, revMap, (r) => r.count),
          recent: recent.map((p) => ({
            id: p._id,
            amount: p.amount,
            currency: p.currency || 'RWF',
            method: p.paymentMethod,
            purpose: p.purpose || 'course',
            date: p.paymentDate || p.createdAt,
            user: p.userId ? p.userId.fullName || p.userId.email : 'Unknown',
            item: p.purpose === 'school_term'
              ? (p.schoolId && p.schoolId.name) || 'School term'
              : (p.courseId && p.courseId.title) || 'Course',
          })),
        };
      })());
    }

    // --------------------------------------------------------------- schools
    if (can.schools) {
      jobs.push((async () => {
        const School = optionalModel('School');
        const Classroom = optionalModel('Classroom');
        if (!School) return;
        const [total, active, newSchools, newPrev, byPlan, byType, classrooms, topSchools, studentAgg] = await Promise.all([
          School.countDocuments({}),
          School.countDocuments({ isActive: true }),
          School.countDocuments({ createdAt: inRange }),
          School.countDocuments({ createdAt: inPrev }),
          countBy(School, {}, 'plan'),
          countBy(School, {}, 'type'),
          Classroom ? Classroom.countDocuments({ isActive: true }) : 0,
          User.aggregate([
            { $match: { role: 'student', schoolId: { $ne: null } } },
            { $group: { _id: '$schoolId', students: { $sum: 1 } } },
            { $sort: { students: -1 } },
            { $limit: 6 },
            { $lookup: { from: 'schools', localField: '_id', foreignField: '_id', as: 'school' } },
            { $unwind: '$school' },
            { $project: { students: 1, name: '$school.name', plan: '$school.plan', district: '$school.address.district' } },
          ]),
          User.countDocuments({ role: 'student', schoolId: { $ne: null } }),
        ]);
        out.schools = {
          total,
          active,
          newSchools: { value: newSchools, previous: newPrev },
          classrooms,
          students: studentAgg,
          avgStudentsPerSchool: total ? round1(studentAgg / total) : 0,
          byPlan,
          byType,
          top: topSchools.map((s) => ({ id: s._id, name: s.name, students: s.students, plan: s.plan, district: s.district || '' })),
        };
      })());
    }

    // ---------------------------------------------------------------- inbox
    jobs.push((async () => {
      const Feedback = optionalModel('Feedback');
      if (!Feedback) return;
      const [unread, inRangeCount] = await Promise.all([
        Feedback.countDocuments({ isRead: false }),
        Feedback.countDocuments({ createdAt: inRange }),
      ]);
      out.feedback = { unread, inRange: inRangeCount };
    })());

    const settled = await Promise.allSettled(jobs);
    const failures = settled.filter((s) => s.status === 'rejected');
    failures.forEach((f) => console.error('[analytics overview] section failed:', f.reason));
    out.partial = failures.length > 0;

    sendSuccess(res, out, 'Analytics overview retrieved successfully');
  } catch (error) {
    console.error('Error in getAnalyticsOverview:', error);
    sendError(res, 'Failed to retrieve analytics overview', 500, error.message);
  }
};

module.exports = { getAnalyticsOverview };
