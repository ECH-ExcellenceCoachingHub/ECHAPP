const User = require('../models/User');
const School = require('../models/School');
const admin = require('../config/firebase');
const { sendSuccess, sendError } = require('../utils/response.utils');

const escapeRegex = (string) => string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** True when the caller may manage the given school (super admin or member of it). */
const assertSchoolAccess = (user, schoolId) => {
  if (user.role === 'admin') return true;
  if (!user.schoolId) return false;
  return user.schoolId.toString() === schoolId.toString() &&
    (user.role === 'school_admin' || user.role === 'instructor');
};

/** POST /api/admin/schools — super admin creates a school + its school admin user */
const createSchool = async (req, res) => {
  try {
    const { name, description, adminFullName, adminEmail, adminPhone, adminPassword, plan, studentLimit } = req.body;

    if (!name || !adminFullName || !adminEmail) {
      return sendError(res, 'School name, admin full name and admin email are required', 400);
    }

    const existing = await User.findOne({ email: adminEmail.toLowerCase() });
    if (existing) return sendError(res, 'A user with this email already exists', 409);

    // Firebase account so the school admin can log in to the app
    let firebaseUid = null;
    try {
      const firebaseUser = await admin.auth().createUser({
        email: adminEmail,
        password: adminPassword || 'Echapp2026!SchoolAdmin',
        displayName: adminFullName,
        phoneNumber: adminPhone && adminPhone.startsWith('+') ? adminPhone : undefined,
      });
      await admin.auth().setCustomUserClaims(firebaseUser.uid, { role: 'school_admin' });
      firebaseUid = firebaseUser.uid;
    } catch (firebaseError) {
      console.error('Firebase school admin creation error:', firebaseError.message);
    }

    const school = await School.create({
      name,
      description,
      admin: null,
      plan: plan || 'free',
      studentLimit: studentLimit != null ? parseInt(studentLimit, 10) : 50,
      isActive: true,
    });

    const userData = {
      fullName: adminFullName,
      email: adminEmail.toLowerCase(),
      phone: adminPhone || undefined,
      password: adminPassword || undefined,
      role: 'school_admin',
      schoolId: school._id,
      isVerified: true,
      isActive: true,
    };
    if (firebaseUid) userData.firebaseUid = firebaseUid;

    const schoolAdmin = await User.create(userData);

    school.admin = schoolAdmin._id;
    await school.save();

    sendSuccess(res, {
      school: {
        id: school._id,
        name: school.name,
        plan: school.plan,
        studentLimit: school.studentLimit,
        studentCount: 0,
        isActive: school.isActive,
      },
      schoolAdmin: {
        id: schoolAdmin._id,
        fullName: schoolAdmin.fullName,
        email: schoolAdmin.email,
        phone: schoolAdmin.phone,
        role: schoolAdmin.role,
      },
    }, 'School and school admin created successfully', 201);
  } catch (error) {
    if (error.code === 11000) {
      return sendError(res, 'This email is already in use', 409);
    }
    sendError(res, 'Failed to create school', 500, error.message);
  }
};

/** GET /api/admin/schools — list all schools with stats */
const getSchools = async (req, res) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const filter = {};
    if (search) {
      filter.$or = [
        { name: { $regex: escapeRegex(search), $options: 'i' } },
        { description: { $regex: escapeRegex(search), $options: 'i' } },
      ];
    }

    const schools = await School.find(filter)
      .populate('admin', 'fullName email phone isActive')
      .limit(parseInt(limit, 10))
      .skip((parseInt(page, 10) - 1) * parseInt(limit, 10))
      .sort({ createdAt: -1 });
    const total = await School.countDocuments(filter);

    const schoolsWithStats = await Promise.all(schools.map(async (s) => {
      const studentCount = await User.countDocuments({ role: 'student', schoolId: s._id });
      const teacherCount = await User.countDocuments({ role: 'instructor', schoolId: s._id });
      return {
        ...s.toObject(),
        id: s._id,
        studentCount,
        teacherCount,
      };
    }));

    sendSuccess(res, {
      schools: schoolsWithStats,
      totalPages: Math.ceil(total / parseInt(limit, 10)),
      currentPage: parseInt(page, 10),
      total,
    }, 'Schools retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve schools', 500, error.message);
  }
};

