/**
 * Who may do what inside a school.
 *
 *   super admin (role admin)  — everything, every school
 *   school admin              — everything in their own school
 *   class teacher             — their class: roster (add students), all subjects' progress
 *   subject teacher           — the classes/subjects they teach (ClassSubject)
 *   student                   — their own class, homework, results
 *   parent                    — their children
 */
const Classroom = require('../../models/Classroom');
const ClassSubject = require('../../models/ClassSubject');

// Compares ids that may be ObjectIds, strings or populated documents
// (e.g. classroom.classTeacherId after .populate()).
const idOf = (x) => (x && typeof x === 'object' && x._id ? x._id : x);
const same = (a, b) => !!(a && b) && String(idOf(a)) === String(idOf(b));

function isSuperAdmin(user) {
  return user?.role === 'admin';
}

function canManageSchool(user, schoolId) {
  if (isSuperAdmin(user)) return true;
  return user?.role === 'school_admin' && same(user.schoolId, schoolId);
}

function isSchoolTeacher(user, schoolId) {
  return user?.role === 'instructor' && same(user.schoolId, schoolId);
}

/** Everything a teacher teaches: { classTeacherOf: Classroom[], subjects: ClassSubject[] (populated classroom) }. */
async function teacherLoad(user) {
  if (!user?.schoolId) return { classTeacherOf: [], subjects: [] };
  const [classTeacherOf, subjects] = await Promise.all([
    Classroom.find({ schoolId: user.schoolId, classTeacherId: user._id, isActive: true }).lean(),
    ClassSubject.find({ schoolId: user.schoolId, teacherId: user._id, isActive: true }).populate('classroomId').lean(),
  ]);
  return { classTeacherOf, subjects: subjects.filter((s) => s.classroomId && s.classroomId.isActive !== false) };
}

/**
 * Access of `user` to a classroom: { canView, canManageRoster, isClassTeacher, subjects }.
 * School admins and the super admin can do everything.
 */
async function classroomAccess(user, classroom) {
  if (!classroom) return { canView: false, canManageRoster: false };
  if (canManageSchool(user, classroom.schoolId)) {
    return { canView: true, canManageRoster: true, isAdmin: true, isClassTeacher: false, subjects: [] };
  }
  if (!isSchoolTeacher(user, classroom.schoolId)) return { canView: false, canManageRoster: false };
  const isClassTeacher = same(classroom.classTeacherId, user._id);
  const subjects = await ClassSubject.find({ classroomId: classroom._id, teacherId: user._id, isActive: true }).lean();
  return {
    canView: isClassTeacher || subjects.length > 0,
    canManageRoster: isClassTeacher,
    isClassTeacher,
    isAdmin: false,
    subjects,
  };
}

/** Access to one subject of a class (marking coverage, giving homework, grading). */
async function classSubjectAccess(user, classSubject) {
  if (!classSubject) return { canView: false, canTeach: false };
  if (canManageSchool(user, classSubject.schoolId)) return { canView: true, canTeach: isSuperAdmin(user) || user.role === 'school_admin', isAdmin: true };
  if (!isSchoolTeacher(user, classSubject.schoolId)) return { canView: false, canTeach: false };
  const teaches = same(classSubject.teacherId, user._id);
  let isClassTeacher = false;
  if (!teaches) {
    const room = await Classroom.findById(classSubject.classroomId).select('classTeacherId').lean();
    isClassTeacher = same(room?.classTeacherId, user._id);
  }
  return { canView: teaches || isClassTeacher, canTeach: teaches, isAdmin: false };
}

module.exports = { same, isSuperAdmin, canManageSchool, isSchoolTeacher, teacherLoad, classroomAccess, classSubjectAccess };
