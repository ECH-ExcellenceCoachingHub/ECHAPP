/**
 * Sign-in codes for "School only" schools.
 *   GET /api/school/access-code?classId=  — class code (teachers of the class, school admins)
 *   GET /api/school/access-code           — school-wide code for the lab (school staff)
 *   GET /api/school/my-ip                 — the address the server sees (to whitelist the school network)
 */
const School = require('../../models/School');
const Classroom = require('../../models/Classroom');
const AccessCode = require('../../models/AccessCode');
const LoginAudit = require('../../models/LoginAudit');
const access = require('../../services/school/accessPolicy.service');
const { classroomAccess, canManageSchool, isSchoolTeacher } = require('../../services/school/access.service');
const { clientIp, ipAllowed, isPrivateIp, suggestedRule } = require('../../utils/clientIp');
const { HttpError, ok, wrap, requireId } = require('./helpers');

const currentAccessCode = wrap(async (req, res) => {
  let school;
  let classroom = null;
  if (req.query.classId) {
    requireId(req.query.classId, 'class id');
    classroom = await Classroom.findById(req.query.classId);
    if (!classroom || !classroom.isActive) throw new HttpError('Class not found', 404);
    const a = await classroomAccess(req.user, classroom);
    if (!a.canView) throw new HttpError('You do not teach this class.', 403);
    school = await School.findById(classroom.schoolId);
  } else {
    const schoolId = req.query.schoolId && req.user.role === 'admin' ? req.query.schoolId : req.user.schoolId;
    if (!schoolId) throw new HttpError('Your account is not linked to a school.', 404);
    school = await School.findById(schoolId);
    if (!school) throw new HttpError('School not found', 404);
    if (!canManageSchool(req.user, school._id) && !isSchoolTeacher(req.user, school._id)) throw new HttpError('Access denied', 403);
  }
  if (!school || school.isActive === false) throw new HttpError('This school is not active.', 403);

  const policy = access.policyOf(school);
  const code = await access.currentCode({ school, classroomId: classroom?._id || null, createdBy: req.user._id });

  // Who signed in with this scope's codes today.
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const codeIds = await AccessCode.find({ schoolId: school._id, classroomId: classroom?._id || null, createdAt: { $gte: new Date(startOfDay.getTime() - 2 * 3600 * 1000) } }).distinct('_id');
  const signIns = await LoginAudit.find({ accessCodeId: { $in: codeIds }, success: true, at: { $gte: startOfDay } })
    .populate('userId', 'fullName studentCode classroomId')
    .sort({ at: -1 })
    .limit(200)
    .lean();
  const seen = new Set();
  const people = [];
  for (const s of signIns) {
    if (!s.userId || seen.has(String(s.userId._id))) continue;
    seen.add(String(s.userId._id));
    people.push({ id: String(s.userId._id), fullName: s.userId.fullName, studentCode: s.userId.studentCode, at: s.at, method: s.method });
  }

  ok(res, {
    code: code.code,
    expiresAt: code.expiresAt,
    scope: classroom ? 'class' : 'school',
    className: classroom?.name || null,
    schoolName: school.name,
    mode: policy.mode,
    codeMinutes: policy.codeMinutes,
    pinless: classroom ? access.isPinlessLevel(policy, classroom.level) : false,
    signIns: people,
  });
});

const myIp = wrap(async (req, res) => {
  const ip = clientIp(req);
  let onSchoolNetwork = null;
  if (req.user.schoolId) {
    const school = await School.findById(req.user.schoolId).select('studentAccess').lean();
    onSchoolNetwork = ipAllowed(ip, access.policyOf(school).allowedIps);
  }
  ok(res, {
    ip,
    version: ip.includes(':') ? 6 : 4,
    // What to save as "school internet" for this connection (IPv6: the whole /64 network).
    suggestedRule: suggestedRule(ip),
    // A local / private address means the server cannot see the real school address (should not happen online).
    usable: !!ip && !isPrivateIp(ip),
    onSchoolNetwork,
  });
});

module.exports = { currentAccessCode, myIp };