/** GET /api/admin/schools/:id — school detail (super admin or member of the school) */
const getSchool = async (req, res) => {
  try {
    const { id } = req.params;
    const school = await School.findById(id).populate('admin', 'fullName email phone isActive');
    if (!school) return sendError(res, 'School not found', 404);

    if (!assertSchoolAccess(req.user, school._id)) {
      return sendError(res, 'Access denied. You are not associated with this school.', 403);
    }

    const studentCount = await User.countDocuments({ role: 'student', schoolId: school._id });
    const teacherCount = await User.countDocuments({ role: 'instructor', schoolId: school._id });

    sendSuccess(res, {
      school: {
        ...school.toObject(),
        id: school._id,
        studentCount,
        teacherCount,
      },
    }, 'School retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve school', 500, error.message);
  }
};

/** PATCH /api/admin/schools/:id/plan — super admin updates plan & student limit */
const updateSchoolPlan = async (req, res) => {
  try {
    const { id } = req.params;
    const { plan, studentLimit } = req.body;

    if (!plan || !['free', 'basic', 'premium'].includes(plan)) {
      return sendError(res, 'Invalid plan (free, basic, premium)', 400);
    }

    const school = await School.findById(id);
    if (!school) return sendError(res, 'School not found', 404);

    school.plan = plan;
    if (studentLimit != null) {
      const parsed = parseInt(studentLimit, 10);
      if (parsed < 0) return sendError(res, 'Student limit cannot be negative', 400);
      school.studentLimit = parsed;
    }
    await school.save();

    sendSuccess(res, {
      school: {
        id: school._id,
        name: school.name,
        plan: school.plan,
        studentLimit: school.studentLimit,
        studentCount: school.studentCount,
      },
    }, 'School plan updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update school plan', 500, error.message);
  }
};

/** PATCH /api/admin/schools/:id/details — update name & description */
const updateSchoolDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description } = req.body;

    if (!name || name.trim().length === 0) {
      return sendError(res, 'School name is required', 400);
    }

    const school = await School.findById(id);
    if (!school) return sendError(res, 'School not found', 404);

    school.name = name.trim();
    if (description !== undefined) school.description = description.trim() || null;
    await school.save();

    sendSuccess(res, {
      school: {
        id: school._id,
        name: school.name,
        description: school.description,
        plan: school.plan,
        studentLimit: school.studentLimit,
      },
    }, 'School details updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update school details', 500, error.message);
  }
};

/** PATCH /api/admin/schools/:id/admin — change school admin */
const changeSchoolAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    const { adminId } = req.body;

    if (!adminId) {
      return sendError(res, 'Admin user ID is required', 400);
    }

    const school = await School.findById(id);
    if (!school) return sendError(res, 'School not found', 404);

    const newAdmin = await User.findOne({ _id: adminId, role: 'school_admin', schoolId: id });
    if (!newAdmin) return sendError(res, 'School admin not found in this school', 404);

    school.admin = newAdmin._id;
    await school.save();

    sendSuccess(res, {
      school: {
        id: school._id,
        name: school.name,
        admin: {
          id: newAdmin._id,
          fullName: newAdmin.fullName,
          email: newAdmin.email,
        },
      },
    }, 'School admin changed successfully');
  } catch (error) {
    sendError(res, 'Failed to change school admin', 500, error.message);
  }
};

/** GET /api/admin/schools/me — the school of the logged-in school admin / instructor */
const getMySchool = async (req, res) => {
  try {
    if (!req.user.schoolId) {
      return sendError(res, 'Your account is not associated with any school', 404);
    }

    const school = await School.findById(req.user.schoolId).populate('admin', 'fullName email phone isActive');
    if (!school) return sendError(res, 'School not found', 404);

    // Members can only see their own school
    if (req.user.role !== 'admin' && !assertSchoolAccess(req.user, school._id)) {
      return sendError(res, 'Access denied. You are not associated with this school.', 403);
    }

    const studentCount = await User.countDocuments({ role: 'student', schoolId: school._id });
    const teacherCount = await User.countDocuments({ role: 'instructor', schoolId: school._id });

    sendSuccess(res, {
      school: {
        ...school.toObject(),
        id: school._id,
        studentCount,
        teacherCount,
      },
    }, 'School retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve school', 500, error.message);
  }
};
const deleteSchool = async (req, res) => {
  try {
    const { id } = req.params;

    const school = await School.findById(id);
    if (!school) return sendError(res, 'School not found', 404);

    // Prevent deleting a school that still has members
    const memberCount = await User.countDocuments({ schoolId: school._id });
    if (memberCount > 0) {
      return sendError(res, 'Cannot delete a school that still has members. Remove all teachers and students first.', 400);
    }

    await School.findByIdAndDelete(id);

    sendSuccess(res, { id }, 'School deleted successfully');
  } catch (error) {
    sendError(res, 'Failed to delete school', 500, error.message);
  }
};

