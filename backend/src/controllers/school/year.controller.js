/**
 * Login cards and year-end promotion.
 *
 *   POST /school/classes/:classId/login-cards { studentIds? }
 *        New PINs for the class (or the chosen students) to print on cards.
 *   GET  /schools/:schoolId/promotion/preview?fromYear=
 *        Classes of the year with the suggested next class (S3 A → S4 A, S6 → graduate).
 *   POST /schools/:schoolId/promotion
 *        Moves students into next year's classes, keeps repeaters at their level,
 *        marks graduates/leavers, copies subjects + teachers, archives old classes.
 */
const School = require('../../models/School');
const Classroom = require('../../models/Classroom');
const ClassSubject = require('../../models/ClassSubject');
const User = require('../../models/User');
const cred = require('../../services/school/credentials.service');
const access = require('../../services/school/accessPolicy.service');
const { classroomAccess } = require('../../services/school/access.service');
const { HttpError, ok, wrap, requireId, schoolFor } = require('./helpers');

const LEVEL_ORDER = ['N1', 'N2', 'N3', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6'];
const TVET_ORDER = ['L3', 'L4', 'L5'];

/** Next level, or null when students finish (graduate) at this level. */
function nextLevel(level, schoolLevels = []) {
  const L = String(level || '').toUpperCase();
  for (const order of [LEVEL_ORDER, TVET_ORDER]) {
    const i = order.indexOf(L);
    if (i < 0) continue;
    const next = order[i + 1];
    if (!next) return null;
    // A school that does not teach the next level: the class leaves (e.g. P6 in a primary school).
    if (schoolLevels.length && !schoolLevels.map((x) => String(x).toUpperCase()).includes(next)) return null;
    return next;
  }
  return null;
}

/** "2026" → "2027", "2025-2026" → "2026-2027". */
function nextYear(y) {
  const s = String(y || '');
  const m = s.match(/^(\d{4})-(\d{4})$/);
  if (m) return `${+m[1] + 1}-${+m[2] + 1}`;
  if (/^\d{4}$/.test(s)) return String(+s + 1);
  return s;
}

// ── Login cards ──────────────────────────────────────────────────────────

const loginCards = wrap(async (req, res) => {
  requireId(req.params.classId, 'class id');
  const room = await Classroom.findById(req.params.classId);
  if (!room || !room.isActive) throw new HttpError('Class not found', 404);
  const a = await classroomAccess(req.user, room);
  if (!a.canManageRoster) throw new HttpError('Only the class teacher or the school office can print login cards.', 403);
  const school = await School.findById(room.schoolId).select('name code studentAccess').lean();

  const filter = { classroomId: room._id, role: 'student', isActive: true };
  if (Array.isArray(req.body?.studentIds) && req.body.studentIds.length) filter._id = { $in: req.body.studentIds.filter((x) => /^[a-f0-9]{24}$/i.test(String(x))) };
  const students = await User.find(filter).select('+pinHash +pinFailedCount +pinLockedUntil +activeSessionId').sort({ fullName: 1 });
  if (!students.length) throw new HttpError('No students to print cards for.');

  const policy = access.policyOf(school);
  const pinless = access.isPinlessLevel(policy, room.level) && policy.mode === 'code';
  const cards = [];
  for (const st of students) {
    let pin = null;
    if (!pinless) {
      pin = cred.generatePin();
      st.pinHash = await cred.hashPin(pin);
      st.pinFailedCount = 0;
      st.pinLockedUntil = null;
      st.activeSessionId = null; // old cards stop working right away
      await st.save();
    }
    cards.push({ id: String(st._id), fullName: st.fullName, studentCode: st.studentCode, pin });
  }
  ok(res, {
    schoolName: school?.name,
    className: room.name,
    academicYear: room.academicYear,
    mode: policy.mode,
    pinless,
    cards,
  }, `${cards.length} login card${cards.length === 1 ? '' : 's'} ready`);
});

// ── Year-end promotion ───────────────────────────────────────────────────

const promotionPreview = wrap(async (req, res) => {
  const school = await schoolFor(req);
  const years = (await Classroom.distinct('academicYear', { schoolId: school._id, isActive: true })).sort();
  const fromYear = String(req.query.fromYear || years[years.length - 1] || '');
  const toYear = String(req.query.toYear || nextYear(fromYear));
  const classes = await Classroom.find({ schoolId: school._id, academicYear: fromYear, isActive: true }).sort({ level: 1, combination: 1, stream: 1 }).lean();
  const counts = await User.aggregate([
    { $match: { classroomId: { $in: classes.map((c) => c._id) }, role: 'student', isActive: true } },
    { $group: { _id: '$classroomId', n: { $sum: 1 } } },
  ]);
  const countMap = new Map(counts.map((c) => [String(c._id), c.n]));
  const existingNext = await Classroom.find({ schoolId: school._id, academicYear: toYear }).lean();

  const items = classes.map((c) => {
    const nl = nextLevel(c.level, school.levels);
    const target = nl ? { level: nl, combination: c.combination || '', stream: c.stream || '' } : null;
    const existing = target && existingNext.find((x) => x.level === target.level && (x.combination || '') === target.combination && (x.stream || '') === target.stream);
    return {
      id: String(c._id),
      name: c.name,
      level: c.level,
      combination: c.combination || '',
      stream: c.stream || '',
      studentCount: countMap.get(String(c._id)) || 0,
      suggested: target
        ? { action: 'promote', ...target, name: Classroom.buildName(target), exists: !!existing }
        : { action: 'graduate' },
      // S3 → S4 usually needs a combination (MPC, PCB…) chosen per student group.
      needsCombination: !!(nl && ['S4', 'S5', 'S6'].includes(nl) && !c.combination),
    };
  });
  ok(res, { fromYear, toYear, years, combinations: school.combinations || [], classes: items });
});

/**
 * POST /schools/:schoolId/promotion
 * { fromYear, toYear, copySubjects = true, archiveOld = true,
 *   plan: [{ classId, action: 'promote'|'graduate'|'skip', toLevel?, toCombination?, toStream?,
 *            repeaterIds?: [], leaverIds?: [],
 *            moves?: [{ studentId, toCombination?, toStream? }] }] }
 *
 * `moves` regroups students: they go up to the same next level as their class
 * but into another combination / stream (S3 A → S4 MS-PURE B). Students of
 * different classes sent to the same place end up in the same new class.
 */
const runPromotion = wrap(async (req, res) => {
  const school = await schoolFor(req);
  const b = req.body || {};
  const fromYear = String(b.fromYear || '').trim();
  const toYear = String(b.toYear || '').trim();
  if (!fromYear || !toYear || fromYear === toYear) throw new HttpError('Choose the year to close and the new year.');
  if (!Array.isArray(b.plan) || !b.plan.length) throw new HttpError('Nothing to do.');
  const copySubjects = b.copySubjects !== false;
  const archiveOld = b.archiveOld !== false;
  const summary = { promoted: 0, regrouped: 0, repeated: 0, graduated: 0, left: 0, classesCreated: 0, subjectsCopied: 0, classesArchived: 0 };
  const now = new Date();

  async function targetClass({ level, combination, stream }, from) {
    const spec = { schoolId: school._id, academicYear: toYear, level: String(level).toUpperCase(), combination: String(combination || '').toUpperCase(), stream: String(stream || '').toUpperCase() };
    let t = await Classroom.findOne(spec);
    if (!t) {
      t = await Classroom.create({ ...spec, room: from.room, capacity: from.capacity });
      summary.classesCreated += 1;
      if (spec.combination) await School.updateOne({ _id: school._id }, { $addToSet: { combinations: spec.combination } });
    } else if (!t.isActive) {
      t.isActive = true;
      await t.save();
    }
    if (copySubjects && !(await ClassSubject.exists({ classroomId: t._id }))) {
      const subs = await ClassSubject.find({ classroomId: from._id, isActive: true }).lean();
      // Same level (repeaters): copy everything. Next level: keep subjects + teachers, drop the syllabus link (a new course applies).
      const sameLevel = t.level === from.level;
      for (const s of subs) {
        await ClassSubject.create({ schoolId: school._id, classroomId: t._id, subject: s.subject, teacherId: s.teacherId, courseId: sameLevel ? s.courseId : null, periodsPerWeek: s.periodsPerWeek });
        summary.subjectsCopied += 1;
      }
    }
    return t;
  }

  for (const item of b.plan) {
    requireId(item.classId, 'class id');
    const from = await Classroom.findOne({ _id: item.classId, schoolId: school._id, academicYear: fromYear });
    if (!from) throw new HttpError('A class in the plan is not part of this school year.', 404);
    if (item.action === 'skip') continue;
    const students = await User.find({ classroomId: from._id, role: 'student', isActive: true }).select('_id').lean();
    const ids = new Set(students.map((s) => String(s._id)));
    const repeaters = (item.repeaterIds || []).map(String).filter((x) => ids.has(x));
    const leavers = (item.leaverIds || []).map(String).filter((x) => ids.has(x) && !repeaters.includes(x));
    // Students sent to another combination / stream (only when the class moves up).
    const moves = item.action === 'promote' && Array.isArray(item.moves)
      ? item.moves.filter((m) => m && ids.has(String(m.studentId)) && !repeaters.includes(String(m.studentId)) && !leavers.includes(String(m.studentId)))
      : [];
    const movedIds = new Set(moves.map((m) => String(m.studentId)));
    const moving = [...ids].filter((x) => !repeaters.includes(x) && !leavers.includes(x) && !movedIds.has(x));

    if (leavers.length) {
      await User.updateMany({ _id: { $in: leavers } }, { isActive: false, leftReason: 'left', leftAt: now, activeSessionId: null });
      summary.left += leavers.length;
    }
    if (repeaters.length) {
      const same = await targetClass({ level: from.level, combination: from.combination, stream: from.stream }, from);
      await User.updateMany({ _id: { $in: repeaters } }, { classroomId: same._id });
      summary.repeated += repeaters.length;
    }
    if (item.action === 'graduate') {
      if (moving.length) {
        await User.updateMany({ _id: { $in: moving } }, { isActive: false, leftReason: 'graduated', leftAt: now, activeSessionId: null });
        summary.graduated += moving.length;
      }
    } else if (item.action === 'promote') {
      const level = item.toLevel || nextLevel(from.level, school.levels);
      if (!level) throw new HttpError(`Choose where ${from.name} goes (or graduate it).`);
      const target = await targetClass({
        level,
        combination: item.toCombination !== undefined ? item.toCombination : from.combination,
        stream: item.toStream !== undefined ? item.toStream : from.stream,
      }, from);
      if (moving.length) {
        await User.updateMany({ _id: { $in: moving } }, { classroomId: target._id });
        summary.promoted += moving.length;
      }
      // Regrouped students, one target class per (combination, stream).
      const groups = new Map();
      for (const m of moves) {
        const combination = String(m.toCombination ?? target.combination ?? '').trim().toUpperCase().slice(0, 20);
        const stream = String(m.toStream ?? target.stream ?? '').trim().toUpperCase().slice(0, 10);
        const key = `${combination}|${stream}`;
        if (!groups.has(key)) groups.set(key, { combination, stream, ids: [] });
        groups.get(key).ids.push(String(m.studentId));
      }
      for (const g of groups.values()) {
        const t = await targetClass({ level, combination: g.combination, stream: g.stream }, from);
        await User.updateMany({ _id: { $in: g.ids } }, { classroomId: t._id });
        summary.promoted += g.ids.length;
        summary.regrouped += g.ids.length;
      }
    } else {
      throw new HttpError(`Unknown action "${item.action}".`);
    }
    if (archiveOld) {
      from.isActive = false;
      await from.save();
      summary.classesArchived += 1;
    }
  }
  ok(res, { summary, fromYear, toYear }, 'New school year ready');
});

module.exports = { loginCards, promotionPreview, runPromotion, nextLevel, nextYear };
