/**
 * School management API (mounted at /api).
 *
 *   /api/schools/...           super admin + school-scoped management ('me' = own school)
 *   /api/school/classes/...    one class / class subjects
 *   /api/school/teaching/...   teacher portal (coverage, homework, grading)
 *   /api/school/learning/...   student portal
 *   /api/school/parent/...     parent portal
 *
 * Every route carries its own middleware (this router is mounted at /api).
 */
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
const schools = require('../controllers/school/schools.controller');
const classes = require('../controllers/school/classes.controller');
const members = require('../controllers/school/members.controller');
const reports = require('../controllers/school/reports.controller');
const teaching = require('../controllers/school/teaching.controller');
const learner = require('../controllers/school/learner.controller');
const accessCodes = require('../controllers/school/access.controller');
const groups = require('../controllers/school/groups.controller');
const year = require('../controllers/school/year.controller');
const studentReports = require('../controllers/school/studentReports.controller');

const superAdmin = [protect, authorize('admin')];
const managers = [protect, authorize('admin', 'school_admin')];
const staff = [protect, authorize('admin', 'school_admin', 'instructor')];
const anyMember = [protect, authorize('admin', 'school_admin', 'instructor', 'student', 'parent')];
const students = [protect, authorize('student')];
const parents = [protect, authorize('parent')];

// ── Schools ─────────────────────────────────────────────────────────────
router.post('/schools', ...superAdmin, schools.createSchool);
router.get('/schools', ...superAdmin, schools.listSchools);
router.get('/schools/:schoolId', ...anyMember, schools.getSchool);
router.patch('/schools/:schoolId', ...managers, schools.updateSchool);
router.delete('/schools/:schoolId', ...superAdmin, schools.deleteSchool);
router.patch('/schools/:schoolId/main-admin', ...superAdmin, members.setMainAdmin);

// Courses offered free to school students, by class level (super admin)
const schoolCourses = require('../controllers/school/courses.controller');
router.get('/schools-courses', ...superAdmin, schoolCourses.listCourses);
router.patch('/schools-courses/:courseId', ...superAdmin, schoolCourses.updateCourseAccess);

// Terms & billing (per student per term)
router.get('/schools/:schoolId/terms', ...staff, schools.listTerms);
router.post('/schools/:schoolId/terms', ...managers, schools.createTerm);
router.patch('/schools/:schoolId/terms/:termId', ...managers, schools.updateTerm);
router.delete('/schools/:schoolId/terms/:termId', ...managers, schools.deleteTerm);

// Head teacher / director of studies
router.get('/schools/:schoolId/overview', ...managers, reports.overview);
router.get('/schools/:schoolId/progress', ...managers, reports.progress);
router.get('/schools/:schoolId/coverage', ...managers, reports.listCoverage);
router.patch('/schools/:schoolId/coverage/:id', ...managers, reports.reviewCoverage);
router.get('/schools/:schoolId/teachers/:userId/activity', ...managers, reports.teacherActivity);
router.get('/schools/:schoolId/results', ...managers, reports.results);
router.get('/schools/:schoolId/sign-ins', ...managers, reports.signIns);
router.get('/schools/:schoolId/report', ...managers, studentReports.schoolReport);

// Classes
router.get('/schools/:schoolId/classes', ...staff, classes.listClasses);
router.post('/schools/:schoolId/classes', ...managers, classes.createClasses);
router.get('/school/classes/:classId', ...staff, classes.getClass);
router.patch('/school/classes/:classId', ...managers, classes.updateClass);
router.delete('/school/classes/:classId', ...managers, classes.deleteClass);
router.post('/school/classes/:classId/subjects', ...managers, classes.addSubjects);
router.patch('/school/class-subjects/:id', ...managers, classes.updateSubject);
router.delete('/school/class-subjects/:id', ...managers, classes.removeSubject);
router.post('/school/classes/:classId/login-cards', ...staff, year.loginCards);
router.get('/school/classes/:classId/report', ...staff, studentReports.classReport);

// Year-end promotion
router.get('/schools/:schoolId/promotion/preview', ...managers, year.promotionPreview);
router.post('/schools/:schoolId/promotion', ...managers, year.runPromotion);