/** POST /api/admin/schools/:id/teachers — add a teacher to the school */
const addTeacher = async (req, res) => {
  try {
    const { id: schoolId } = req.params;
    const { fullName, email, phone, password } = req.body;

    if (!assertSchoolAccess(req.user, schoolId)) {
      return sendError(res, 'Access denied. You can only add teachers to your own school.', 403);
    }
    if (req.user.role === 'instructor') {
      return sendError(res, 'Teachers cannot add other teachers.', 403);
    }

    if (!fullName || (!email && !phone)) {
      return sendError(res, 'Full name and at least one contact method (email or phone) required', 400);
    }

    const existingQuery = [];
    if (email) existingQuery.push({ email });
    if (phone) existingQuery.push({ phone });
    const existingUser = await User.findOne({ $or: existingQuery });
    if (existingUser) return sendError(res, 'A user with this email or phone already exists', 409);

    const school = await School.findById(schoolId);
    if (!school) return sendError(res, 'School not found', 404);
    if (!school.isActive) return sendError(res, 'This school is deactivated', 403);

    let firebaseUid = null;
    if (email && password) {
      try {
        const e164Phone = phone && phone.startsWith('+') ? phone : undefined;
        const firebaseUser = await admin.auth().createUser({
          email,
          password,
          displayName: fullName,
          phoneNumber: e164Phone,
        });
        await admin.auth().setCustomUserClaims(firebaseUser.uid, { role: 'instructor' });
        firebaseUid = firebaseUser.uid;
      } catch (firebaseError) {
        console.error('Firebase teacher creation error:', firebaseError.message);
      }
    }

    const userData = {
      fullName,
      email: email || undefined,
      phone: phone || undefined,
      password: password || undefined,
      role: 'instructor',
      schoolId: school._id,
      isVerified: true,
      isActive: true,
    };
    if (firebaseUid) userData.firebaseUid = firebaseUid;

    const teacher = await User.create(userData);

    sendSuccess(res, {
      id: teacher._id,
      firebaseUid: teacher.firebaseUid,
      fullName: teacher.fullName,
      email: teacher.email,
      phone: teacher.phone,
      role: teacher.role,
      schoolId: teacher.schoolId,
    }, 'Teacher added to school successfully', 201);
  } catch (error) {
    if (error.code === 11000) {
      return sendError(res, 'A user with this email or phone already exists', 409);
    }
    sendError(res, 'Failed to add teacher', 500, error.message);
  }
};

/** GET /api/admin/schools/:id/teachers — list teachers of the school */
const getTeachers = async (req, res) => {
  try {
    const { id: schoolId } = req.params;
    const { page = 1, limit = 20, search } = req.query;

    if (!assertSchoolAccess(req.user, schoolId)) {
      return sendError(res, 'Access denied. You can only view teachers of your own school.', 403);
    }

    const filter = { role: 'instructor', schoolId };
    if (search) {
      filter.$or = [
        { fullName: { $regex: escapeRegex(search), $options: 'i' } },
        { email: { $regex: escapeRegex(search), $options: 'i' } },
      ];
    }

    const teachers = await User.find(filter)
      .select('-password')
      .limit(parseInt(limit, 10))
      .skip((parseInt(page, 10) - 1) * parseInt(limit, 10))
      .sort({ createdAt: -1 });
    const total = await User.countDocuments(filter);

    sendSuccess(res, {
      teachers: teachers.map(t => ({ ...t.toObject(), id: t._id })),
      totalPages: Math.ceil(total / parseInt(limit, 10)),
      currentPage: parseInt(page, 10),
      total,
    }, 'School teachers retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve teachers', 500, error.message);
  }
};

/** POST /api/admin/schools/:id/students — add a student to the school */
const addStudent = async (req, res) => {
  try {
    const { id: schoolId } = req.params;
    const { fullName, email, phone, password } = req.body;

    if (!assertSchoolAccess(req.user, schoolId)) {
      return sendError(res, 'Access denied. You can only add students to your own school.', 403);
    }

    if (!fullName || (!email && !phone)) {
      return sendError(res, 'Full name and at least one contact method (email or phone) required', 400);
    }

    const school = await School.findById(schoolId);
    if (!school) return sendError(res, 'School not found', 404);
    if (!school.isActive) return sendError(res, 'This school is deactivated', 403);

    // Enforce the paid student limit
    const currentCount = await User.countDocuments({ role: 'student', schoolId: school._id });
    if (currentCount >= school.studentLimit) {
      return sendError(
        res,
        `Student limit reached (${school.studentLimit}/${school.studentLimit}). Upgrade the school plan to admit more students.`,
        403
      );
    }

    const existingQuery = [];
    if (email) existingQuery.push({ email });
    if (phone) existingQuery.push({ phone });
    const existingUser = await User.findOne({ $or: existingQuery });
    if (existingUser) return sendError(res, 'A user with this email or phone already exists', 409);

    let firebaseUid = null;
    if (email && password) {
      try {
        const e164Phone = phone && phone.startsWith('+') ? phone : undefined;
        const firebaseUser = await admin.auth().createUser({
          email,
          password,
          displayName: fullName,
          phoneNumber: e164Phone,
        });
        await admin.auth().setCustomUserClaims(firebaseUser.uid, { role: 'student' });
        firebaseUid = firebaseUser.uid;
      } catch (firebaseError) {
        console.error('Firebase student creation error:', firebaseError.message);
      }
    }

    const userData = {
      fullName,
      email: email || undefined,
      phone: phone || undefined,
      password: password || undefined,
      role: 'student',
      schoolId: school._id,
      isPrivateStudent: false,
      isVerified: true,
      isActive: true,
    };
    if (firebaseUid) userData.firebaseUid = firebaseUid;

    const student = await User.create(userData);

    school.studentCount = currentCount + 1;
    await school.save();

    sendSuccess(res, {
      id: student._id,
      firebaseUid: student.firebaseUid,
      fullName: student.fullName,
      email: student.email,
      phone: student.phone,
      role: student.role,
      schoolId: student.schoolId,
      isPrivateStudent: student.isPrivateStudent,
    }, 'Student added to school successfully', 201);
  } catch (error) {
    if (error.code === 11000) {
      return sendError(res, 'A user with this email or phone already exists', 409);
    }
    sendError(res, 'Failed to add student', 500, error.message);
  }
};

/** GET /api/admin/schools/:id/students — list students of the school */
const getStudents = async (req, res) => {
  try {
    const { id: schoolId } = req.params;
    const { page = 1, limit = 20, search } = req.query;

    if (!assertSchoolAccess(req.user, schoolId)) {
      return sendError(res, 'Access denied. You can only view students of your own school.', 403);
    }

    const filter = { role: 'student', schoolId };
    if (search) {
      filter.$or = [
        { fullName: { $regex: escapeRegex(search), $options: 'i' } },
        { email: { $regex: escapeRegex(search), $options: 'i' } },
      ];
    }

    const students = await User.find(filter)
      .select('-password')
      .limit(parseInt(limit, 10))
      .skip((parseInt(page, 10) - 1) * parseInt(limit, 10))
      .sort({ createdAt: -1 });
    const total = await User.countDocuments(filter);

    sendSuccess(res, {
      students: students.map(s => ({ ...s.toObject(), id: s._id })),
      totalPages: Math.ceil(total / parseInt(limit, 10)),
      currentPage: parseInt(page, 10),
      total,
    }, 'School students retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve students', 500, error.message);
  }
};

/** GET /api/admin/schools/:id/members — list all staff (school_admins + instructors) of the school */
const getSchoolMembers = async (req, res) => {
  try {
    const { id: schoolId } = req.params;
    const { page = 1, limit = 20, search } = req.query;

    if (!assertSchoolAccess(req.user, schoolId)) {
      return sendError(res, 'Access denied. You can only view members of your own school.', 403);
    }

    const filter = { schoolId, role: { $in: ['school_admin', 'instructor'] } };
    if (search) {
      filter.$or = [
        { fullName: { $regex: escapeRegex(search), $options: 'i' } },
        { email: { $regex: escapeRegex(search), $options: 'i' } },
      ];
    }

    const members = await User.find(filter)
      .select('-password')
      .limit(parseInt(limit, 10))
      .skip((parseInt(page, 10) - 1) * parseInt(limit, 10))
      .sort({ role: 1, fullName: 1 });
    const total = await User.countDocuments(filter);

    sendSuccess(res, {
      members: members.map(m => ({ ...m.toObject(), id: m._id })),
      totalPages: Math.ceil(total / parseInt(limit, 10)),
      currentPage: parseInt(page, 10),
      total,
    }, 'School members retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve school members', 500, error.message);
  }
};

module.exports = {
  createSchool,
  getSchools,
  getSchool,
  getMySchool,
  updateSchoolPlan,
  updateSchoolDetails,
  changeSchoolAdmin,
  deleteSchool,
  addTeacher,
  getTeachers,
  addStudent,
  getStudents,
  getSchoolMembers,
};