// Members
router.get('/schools/:schoolId/staff', ...staff, members.listStaff);
router.post('/schools/:schoolId/teachers', ...managers, members.addTeacher);
router.post('/schools/:schoolId/admins', ...managers, members.addSchoolAdmin);
router.get('/schools/:schoolId/students', ...staff, members.listStudents);
router.get('/schools/:schoolId/students/lookup', ...staff, members.lookupStudents);
router.post('/schools/:schoolId/students', ...staff, members.addStudent);
router.post('/schools/:schoolId/students/import', ...staff, members.importStudents);
router.post('/schools/:schoolId/students/:userId/enroll', ...staff, members.enrollExistingStudent);
router.get('/schools/:schoolId/members/:userId', ...staff, members.getMember);
router.get('/schools/:schoolId/students/:userId/report', ...staff, studentReports.studentReport);
router.patch('/schools/:schoolId/members/:userId', ...staff, members.updateMember);
router.post('/schools/:schoolId/members/:userId/reset-credentials', ...staff, members.resetCredentials);
router.get('/schools/:schoolId/parents', ...managers, members.listParents);
router.post('/schools/:schoolId/parents/:userId/reset-pin', ...managers, members.resetParentPin);

// Sign-in codes ("School only" schools) and the caller's internet address
router.get('/school/access-code', ...staff, accessCodes.currentAccessCode);
router.get('/school/my-ip', ...staff, accessCodes.myIp);

// ── Teacher portal ──────────────────────────────────────────────────────
router.get('/school/teaching/me', ...staff, teaching.myTeaching);
router.get('/school/teaching/class-subjects/:id/syllabus', ...staff, teaching.syllabus);
router.post('/school/teaching/class-subjects/:id/coverage', ...staff, teaching.markTaught);
router.delete('/school/teaching/coverage/:id', ...staff, teaching.unmarkTaught);
router.get('/school/teaching/class-subjects/:id/assessments', ...staff, teaching.listAssessments);
router.post('/school/teaching/class-subjects/:id/assessments', ...staff, teaching.createAssessment);
router.get('/school/teaching/assessments/:id', ...staff, teaching.getAssessment);
router.patch('/school/teaching/assessments/:id', ...staff, teaching.updateAssessment);
router.delete('/school/teaching/assessments/:id', ...staff, teaching.deleteAssessment);
router.post('/school/teaching/assessments/:id/submissions/:subId/grade', ...staff, teaching.gradeSubmission);

// ── Class groups (school community): teachers create, students discuss ──
const groupMembers = [protect, authorize('admin', 'school_admin', 'instructor', 'student')];
router.get('/school/groups', ...groupMembers, groups.myGroups);
router.post('/school/groups', ...staff, groups.createGroup);
router.get('/school/groups/:id', ...groupMembers, groups.getGroup);
router.patch('/school/groups/:id', ...staff, groups.updateGroup);
router.delete('/school/groups/:id', ...staff, groups.archiveGroup);
router.get('/school/groups/:id/messages', ...groupMembers, groups.listMessages);
router.post('/school/groups/:id/messages', ...groupMembers, groups.postMessage);
router.delete('/school/groups/:id/messages/:messageId', ...groupMembers, groups.deleteMessage);
router.post('/school/groups/:id/messages/:messageId/pin', ...staff, groups.pinMessage);

// ── Student portal ──────────────────────────────────────────────────────
router.get('/school/learning/home', ...students, learner.studentHome);
router.get('/school/learning/assessments/:id', ...students, learner.studentAssessment);
router.post('/school/learning/assessments/:id/submit', ...students, learner.submitAssessment);
router.post('/school/learning/coverage/:id/check', ...students, learner.checkLesson);

// ── Parent portal ───────────────────────────────────────────────────────
router.get('/school/parent/children', ...parents, learner.parentChildren);
router.get('/school/parent/children/:id', ...parents, learner.parentChild);
router.get('/school/parent/children/:id/assessments/:aid', ...parents, learner.parentAssessment);
router.post('/school/parent/children/:id/assessments/:aid/submit', ...parents, learner.parentSubmit);
router.post('/school/parent/children/:id/assessments/:aid/eexams', ...parents, learner.parentOpenExam);

module.exports = router;
