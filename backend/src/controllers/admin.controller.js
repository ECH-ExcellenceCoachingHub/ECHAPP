const User = require('../models/User');
const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const Payment = require('../models/Payment');
const Result = require('../models/Result');
const Notification = require('../models/Notification');
const Certificate = require('../models/Certificate');
const Conversation = require('../models/Conversation');
const ChatMessage = require('../models/ChatMessage');
const { sendSuccess, sendError } = require('../utils/response.utils');
const { getStudentCourseProgress } = require('../utils/studentProgress.utils');
const admin = require('../config/firebase');

// Helper function to escape special regex characters
const escapeRegex = (string) => {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
};

// Sync Firebase user to MongoDB
const syncFirebaseUser = async (req, res) => {
  try {
    // Verify API key for security
    const apiKey = req.headers['x-api-key'];
    if (apiKey !== process.env.FIREBASE_SYNC_API_KEY) {
      return sendUnauthorized(res, 'Invalid API key');
    }
    
    const { firebaseUid, fullName, email, phone, provider, role = 'student' } = req.body;
    
    // Validate required fields
    if (!firebaseUid || !email) {
      return sendError(res, 'Firebase UID and email are required', 400);
    }
    
    // Check if user already exists
    let user = await User.findOne({ firebaseUid });
    
    if (user) {
      // Update existing user
      user.fullName = fullName || user.fullName;
      user.email = email;
      user.phone = phone || user.phone;
      user.role = role;
      user.lastLogin = new Date();
      await user.save();
      
      return sendSuccess(res, {
        id: user._id,
        firebaseUid: user.firebaseUid,
        fullName: user.fullName,
        email: user.email,
        role: user.role
      }, 'User updated successfully');
    } else {
      // Create new user
      user = await User.create({
        firebaseUid,
        fullName: fullName || 'New User',
        email,
        phone,
        role,
        provider: provider || 'firebase'
      });
      
      return sendSuccess(res, {
        id: user._id,
        firebaseUid: user.firebaseUid,
        fullName: user.fullName,
        email: user.email,
        role: user.role
      }, 'User created successfully', 201);
    }
  } catch (error) {
    sendError(res, 'Failed to sync user', 500, error.message);
  }
};

// Delete user sync
const deleteUserSync = async (req, res) => {
  try {
    const { firebaseUid } = req.params;
    
    if (!firebaseUid) {
      return sendError(res, 'Firebase UID is required', 400);
    }
    
    const user = await User.findOneAndDelete({ firebaseUid });
    
    if (!user) {
      return sendError(res, 'User not found', 404);
    }
    
    sendSuccess(res, {
      id: user._id,
      firebaseUid: user.firebaseUid,
      email: user.email
    }, 'User deleted successfully');
  } catch (error) {
    sendError(res, 'Failed to delete user', 500, error.message);
  }
};

// Get all students from Firebase with MongoDB backup
const getStudents = async (req, res) => {
  try {
    const { page = 1, limit = 20, search, source = 'firebase' } = req.query;
    
    if (source === 'firebase') {
      // Fetch from Firebase
      let firebaseUsers = [];
      let total = 0;
      
      try {
        // Get all users from Firebase
        const userList = await admin.auth().listUsers();
        let filteredUsers = userList.users.filter(user => 
          user.customClaims?.role !== 'admin'
        );
        
        // Apply search filter (name, email, or phone)
        if (search) {
          const searchLower = search.toLowerCase();
          filteredUsers = filteredUsers.filter(user => 
            (user.displayName?.toLowerCase().includes(searchLower) ||
             user.email?.toLowerCase().includes(searchLower) ||
             user.phoneNumber?.toLowerCase().includes(searchLower))
          );
        }
        
        total = filteredUsers.length;
        
        // Apply pagination
        const startIndex = (page - 1) * limit;
        const endIndex = startIndex + parseInt(limit);
        const paginatedUsers = filteredUsers.slice(startIndex, endIndex);
        
        // Transform Firebase users to match our format
        firebaseUsers = paginatedUsers.map(user => ({
          id: user.uid,
          firebaseUid: user.uid,
          fullName: user.displayName || 'Unknown User',
          email: user.email || 'No email',
          phone: user.phoneNumber,
          role: user.customClaims?.role || 'student',
          provider: user.providerData[0]?.providerId || 'unknown',
          createdAt: user.metadata.creationTime ? 
            new Date(user.metadata.creationTime) : new Date(),
          lastLogin: user.metadata.lastSignInTime ? 
            new Date(user.metadata.lastSignInTime) : null,
          emailVerified: user.emailVerified,
          disabled: user.disabled
        }));
        
        sendSuccess(res, {
          students: firebaseUsers,
          totalPages: Math.ceil(total / limit),
          currentPage: Number(page),
          total,
          source: 'firebase'
        }, 'Students retrieved from Firebase successfully');
        
      } catch (firebaseError) {
        console.error('Firebase error, falling back to MongoDB:', firebaseError.message);
        // Fallback to MongoDB
        const filter = { role: 'student' };
        
        if (search) {
          const escapedSearch = escapeRegex(search);
          filter.$or = [
            { fullName: { $regex: escapedSearch, $options: 'i' } },
            { email: { $regex: escapedSearch, $options: 'i' } },
            { phone: { $regex: escapedSearch, $options: 'i' } }
          ];
        }

        const students = await User.find(filter)
          .select('-password')
          .limit(limit * 1)
          .skip((page - 1) * limit)
          .sort({ createdAt: -1 });

        // Map isActive (MongoDB) to disabled (Firebase)
        const mappedStudents = students.map(user => {
          const userObj = user.toObject();
          return {
            ...userObj,
            id: userObj._id,
            disabled: userObj.isActive === false
          };
        });

        const total = await User.countDocuments(filter);

        sendSuccess(res, {
          students: mappedStudents,
          totalPages: Math.ceil(total / limit),
          currentPage: Number(page),
          total,
          source: 'mongodb-fallback'
        }, 'Students retrieved from MongoDB (fallback)');
      }
    } else {
      // Original MongoDB approach
      const filter = { role: 'student' };

      if (search) {
        const escapedSearch = escapeRegex(search);
        filter.$or = [
          { fullName: { $regex: escapedSearch, $options: 'i' } },
          { email: { $regex: escapedSearch, $options: 'i' } },
          { phone: { $regex: escapedSearch, $options: 'i' } }
        ];
      }

      const students = await User.find(filter)
        .select('-password')
        .limit(limit * 1)
        .skip((page - 1) * limit)
        .sort({ createdAt: -1 });
      
      // Map isActive (MongoDB) to disabled (Firebase)
      const mappedStudents = students.map(user => {
        const userObj = user.toObject();
        return {
          ...userObj,
          id: userObj._id,
          disabled: userObj.isActive === false
        };
      });
      
      const total = await User.countDocuments(filter);
      
      sendSuccess(res, {
        students: mappedStudents,
        totalPages: Math.ceil(total / limit),
        currentPage: Number(page),
        total,
        source: 'mongodb'
      }, 'Students retrieved from MongoDB');
    }
  } catch (error) {
    sendError(res, 'Failed to retrieve students', 500, error.message);
  }
};

// Get all admins from Firebase with MongoDB backup
const getAdmins = async (req, res) => {
  try {
    const { page = 1, limit = 20, search, source = 'firebase' } = req.query;
    
    if (source === 'firebase') {
      try {
        const userList = await admin.auth().listUsers();
        let filteredUsers = userList.users.filter(user => 
          user.customClaims?.role === 'admin'
        );
        
        if (search) {
          filteredUsers = filteredUsers.filter(user => 
            (user.displayName?.toLowerCase().includes(search.toLowerCase()) ||
             user.email?.toLowerCase().includes(search.toLowerCase()))
          );
        }
        
        const total = filteredUsers.length;
        const startIndex = (page - 1) * limit;
        const endIndex = startIndex + parseInt(limit);
        const paginatedUsers = filteredUsers.slice(startIndex, endIndex);
        
        const firebaseAdmins = paginatedUsers.map(user => ({
          id: user.uid,
          firebaseUid: user.uid,
          fullName: user.displayName || 'Unknown Admin',
          email: user.email || 'No email',
          phone: user.phoneNumber,
          role: user.customClaims?.role || 'admin',
          createdAt: user.metadata.creationTime ? new Date(user.metadata.creationTime) : new Date(),
          lastLogin: user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime) : null,
          disabled: user.disabled
        }));
        
        sendSuccess(res, {
          admins: firebaseAdmins,
          totalPages: Math.ceil(total / limit),
          currentPage: Number(page),
          total,
          source: 'firebase'
        }, 'Admins retrieved from Firebase successfully');
        
      } catch (firebaseError) {
        console.error('Firebase error fetching admins:', firebaseError.message);
        // Fallback to MongoDB
        const filter = { role: 'admin' };
        if (search) {
          filter.$or = [
            { fullName: { $regex: search, $options: 'i' } },
            { email: { $regex: search, $options: 'i' } }
          ];
        }
        
        const admins = await User.find(filter)
          .select('-password')
          .limit(limit * 1)
          .skip((page - 1) * limit)
          .sort({ createdAt: -1 });
        
        const total = await User.countDocuments(filter);
        
        sendSuccess(res, {
          admins: admins.map(u => ({ ...u.toObject(), id: u._id, disabled: u.isActive === false })),
          totalPages: Math.ceil(total / limit),
          currentPage: Number(page),
          total,
          source: 'mongodb-fallback'
        }, 'Admins retrieved from MongoDB (fallback)');
      }
    } else {
      const filter = { role: 'admin' };
      if (search) {
        filter.$or = [
          { fullName: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } }
        ];
      }
      
      const admins = await User.find(filter)
        .select('-password')
        .limit(limit * 1)
        .skip((page - 1) * limit)
        .sort({ createdAt: -1 });
      
      const total = await User.countDocuments(filter);
      
      sendSuccess(res, {
        admins: admins.map(u => ({ ...u.toObject(), id: u._id, disabled: u.isActive === false })),
        totalPages: Math.ceil(total / limit),
        currentPage: Number(page),
        total,
        source: 'mongodb'
      }, 'Admins retrieved from MongoDB');
    }
  } catch (error) {
    sendError(res, 'Failed to retrieve admins', 500, error.message);
  }
};

// Update user role (e.g., student to admin)
const updateUserRole = async (req, res) => {
  try {
    const { id } = req.params; // Can be firebaseUid or mongoId
    const { role } = req.body;
    
    if (!['admin', 'student', 'instructor'].includes(role)) {
      return sendError(res, 'Invalid role', 400);
    }
    
    // Find user in MongoDB first to get firebaseUid if id is mongoId
    let user;
    
    // Check if id is a valid MongoDB ObjectId
    if (id.match(/^[0-9a-fA-F]{24}$/)) {
      try {
        user = await User.findById(id);
      } catch (e) {
        console.log("Not a valid MongoDB ID, will try as Firebase UID");
      }
    }
    
    if (!user) {
      user = await User.findOne({ firebaseUid: id });
    }
    
    if (!user) {
      return sendError(res, 'User not found in MongoDB', 404);
    }
    
    const firebaseUid = user.firebaseUid || id;
    
    // Update in Firebase
    let firebaseUpdated = false;
    try {
      await admin.auth().setCustomUserClaims(firebaseUid, { role });
      firebaseUpdated = true;
      console.log(`Firebase user ${firebaseUid} role updated to ${role}`);
    } catch (firebaseError) {
      console.error(`Firebase role update failed for ${firebaseUid}:`, firebaseError.message);
    }
    
    // Update in MongoDB
    user.role = role;
    await user.save();
    console.log(`MongoDB user ${user._id} role updated to ${role}`);
    
    sendSuccess(res, {
      id: user._id,
      firebaseUid: user.firebaseUid,
      role,
      firebaseUpdated,
      mongoUpdated: true
    }, `User role updated to ${role} successfully`);
  } catch (error) {
    console.error('Error updating user role:', error);
    sendError(res, 'Failed to update user role', 500, error.message);
  }
};

// Get course statistics
const getCourseStats = async (req, res) => {
  try {
    // For admin dashboard, show all courses (both published and unpublished)
    const courses = await Course.find({});
    
    const stats = await Promise.all(courses.map(async (course) => {
      const enrollmentCount = await Enrollment.countDocuments({ courseId: course._id });
      const paymentCount = await Payment.countDocuments({ 
        courseId: course._id, 
        status: 'completed' 
      });
      
      return {
        courseId: course._id,
        title: course.title,
        price: course.price,
        enrollmentCount,
        paymentCount,
        revenue: paymentCount * course.price,
        isPublished: course.isPublished,
        createdAt: course.createdAt
      };
    }));
    
    sendSuccess(res, stats, 'Course statistics retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve course statistics', 500, error.message);
  }
};

// Get payment statistics
const getPaymentStats = async (req, res) => {
  try {
    console.log('Admin getPaymentStats called by user:', req.user?.id);
    
    const totalPayments = await Payment.countDocuments({ status: { $in: ['completed', 'approved'] } });
    const totalRevenue = await Payment.aggregate([
      { $match: { status: { $in: ['completed', 'approved'] } } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);
    
    const recentPayments = await Payment.find({ status: { $in: ['completed', 'approved'] } })
      .populate('userId', 'fullName email')
      .populate('courseId', 'title')
      .sort({ paymentDate: -1 })
      .limit(20);
    
    const responseData = {
      totalPayments,
      totalRevenue: totalRevenue[0]?.total || 0,
      recentPayments
    };
    
    console.log('Admin getPaymentStats response:', responseData);
    
    sendSuccess(res, responseData, 'Payment statistics retrieved successfully');
  } catch (error) {
    console.error('Error in admin getPaymentStats:', error);
    sendError(res, 'Failed to retrieve payment statistics', 500, error.message);
  }
};

// Get exam results statistics
const getExamStats = async (req, res) => {
  try {
    const totalResults = await Result.countDocuments();
    const passedResults = await Result.countDocuments({ passed: true });
    const passRate = totalResults > 0 ? (passedResults / totalResults) * 100 : 0;
    
    // Get total final exams count (distinct exams that have results)
    const finalExamsResults = await Result.aggregate([
      {
        $lookup: {
          from: 'exams',
          localField: 'examId',
          foreignField: '_id',
          as: 'exam'
        }
      },
      { $unwind: '$exam' },
      { $match: { 'exam.type': 'final' } },
      { $group: { _id: '$examId' } }
    ]);
    
    const totalFinalExamsDone = finalExamsResults.length;
    
    const recentResults = await Result.find()
      .populate('userId', 'fullName')
      .populate('examId', 'title')
      .sort({ submittedAt: -1 })
      .limit(20);
    
    sendSuccess(res, {
      totalResults,
      passedResults,
      passRate,
      totalFinalExamsDone,
      recentResults
    }, 'Exam statistics retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve exam statistics', 500, error.message);
  }
};

// Manual sync all Firebase users to MongoDB
const manualSyncAllUsers = async (req, res) => {
  try {
    console.log('Manual user sync initiated');
    
    // Get all users from Firebase
    const userList = await admin.auth().listUsers();
    
    // Filter out admin users
    const studentUsers = userList.users.filter(userRecord => userRecord.customClaims?.role !== 'admin');
    
    console.log(`Processing ${studentUsers.length} users from ${userList.users.length} total users`);
    
    let syncedCount = 0;
    let errorCount = 0;
    const errors = [];
    
    // Process users in batches to improve performance
    const batchSize = 10;
    
    for (let i = 0; i < studentUsers.length; i += batchSize) {
      const batch = studentUsers.slice(i, i + batchSize);
      
      // Process batch in parallel
      const batchPromises = batch.map(async (userRecord) => {
        try {
          const userData = {
            firebaseUid: userRecord.uid,
            fullName: userRecord.displayName || 'Unknown User',
            email: userRecord.email,
            phone: userRecord.phoneNumber,
            provider: userRecord.providerData[0]?.providerId || 'unknown',
            role: userRecord.customClaims?.role || 'student'
          };

          // Sync to MongoDB
          let user = await User.findOne({ firebaseUid: userRecord.uid });
          
          if (user) {
            // Update existing user
            user.fullName = userData.fullName;
            user.email = userData.email;
            user.phone = userData.phone;
            user.role = userData.role;
            user.lastLogin = new Date();
            await user.save();
          } else {
            // Create new user
            await User.create({
              firebaseUid: userData.firebaseUid,
              fullName: userData.fullName,
              email: userData.email,
              phone: userData.phone,
              role: userData.role,
              provider: userData.provider
            });
          }
          
          return true;
        } catch (syncError) {
          console.error(`Failed to sync user ${userRecord.uid}:`, syncError.message);
          return { uid: userRecord.uid, email: userRecord.email, error: syncError.message };
        }
      });
      
      const results = await Promise.all(batchPromises);
      
      // Count successes and collect errors
      results.forEach(result => {
        if (result === true) {
          syncedCount++;
        } else {
          errors.push(result);
          errorCount++;
        }
      });
      
      // Log progress
      console.log(`Processed batch ${Math.floor(i/batchSize) + 1}/${Math.ceil(studentUsers.length/batchSize)}, synced: ${syncedCount}, errors: ${errorCount}`);
    }

    const result = {
      totalUsers: userList.users.length,
      processed: studentUsers.length,
      synced: syncedCount,
      errors: errorCount,
      errorDetails: errors,
      message: `Sync completed: ${syncedCount} users synced, ${errorCount} errors from ${studentUsers.length} student users processed`
    };

    console.log('Manual sync result:', result);
    sendSuccess(res, result, 'Manual user sync completed');
  } catch (error) {
    console.error('Manual sync failed:', error.message);
    sendError(res, 'Manual sync failed', 500, error.message);
  }
};

// Create admin user (for initial setup)
const createAdmin = async (req, res) => {
  try {
    const { fullName, email, password, phone } = req.body;
    
    // Check if admin already exists
    const adminExists = await User.findOne({ email, role: 'admin' });
    if (adminExists) {
      return sendError(res, 'Admin user already exists', 400);
    }
    
    const admin = await User.create({
      fullName,
      email,
      password,
      phone,
      role: 'admin'
    });
    
    sendSuccess(res, {
      id: admin._id,
      fullName: admin.fullName,
      email: admin.email,
      role: admin.role
    }, 'Admin user created successfully', 201);
  } catch (error) {
    sendError(res, 'Failed to create admin user', 500, error.message);
  }
};

// Get detailed student information including enrollments
const getStudentDetail = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Try to find user in Firebase first
    let user;
    let mongoUserId;
    
    try {
      const firebaseUser = await admin.auth().getUser(id);
      user = {
        _id: firebaseUser.uid,
        id: firebaseUser.uid,
        firebaseUid: firebaseUser.uid,
        fullName: firebaseUser.displayName || 'Unknown User',
        email: firebaseUser.email || 'No email',
        phone: firebaseUser.phoneNumber,
        role: firebaseUser.customClaims?.role || 'student',
        provider: firebaseUser.providerData[0]?.providerId || 'unknown',
        createdAt: firebaseUser.metadata.creationTime ? 
          new Date(firebaseUser.metadata.creationTime) : new Date(),
        lastLogin: firebaseUser.metadata.lastSignInTime ? 
          new Date(firebaseUser.metadata.lastSignInTime) : null,
        emailVerified: firebaseUser.emailVerified,
        disabled: firebaseUser.disabled
      };
      
      // Try to find the corresponding MongoDB user (to get avatar and deviceId)
      const mongoUser = await User.findOne({ firebaseUid: id });
      mongoUserId = mongoUser?._id;
      if (mongoUser?.avatar) user.avatar = mongoUser.avatar;
      if (mongoUser?.deviceId) user.deviceId = mongoUser.deviceId;
      
    } catch (firebaseError) {
      console.log(`Firebase user ${id} not found, falling back to MongoDB:`, firebaseError.message);
      // Fallback to MongoDB
      let mongoUser;
      
      // Check if id is a valid MongoDB ObjectId
      if (id.match(/^[0-9a-fA-F]{24}$/)) {
        try {
          mongoUser = await User.findById(id).select('-password');
        } catch (e) {
          console.log("Not a valid MongoDB ID in getStudentDetail");
        }
      }
      
      if (!mongoUser) {
        mongoUser = await User.findOne({ firebaseUid: id }).select('-password');
      }
      
      if (!mongoUser) {
        return sendError(res, 'Student not found', 404);
      }
      
      user = {
        _id: mongoUser._id,
        id: mongoUser._id,
        firebaseUid: mongoUser.firebaseUid,
        fullName: mongoUser.fullName,
        email: mongoUser.email,
        phone: mongoUser.phone,
        role: mongoUser.role,
        provider: mongoUser.provider,
        avatar: mongoUser.avatar,
        disabled: mongoUser.isActive === false,
        createdAt: mongoUser.createdAt,
        lastLogin: mongoUser.lastLogin,
        deviceId: mongoUser.deviceId
      };
      
      mongoUserId = mongoUser._id;
    }
    
    // Get student's enrollments using the MongoDB user ID, including
    // unenrolled/suspended ones so admins can see the full history
    const enrollments = mongoUserId 
      ? await Enrollment.find({ userId: mongoUserId, status: Enrollment.ANY_STATUS })
          .populate({
            path: 'courseId',
            select: 'title description price duration level thumbnail isPublished createdBy',
            populate: {
              path: 'createdBy',
              select: 'fullName'
            }
          })
          .sort({ enrollmentDate: -1 })
      : [];
    
    // Calculate statistics
    const activeEnrollments = enrollments.filter(e => !e.status || e.status === 'active');
    const totalEnrollments = activeEnrollments.length;
    const unenrolledCourses = enrollments.filter(e => e.status === 'unenrolled').length;
    const suspendedCourses = enrollments.filter(e => e.status === 'suspended').length;
    const completedCourses = activeEnrollments.filter(e => e.completionStatus === 'completed').length;
    const inProgressCourses = activeEnrollments.filter(e => e.completionStatus === 'in-progress').length;
    
    // Calculate total spent
    const payments = mongoUserId
      ? await Payment.find({ 
          userId: mongoUserId, 
          status: 'completed' 
        }).populate('courseId', 'price')
      : [];
    
    const totalSpent = payments.reduce((sum, payment) => {
      return sum + (payment.courseId?.price || 0);
    }, 0);
    
    // Get student's exam results
    const examResults = mongoUserId
      ? await Result.find({ userId: mongoUserId })
          .populate('examId', 'title type')
          .sort({ submittedAt: -1 })
      : [];
    
    // Get last active date (latest enrollment or login or exam submission)
    const lastActive = user.lastLogin || 
      (enrollments.length > 0 ? enrollments[0].enrollmentDate : 
        (examResults.length > 0 ? examResults[0].submittedAt : user.createdAt));
    
    // Get time tracking data from MongoDB user
    // totalSessionTime is kept up to date by client heartbeats (see auth.controller.js
    // recordSessionHeartbeat), so it already reflects all completed foreground time.
    let timeSpentInApp = 0;
    if (mongoUserId) {
      const mongoUser = await User.findById(mongoUserId).select('totalSessionTime sessionCount');
      if (mongoUser) {
        timeSpentInApp = mongoUser.totalSessionTime || 0;
      }
    }
    
    sendSuccess(res, {
      user: {
        ...user,
        profilePicture: user.avatar || user.profilePicture || null,
      },
      enrollments,
      examResults,
      payments,
      totalEnrollments,
      unenrolledCourses,
      suspendedCourses,
      completedCourses,
      inProgressCourses,
      totalSpent,
      lastActive,
      timeSpentInApp
    }, 'Student details retrieved successfully');
  } catch (error) {
    console.error('Error in getStudentDetail:', error);
    sendError(res, 'Failed to retrieve student details', 500, error.message);
  }
};

// Get student analytics data
const getStudentAnalytics = async (req, res) => {
  try {
    // Get total students from both Firebase and MongoDB
    const firebaseUsers = await admin.auth().listUsers();
    const mongoUsers = await User.countDocuments({ role: 'student' });
    
    // Count Firebase users excluding admins
    const firebaseStudentCount = firebaseUsers.users.filter(user => 
      user.customClaims?.role !== 'admin'
    ).length;
    
    const totalStudents = firebaseStudentCount + mongoUsers;
    
    // Get active students (those who logged in recently)
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const activeStudents = await User.countDocuments({
      role: 'student',
      $or: [
        { lastLogin: { $gte: thirtyDaysAgo } },
        { createdAt: { $gte: thirtyDaysAgo } }
      ]
    });
    
    const inactiveStudents = totalStudents - activeStudents;
    
    // Get new students this month
    const startOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
    const newStudentsThisMonth = await User.countDocuments({
      role: 'student',
      createdAt: { $gte: startOfMonth }
    });
    
    // Calculate average enrollments per student
    const studentEnrollmentCounts = await Enrollment.aggregate([
      { $group: { _id: '$userId', count: { $sum: 1 } } }
    ]);
    
    const totalEnrollments = studentEnrollmentCounts.reduce((sum, item) => sum + item.count, 0);
    const averageEnrollmentsPerStudent = studentEnrollmentCounts.length > 0 
      ? totalEnrollments / studentEnrollmentCounts.length 
      : 0;
    
    // Get top performing students (most enrollments and completions)
    try {
      const topStudentsPipeline = [
        {
          $lookup: {
            from: 'users',
            localField: 'userId',
            foreignField: '_id',
            as: 'user'
          }
        },
        { $unwind: '$user' },
        {
          $group: {
            _id: '$userId',
            totalEnrollments: { $sum: 1 },
            completedCourses: {
              $sum: {
                $cond: [{ $eq: ['$completionStatus', 'completed'] }, 1, 0]
              }
            },
            averageProgress: { $avg: '$progress' },
            user: { $first: '$user' }
          }
        },
        {
          $lookup: {
            from: 'payments',
            localField: '_id',
            foreignField: 'userId',
            as: 'payments'
          }
        },
        {
          $addFields: {
            totalSpent: {
              $sum: {
                $map: {
                  input: '$payments',
                  as: 'payment',
                  in: {
                    $cond: [
                      { $eq: ['$$payment.status', 'completed'] },
                      { $ifNull: ['$$payment.amount', 0] },
                      0
                    ]
                  }
                }
              }
            }
          }
        },
        {
          $sort: {
            totalEnrollments: -1,
            completedCourses: -1,
            averageProgress: -1
          }
        },
        { $limit: 10 }
      ];
      
      const topPerformingStudents = await Enrollment.aggregate(topStudentsPipeline);
      
      // Format top students data
      var formattedTopStudents = topPerformingStudents.map(student => ({
        id: student._id,
        name: student.user?.fullName || 'Unknown User',
        email: student.user?.email || 'No email',
        totalEnrollments: student.totalEnrollments,
        completedCourses: student.completedCourses,
        averageProgress: student.averageProgress || 0,
        totalSpent: student.totalSpent || 0
      }));
    } catch (aggregateError) {
      console.log('Error in top students aggregation, using fallback:', aggregateError.message);
      formattedTopStudents = [];
    }
    
    // Get enrollment trends (last 30 days)
    try {
      const enrollmentTrends = await Enrollment.aggregate([
        {
          $match: {
            enrollmentDate: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
          }
        },
        {
          $group: {
            _id: {
              $dateToString: { format: '%Y-%m-%d', date: '$enrollmentDate' }
            },
            enrollments: { $sum: 1 },
            completions: {
              $sum: {
                $cond: [{ $eq: ['$completionStatus', 'completed'] }, 1, 0]
              }
            }
          }
        },
        { $sort: { '_id': 1 } }
      ]);
      
      // Format enrollment trends
      var formattedTrends = enrollmentTrends.map(trend => ({
        date: trend._id,
        enrollments: trend.enrollments,
        completions: trend.completions
      }));
    } catch (trendError) {
      console.log('Error in enrollment trends aggregation, using fallback:', trendError.message);
      formattedTrends = [];
    }
    
    // Get student activity stats
    const dailyActive = await User.countDocuments({
      role: 'student',
      lastLogin: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }
    });
    
    const weeklyActive = await User.countDocuments({
      role: 'student',
      $or: [
        { lastLogin: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
        { createdAt: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } }
      ]
    });
    
    const monthlyActive = await User.countDocuments({
      role: 'student',
      $or: [
        { lastLogin: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } },
        { createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } }
      ]
    });
    
    // Calculate average session duration and total study hours from real, tracked
    // session time (User.totalSessionTime / sessionCount, updated via client heartbeats)
    const sessionAgg = await User.aggregate([
      { $match: { role: 'student' } },
      {
        $group: {
          _id: null,
          totalSeconds: { $sum: '$totalSessionTime' },
          totalSessions: { $sum: '$sessionCount' }
        }
      }
    ]);
    const totalTrackedSeconds = sessionAgg[0]?.totalSeconds || 0;
    const totalTrackedSessions = sessionAgg[0]?.totalSessions || 0;

    const avgSessionDuration = totalTrackedSessions > 0
      ? Math.round((totalTrackedSeconds / totalTrackedSessions) / 60)
      : 0; // minutes
    const totalStudyHours = Math.round(totalTrackedSeconds / 3600);
    
    sendSuccess(res, {
      totalStudents,
      activeStudents,
      inactiveStudents,
      newStudentsThisMonth,
      averageEnrollmentsPerStudent,
      topPerformingStudents: formattedTopStudents,
      enrollmentTrends: formattedTrends,
      studentActivityStats: {
        dailyActiveStudents: dailyActive,
        weeklyActiveStudents: weeklyActive,
        monthlyActiveStudents: monthlyActive,
        avgSessionDuration,
        totalStudyHours
      }
    }, 'Student analytics retrieved successfully');
  } catch (error) {
    console.error('Error in getStudentAnalytics:', error);
    sendError(res, 'Failed to retrieve student analytics', 500, error.message);
  }
};

// Get analytics for a specific course
const getCourseAnalytics = async (req, res) => {
  try {
    const { courseId } = req.params;
    
    // Get course details
    const course = await Course.findById(courseId);
    if (!course) {
      return sendError(res, 'Course not found', 404);
    }
    
        
    // Get all enrollments for this course
    const enrollments = await Enrollment.find({ courseId })
      .populate('userId', 'fullName email phone lastLogin createdAt')
      .sort({ enrollmentDate: -1 });
    
    const totalStudents = enrollments.length;
    
    // Calculate completions
    const completedCount = enrollments.filter(e => e.completionStatus === 'completed').length;
    const completionRate = totalStudents > 0 ? (completedCount / totalStudents) * 100 : 0;
    
    // Calculate average progress
    const totalProgress = enrollments.reduce((sum, e) => sum + (e.progress || 0), 0);
    const averageProgress = totalStudents > 0 ? totalProgress / totalStudents : 0;
    
    // Get students with their performance
    const now = new Date();
    const studentsPerformance = enrollments.map(e => {
      let timeRemaining = null;
      let isExpired = false;
      let status = 'active';
      
      if (e.accessExpirationDate) {
        const timeDiff = e.accessExpirationDate.getTime() - now.getTime();
        isExpired = timeDiff <= 0;
        
        if (!isExpired) {
          const days = Math.floor(timeDiff / (1000 * 60 * 60 * 24));
          const hours = Math.floor((timeDiff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
          const minutes = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60));
          
          if (days > 0) {
            timeRemaining = `${days}d ${hours}h ${minutes}m`;
          } else if (hours > 0) {
            timeRemaining = `${hours}h ${minutes}m`;
          } else {
            timeRemaining = `${minutes}m`;
          }
          status = 'active';
        } else {
          status = 'expired';
          timeRemaining = 'Expired';
        }
      } else {
        status = 'unlimited';
        timeRemaining = 'Unlimited';
      }
      
      return {
        id: e.userId?._id || 'unknown',
        name: e.userId?.fullName || 'Unknown Student',
        email: e.userId?.email || 'N/A',
        enrollmentDate: e.enrollmentDate,
        progress: e.progress,
        completionStatus: e.completionStatus,
        lastAccessed: e.lastAccessed,
        rating: e.rating,
        feedback: e.feedback,
        accessExpirationDate: e.accessExpirationDate,
        timeRemaining,
        status,
        isExpired,
        examScores: [] // We could populate this if needed
      };
    });

    // Calculate ratings data
    const ratings = enrollments.filter(e => e.rating != null).map(e => e.rating);
    const totalRatings = ratings.length;
    const averageRating = totalRatings > 0 ? ratings.reduce((sum, r) => sum + r, 0) / totalRatings : 0;
    
    // Get reviews with user details
    const reviews = enrollments
      .filter(e => e.rating != null || e.feedback != null)
      .map(e => ({
        userName: e.userId?.fullName || 'Unknown Student',
        rating: e.rating,
        feedback: e.feedback,
        date: e.updatedAt
      }));
    
    // Get new enrollments this month
    const startOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
    const newStudentsThisMonth = enrollments.filter(e => e.enrollmentDate >= startOfMonth).length;
    
    // Get active students (accessed in last 30 days)
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const activeStudents = enrollments.filter(e => e.lastAccessed >= thirtyDaysAgo).length;
    
    // Calculate expired students statistics
    const expiredStudents = enrollments.filter(e => e.accessExpirationDate && e.accessExpirationDate < now).length;
    const studentsWithExpiringAccess = enrollments.filter(e => {
      if (!e.accessExpirationDate) return false;
      const timeDiff = e.accessExpirationDate.getTime() - now.getTime();
      return timeDiff > 0 && timeDiff <= 7 * 24 * 60 * 60 * 1000; // Expires within 7 days
    }).length;
    
    sendSuccess(res, {
      course: {
        id: course._id,
        title: course.title,
        thumbnail: course.thumbnail,
        accessDuration: course.accessDuration,
        accessDurationUnit: course.accessDurationUnit
      },
      stats: {
        totalStudents,
        activeStudents,
        completedCount,
        completionRate,
        averageProgress,
        newStudentsThisMonth,
        averageRating,
        totalRatings,
        expiredStudents,
        studentsWithExpiringAccess
      },
      reviews,
      students: studentsPerformance
    }, 'Course analytics retrieved successfully');
  } catch (error) {
    console.error('Error in getCourseAnalytics:', error);
    sendError(res, 'Failed to retrieve course analytics', 500, error.message);
  }
};

// Get one student's chapter/lesson-level progress breakdown for a course
const getStudentCoursePerformance = async (req, res) => {
  try {
    const { courseId, studentId } = req.params;

    const data = await getStudentCourseProgress(courseId, studentId);
    if (!data) {
      return sendError(res, 'Student not enrolled in this course', 404);
    }

    sendSuccess(res, data, 'Student course performance retrieved successfully');
  } catch (error) {
    console.error('Error in getStudentCoursePerformance:', error);
    sendError(res, 'Failed to retrieve student course performance', 500, error.message);
  }
};

// Get user device information and enrolled courses
const getUserDeviceInfo = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Try to find user in Firebase first
    let user;
    let mongoUserId;
    
    try {
      const firebaseUser = await admin.auth().getUser(id);
      user = {
        _id: firebaseUser.uid,
        id: firebaseUser.uid,
        firebaseUid: firebaseUser.uid,
        fullName: firebaseUser.displayName || 'Unknown User',
        email: firebaseUser.email || 'No email',
        phone: firebaseUser.phoneNumber,
        role: firebaseUser.customClaims?.role || 'student',
        provider: firebaseUser.providerData[0]?.providerId || 'unknown',
        createdAt: firebaseUser.metadata.creationTime ? 
          new Date(firebaseUser.metadata.creationTime) : new Date(),
        lastLogin: firebaseUser.metadata.lastSignInTime ? 
          new Date(firebaseUser.metadata.lastSignInTime) : null,
        emailVerified: firebaseUser.emailVerified,
        disabled: firebaseUser.disabled
      };
      
      // Try to find the corresponding MongoDB user
      const mongoUser = await User.findOne({ firebaseUid: id });
      mongoUserId = mongoUser?._id;
      
    } catch (firebaseError) {
      console.log(`Firebase user ${id} not found, falling back to MongoDB:`, firebaseError.message);
      // Fallback to MongoDB - handle potential CastError
      try {
        const mongoUser = await User.findById(id).select('-password');
        if (!mongoUser) {
          return sendError(res, 'User not found in either Firebase or MongoDB', 404);
        }
        
        user = {
          _id: mongoUser._id,
          id: mongoUser._id,
          firebaseUid: mongoUser.firebaseUid,
          fullName: mongoUser.fullName,
          email: mongoUser.email,
          phone: mongoUser.phone,
          role: mongoUser.role,
          provider: mongoUser.provider,
          createdAt: mongoUser.createdAt,
          lastLogin: mongoUser.lastLogin,
          deviceId: mongoUser.deviceId
        };
        
        mongoUserId = mongoUser._id;
      } catch (mongoError) {
        if (mongoError.name === 'CastError') {
          // If it's a CastError, try finding by firebaseUid
          const mongoUser = await User.findOne({ firebaseUid: id }).select('-password');
          if (!mongoUser) {
            return sendError(res, 'User not found in either Firebase or MongoDB', 404);
          }
          
          user = {
            _id: mongoUser._id,
            id: mongoUser._id,
            firebaseUid: mongoUser.firebaseUid,
            fullName: mongoUser.fullName,
            email: mongoUser.email,
            phone: mongoUser.phone,
            role: mongoUser.role,
            provider: mongoUser.provider,
            createdAt: mongoUser.createdAt,
            lastLogin: mongoUser.lastLogin,
            deviceId: mongoUser.deviceId
          };
          
          mongoUserId = mongoUser._id;
        } else {
          throw mongoError;
        }
      }
    }
    
    // Get user's enrolled courses using the MongoDB user ID if available
    const enrollments = mongoUserId 
      ? await Enrollment.find({ userId: mongoUserId })
          .populate({
            path: 'courseId',
            select: 'title description price duration level thumbnail isPublished'
          })
          .sort({ enrollmentDate: -1 })
      : [];
    
    sendSuccess(res, {
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        deviceId: user.deviceId,
        role: user.role,
        createdAt: user.createdAt,
        profilePicture: user.avatar || user.profilePicture || null,
      },
      enrolledCourses: enrollments,
      totalEnrollments: enrollments.length
    }, 'User device info and enrolled courses retrieved successfully');
    
  } catch (error) {
    console.error('Error in getUserDeviceInfo:', error);
    sendError(res, 'Failed to retrieve user device info', 500, error.message);
  }
};

// Reset user device binding
const resetUserDevice = async (req, res) => {
  try {
    const { id } = req.params;
    const { deviceId } = req.body;
    
    // Find user in MongoDB
    let user;
    
    // Check if id is a valid MongoDB ObjectId
    if (id.match(/^[0-9a-fA-F]{24}$/)) {
      try {
        user = await User.findById(id);
      } catch (e) {
        console.log("Not a valid MongoDB ID in resetUserDevice");
      }
    }
    
    if (!user) {
      user = await User.findOne({ firebaseUid: id });
    }
    
    if (!user) {
      return sendError(res, 'User not found', 404);
    }
    
    // Store old device ID for logging
    const oldDeviceId = user.deviceId;
    
    // Reset the device ID
    user.deviceId = deviceId || null;
    await user.save();
    
    console.log(`Admin ${req.user.id} reset device binding for user ${user.id}. Old device ID: ${oldDeviceId}, New device ID: ${deviceId || 'cleared'}`);
    
    sendSuccess(res, {
      userId: user._id,
      oldDeviceId,
      newDeviceId: user.deviceId,
      message: 'User device binding reset successfully'
    }, 'User device binding reset successfully');
    
  } catch (error) {
    console.error('Error in resetUserDevice:', error);
    sendError(res, 'Failed to reset user device binding', 500, error.message);
  }
};

// Toggle student status (enable/disable)
const toggleStudentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { disabled } = req.body;
    
    if (typeof disabled !== 'boolean') {
      return sendError(res, 'Status (disabled) is required and must be a boolean', 400);
    }
    
    // First, try to update in Firebase
    let firebaseUpdated = false;
    try {
      await admin.auth().updateUser(id, { disabled });
      firebaseUpdated = true;
      console.log(`Firebase user ${id} ${disabled ? 'disabled' : 'enabled'} successfully`);
    } catch (firebaseError) {
      console.log(`Firebase user ${id} not found or update failed:`, firebaseError.message);
    }
    
    // Update in MongoDB if possible
    let mongoUpdated = false;
    let mongoUser = null;
    
    try {
      // First try to find by MongoDB ObjectId
      mongoUser = await User.findById(id);
      if (!mongoUser) {
        // If that fails, try to find by firebaseUid
        mongoUser = await User.findOne({ firebaseUid: id });
      }
      
      if (mongoUser) {
        // Update the isActive field in MongoDB to match Firebase's disabled status
        // Firebase disabled: true means MongoDB isActive: false
        mongoUser.isActive = !disabled;
        await mongoUser.save();
        
        mongoUpdated = true;
        console.log(`MongoDB user ${mongoUser._id} isActive status updated to ${!disabled}`);
      }
    } catch (mongoError) {
      console.log(`MongoDB user ${id} not found or update failed:`, mongoError.message);
    }
    
    if (!firebaseUpdated && !mongoUpdated) {
      return sendError(res, 'Student not found in either Firebase or MongoDB', 404);
    }
    
    sendSuccess(res, {
      id,
      disabled,
      firebaseUpdated,
      mongoUpdated,
      message: `Student ${disabled ? 'disabled' : 'enabled'} successfully`
    }, `Student ${disabled ? 'disabled' : 'enabled'} successfully`);
  } catch (error) {
    console.error('Error in toggleStudentStatus:', error);
    sendError(res, 'Failed to toggle student status', 500, error.message);
  }
};

// Reset student password (admin only)
const resetStudentPassword = async (req, res) => {
  try {
    const { id } = req.params;
    const { newPassword } = req.body;

    if (!newPassword) {
      return sendError(res, 'New password is required', 400);
    }

    if (newPassword.length < 6) {
      return sendError(res, 'Password must be at least 6 characters long', 400);
    }

    // Find the student in MongoDB
    const student = await User.findById(id);
    if (!student) {
      return sendError(res, 'Student not found', 404);
    }

    // Update the password in MongoDB
    student.password = newPassword;
    await student.save();

    // Also update password in Firebase if user exists there
    try {
      if (student.firebaseUid) {
        await admin.auth().updateUser(student.firebaseUid, {
          password: newPassword
        });
      }
    } catch (firebaseError) {
      console.warn('Failed to update Firebase password:', firebaseError);
      // Don't fail the request if Firebase update fails
    }

    sendSuccess(res, null, 'Student password reset successfully');
  } catch (error) {
    console.error('Error in resetStudentPassword:', error);
    sendError(res, 'Failed to reset student password', 500, error.message);
  }
};

// Unenroll a student from a course
const unenrollStudent = async (req, res) => {
  try {
    const { courseId, studentId } = req.params;
    
    // Find the MongoDB user ID (studentId could be firebaseUid or mongoId)
    let mongoUserId;
    
    // First try to find by MongoDB ObjectId
    if (studentId.match(/^[0-9a-fA-F]{24}$/)) {
      try {
        const user = await User.findById(studentId);
        if (user) {
          mongoUserId = user._id;
        }
      } catch (idError) {
        // Ignore and continue to find by firebaseUid
      }
    }
    
    // If not found by ObjectId, try finding by firebaseUid
    if (!mongoUserId) {
      const mongoUser = await User.findOne({ firebaseUid: studentId });
      if (mongoUser) {
        mongoUserId = mongoUser._id;
      }
    }
    
    if (!mongoUserId) {
      return sendError(res, 'Student not found', 404);
    }
    
    // Delete the enrollment
    const enrollment = await Enrollment.findOneAndDelete({ userId: mongoUserId, courseId });
    
    if (!enrollment) {
      return sendError(res, 'Enrollment not found for this student and course', 404);
    }
    
    // Delete associated certificates for this course/user
    await Certificate.deleteMany({ userId: mongoUserId, courseId });
    
    // Find and delete the payment associated with this enrollment if it exists
    if (enrollment.paymentId) {
      await Payment.findByIdAndDelete(enrollment.paymentId);
    } else {
      // Also check if there's any payment for this course/user just in case it wasn't linked
      await Payment.deleteMany({ userId: mongoUserId, courseId });
    }
    
    sendSuccess(res, null, 'Student unenrolled from course successfully');
  } catch (error) {
    console.error('Error in unenrollStudent:', error);
    sendError(res, 'Failed to unenroll student', 500, error.message);
  }
};

// Update student information (admin only)
const updateStudent = async (req, res) => {
  try {
    const { id } = req.params;
    const { fullName, email, phone, role, isActive } = req.body;

    // Find user in MongoDB (support both ObjectId and firebaseUid)
    let user;
    if (id.match(/^[0-9a-fA-F]{24}$/)) {
      try { user = await User.findById(id); } catch (e) { /* not a valid ObjectId */ }
    }
    if (!user) user = await User.findOne({ firebaseUid: id });
    if (!user) return sendError(res, 'Student not found', 404);

    // Check phone uniqueness if being changed
    if (phone !== undefined && phone !== '' && phone !== user.phone) {
      const phoneExists = await User.findOne({ phone, _id: { $ne: user._id } });
      if (phoneExists) return sendError(res, 'This phone number is already used by another account', 409);
    }

    // Check email uniqueness only when a non-empty email is provided AND it differs from stored value
    const incomingEmail = (email || '').trim().toLowerCase();
    if (incomingEmail && incomingEmail !== (user.email || '')) {
      const emailExists = await User.findOne({ email: incomingEmail, _id: { $ne: user._id } });
      if (emailExists) return sendError(res, 'This email address is already used by another account', 409);
    }

    // Validate role if provided
    if (role !== undefined && !['student', 'admin', 'instructor'].includes(role)) {
      return sendError(res, 'Invalid role', 400);
    }

    if (fullName !== undefined && fullName.trim()) user.fullName = fullName.trim();
    if (incomingEmail && incomingEmail !== (user.email || '')) {
      user.email = incomingEmail;
    }
    if (phone !== undefined) user.phone = phone.trim() || undefined;
    if (role !== undefined) user.role = role;
    if (isActive !== undefined) user.isActive = isActive;

    await user.save();

    // Sync name to Firebase if changed
    if (fullName !== undefined && user.firebaseUid) {
      try {
        await admin.auth().updateUser(user.firebaseUid, { displayName: user.fullName });
      } catch (firebaseError) {
        console.warn('Could not update Firebase display name:', firebaseError.message);
      }
    }

    sendSuccess(res, {
      id: user._id,
      firebaseUid: user.firebaseUid,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      isActive: user.isActive
    }, 'Student information updated successfully');
  } catch (error) {
    console.error('Error in updateStudent:', error);
    if (error.code === 11000) {
      const field = error.keyValue ? Object.keys(error.keyValue)[0] : 'field';
      return sendError(res, `This ${field} is already in use by another account`, 409);
    }
    sendError(res, 'Failed to update student information', 500, error.message);
  }
};

// Delete a student and all related data
const deleteStudent = async (req, res) => {
  try {
    const { id } = req.params;
    
    // First, try to find and delete from Firebase
    let firebaseDeleted = false;
    let mongoDeleted = false;
    let deletedUserData = null;
    let mongoUser = null;
    
    try {
      // Try to delete from Firebase
      await admin.auth().deleteUser(id);
      firebaseDeleted = true;
      console.log(`Firebase user ${id} deleted successfully`);
    } catch (firebaseError) {
      console.log(`Firebase user ${id} not found or deletion failed:`, firebaseError.message);
      // Continue with MongoDB deletion
    }
    
    // Find the user in MongoDB to get complete data before deletion
    // First try to find by MongoDB ObjectId
    try {
      mongoUser = await User.findById(id).select('-password');
    } catch (mongoError) {
      // If that fails, try to find by firebaseUid
      if (mongoError.name === 'CastError') {
        mongoUser = await User.findOne({ firebaseUid: id }).select('-password');
      } else {
        throw mongoError;
      }
    }
    
    // If not found by ObjectId, try finding by firebaseUid
    if (!mongoUser) {
      mongoUser = await User.findOne({ firebaseUid: id }).select('-password');
    }
    
    if (mongoUser) {
      deletedUserData = {
        id: mongoUser._id,
        firebaseUid: mongoUser.firebaseUid,
        fullName: mongoUser.fullName,
        email: mongoUser.email,
        role: mongoUser.role,
        createdAt: mongoUser.createdAt
      };
      
      // Delete all related data in proper order to maintain referential integrity
      
      // 1. Delete enrollments
      const enrollmentCount = await Enrollment.deleteMany({ userId: mongoUser._id });
      console.log(`Deleted ${enrollmentCount.deletedCount} enrollments for user ${id}`);
      
      // 2. Delete payments
      const paymentCount = await Payment.deleteMany({ userId: mongoUser._id });
      console.log(`Deleted ${paymentCount.deletedCount} payments for user ${id}`);
      
      // 3. Delete exam results
      const resultCount = await Result.deleteMany({ userId: mongoUser._id });
      console.log(`Deleted ${resultCount.deletedCount} exam results for user ${id}`);
      
      // 4. Delete notifications
      const notificationCount = await Notification.deleteMany({ userId: mongoUser._id });
      console.log(`Deleted ${notificationCount.deletedCount} notifications for user ${id}`);
      
      // 5. Delete certificates
      const certificateCount = await Certificate.deleteMany({ userId: mongoUser._id });
      console.log(`Deleted ${certificateCount.deletedCount} certificates for user ${id}`);
      
      // 6. Delete conversations and messages
      const conversationCount = await Conversation.deleteMany({ participants: mongoUser._id });
      const messageCount = await ChatMessage.deleteMany({ sender: mongoUser._id });
      console.log(`Deleted ${conversationCount.deletedCount} conversations and ${messageCount.deletedCount} messages for user ${id}`);
      
      // 7. Finally delete the user
      await User.findByIdAndDelete(mongoUser._id);
      mongoDeleted = true;
      console.log(`MongoDB user ${id} deleted successfully`);
    }
    
    if (!firebaseDeleted && !mongoDeleted) {
      return sendError(res, 'Student not found in either Firebase or MongoDB', 404);
    }
    
    sendSuccess(res, {
      id,
      firebaseDeleted,
      mongoDeleted,
      deletedUserData,
      message: `Student deleted successfully from ${firebaseDeleted ? 'Firebase' : ''}${firebaseDeleted && mongoDeleted ? ' and ' : ''}${mongoDeleted ? 'MongoDB' : ''}`
    }, 'Student deleted successfully');
  } catch (error) {
    console.error('Error in deleteStudent:', error);
    sendError(res, 'Failed to delete student', 500, error.message);
  }
};

// Get all teachers (instructors)
const getTeachers = async (req, res) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    
    const filter = { role: 'instructor' };
    
    if (search) {
      filter.$or = [
        { fullName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }
    
    const teachers = await User.find(filter)
      .select('-password')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });
    
    // Get course counts for each teacher
    const TeacherAssignment = require('../models/TeacherAssignment');
    const teachersWithStats = await Promise.all(
      teachers.map(async (teacher) => {
        const courseCount = await TeacherAssignment.countDocuments({
          teacherId: teacher._id,
          isActive: true
        });
        
        return {
          ...teacher.toObject(),
          id: teacher._id,
          assignedCourseCount: courseCount
        };
      })
    );
    
    const total = await User.countDocuments(filter);
    
    sendSuccess(res, {
      teachers: teachersWithStats,
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page),
      total
    }, 'Teachers retrieved successfully');
  } catch (error) {
    console.error('Error in getTeachers:', error);
    sendError(res, 'Failed to retrieve teachers', 500, error.message);
  }
};

// Create a new teacher (instructor)
const createTeacher = async (req, res) => {
  try {
    const { fullName, email, phone, password, sendCredentials } = req.body;
    
    if (!fullName || (!email && !phone)) {
      return sendError(res, 'Full name and at least one contact method (email or phone) required', 400);
    }
    
    // Check for existing user
    const existingQuery = [];
    if (email) existingQuery.push({ email });
    if (phone) existingQuery.push({ phone });
    
    const existingUser = await User.findOne({ $or: existingQuery });
    if (existingUser) {
      return sendError(res, 'User with this email or phone already exists', 409);
    }
    
    let firebaseUid = null;
    
    // Create Firebase user if credentials provided
    if (email && password) {
      try {
        // Only pass phone to Firebase if it's in E.164 format (starts with +)
        const e164Phone = phone && phone.startsWith('+') ? phone : undefined;
        const firebaseUser = await admin.auth().createUser({
          email,
          password,
          displayName: fullName,
          phoneNumber: e164Phone
        });
        
        // Set custom claims for role
        await admin.auth().setCustomUserClaims(firebaseUser.uid, { role: 'instructor' });
        firebaseUid = firebaseUser.uid;
      } catch (firebaseError) {
        console.error('Firebase user creation error:', firebaseError.message);
        // Continue without Firebase - user can be created in MongoDB only
      }
    }
    
    // Create user in MongoDB
    const userData = {
      fullName,
      email: email || undefined,
      phone: phone || undefined,
      password: password || undefined,
      role: 'instructor',
      isVerified: true,
      isActive: true
    };
    if (firebaseUid) {
      userData.firebaseUid = firebaseUid;
    }
    const user = await User.create(userData);
    
    // TODO: Send credentials email if sendCredentials is true
    
    sendSuccess(res, {
      id: user._id,
      firebaseUid: user.firebaseUid,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      isActive: user.isActive,
      createdAt: user.createdAt
    }, 'Teacher created successfully', 201);
  } catch (error) {
    console.error('Error in createTeacher:', error);
    if (error.code === 11000) {
      const field = error.keyValue ? Object.keys(error.keyValue)[0] : 'field';
      const fieldLabels = { email: 'email', phone: 'phone number', firebaseUid: 'account' };
      const label = fieldLabels[field] || field;
      return sendError(res, `A teacher with this ${label} already exists`, 409);
    }
    sendError(res, 'Failed to create teacher. Please check the details and try again.', 500, error.message);
  }
};

// Update teacher information
const updateTeacher = async (req, res) => {
  try {
    const { id } = req.params;
    const { fullName, email, phone, isActive, resetPassword, newPassword } = req.body;
    
    const user = await User.findOne({ _id: id, role: 'instructor' });
    if (!user) {
      return sendError(res, 'Teacher not found', 404);
    }
    
    // Update basic info
    if (fullName) user.fullName = fullName;
    if (email) user.email = email;
    if (phone) user.phone = phone;
    if (typeof isActive === 'boolean') user.isActive = isActive;
    
    // Handle password reset
    if (resetPassword && newPassword) {
      user.password = newPassword;
      
      // Also update Firebase if applicable
      if (user.firebaseUid) {
        try {
          await admin.auth().updateUser(user.firebaseUid, { password: newPassword });
        } catch (firebaseError) {
          console.error('Firebase password update error:', firebaseError.message);
        }
      }
    }
    
    await user.save();
    
    sendSuccess(res, {
      id: user._id,
      firebaseUid: user.firebaseUid,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      isActive: user.isActive,
      updatedAt: user.updatedAt
    }, 'Teacher updated successfully');
  } catch (error) {
    console.error('Error in updateTeacher:', error);
    if (error.code === 11000) {
      const field = error.keyValue ? Object.keys(error.keyValue)[0] : 'field';
      return sendError(res, `This ${field} is already in use`, 409);
    }
    sendError(res, 'Failed to update teacher', 500, error.message);
  }
};

// Delete a teacher
const deleteTeacher = async (req, res) => {
  try {
    const { id } = req.params;
    
    const user = await User.findOne({ _id: id, role: 'instructor' });
    if (!user) {
      return sendError(res, 'Teacher not found', 404);
    }
    
    // Check if teacher has active course assignments
    const TeacherAssignment = require('../models/TeacherAssignment');
    const activeAssignments = await TeacherAssignment.countDocuments({
      teacherId: id,
      isActive: true
    });
    
    if (activeAssignments > 0) {
      return sendError(res, `Cannot delete teacher with ${activeAssignments} active course assignments. Please unassign from all courses first.`, 400);
    }
    
    // Delete from Firebase if applicable
    if (user.firebaseUid) {
      try {
        await admin.auth().deleteUser(user.firebaseUid);
      } catch (firebaseError) {
        console.error('Firebase deletion error:', firebaseError.message);
      }
    }
    
    // Delete inactive assignments
    await TeacherAssignment.deleteMany({ teacherId: id });
    
    // Delete the user
    await User.findByIdAndDelete(id);
    
    sendSuccess(res, {
      id,
      fullName: user.fullName,
      message: 'Teacher deleted successfully'
    }, 'Teacher deleted successfully');
  } catch (error) {
    console.error('Error in deleteTeacher:', error);
    if (error.name === 'CastError') {
      return sendError(res, 'Invalid teacher ID', 400);
    }
    sendError(res, 'Failed to delete teacher. Please try again.', 500, error.message);
  }
};

// Assign teacher to a course
const assignTeacherToCourse = async (req, res) => {
  try {
    const { teacherId, courseId } = req.body;
    const assignedBy = req.user.id;
    const notes = req.body.notes || '';
    
    if (!teacherId || !courseId) {
      return sendError(res, 'Teacher ID and Course ID are required', 400);
    }
    
    // Verify teacher exists
    const teacher = await User.findOne({ _id: teacherId, role: 'instructor' });
    if (!teacher) {
      return sendError(res, 'Teacher not found', 404);
    }
    
    // Verify course exists
    const course = await Course.findById(courseId);
    if (!course) {
      return sendError(res, 'Course not found', 404);
    }
    
    // Check if already assigned
    const TeacherAssignment = require('../models/TeacherAssignment');
    const existingAssignment = await TeacherAssignment.findOne({ teacherId, courseId });
    
    if (existingAssignment) {
      if (existingAssignment.isActive) {
        return sendError(res, 'Teacher is already assigned to this course', 409);
      } else {
        // Reactivate assignment
        existingAssignment.isActive = true;
        existingAssignment.assignedBy = assignedBy;
        existingAssignment.assignedAt = new Date();
        await existingAssignment.save();
      }
    } else {
      // Create new assignment
      await TeacherAssignment.create({
        teacherId,
        courseId,
        assignedBy,
        notes
      });
    }
    
    // Update course with teacher reference
    if (!course.assignedTeacherIds.includes(teacherId)) {
      course.assignedTeacherIds.push(teacherId);
      await course.save();
    }
    
    sendSuccess(res, {
      teacherId,
      courseId,
      courseName: course.title,
      teacherName: teacher.fullName,
      assignedAt: new Date()
    }, 'Teacher assigned to course successfully');
  } catch (error) {
    console.error('Error in assignTeacherToCourse:', error);
    sendError(res, 'Failed to assign teacher to course', 500, error.message);
  }
};

// Unassign teacher from a course
const unassignTeacherFromCourse = async (req, res) => {
  try {
    const { teacherId, courseId } = req.body;
    
    if (!teacherId || !courseId) {
      return sendError(res, 'Teacher ID and Course ID are required', 400);
    }
    
    const TeacherAssignment = require('../models/TeacherAssignment');
    const assignment = await TeacherAssignment.findOne({ teacherId, courseId, isActive: true });
    
    if (!assignment) {
      return sendError(res, 'Active assignment not found', 404);
    }
    
    // Deactivate assignment
    assignment.isActive = false;
    await assignment.save();
    
    // Update course - remove teacher from assignedTeacherIds
    const course = await Course.findById(courseId);
    if (course) {
      course.assignedTeacherIds = course.assignedTeacherIds.filter(
        id => id.toString() !== teacherId
      );
      await course.save();
    }
    
    sendSuccess(res, {
      teacherId,
      courseId,
      message: 'Teacher unassigned from course successfully'
    }, 'Teacher unassigned from course successfully');
  } catch (error) {
    console.error('Error in unassignTeacherFromCourse:', error);
    sendError(res, 'Failed to unassign teacher from course', 500, error.message);
  }
};

// Get course assignments for a teacher
const getTeacherAssignments = async (req, res) => {
  try {
    const { teacherId } = req.params;
    const { page = 1, limit = 20 } = req.query;
    
    const TeacherAssignment = require('../models/TeacherAssignment');
    const assignments = await TeacherAssignment.find({ teacherId, isActive: true })
      .populate('courseId', 'title thumbnail level isPublished enrollmentCount')
      .populate('assignedBy', 'fullName')
      .sort({ assignedAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);
    
    const total = await TeacherAssignment.countDocuments({ teacherId, isActive: true });
    
    sendSuccess(res, {
      assignments: assignments.map(a => ({
        id: a._id,
        course: a.courseId,
        assignedBy: a.assignedBy,
        assignedAt: a.assignedAt,
        notes: a.notes
      })),
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page),
      total
    }, 'Teacher assignments retrieved successfully');
  } catch (error) {
    console.error('Error in getTeacherAssignments:', error);
    sendError(res, 'Failed to retrieve teacher assignments', 500, error.message);
  }
};

// Get all teachers assigned to a specific course
const getCourseTeachers = async (req, res) => {
  try {
    const { courseId } = req.params;
    
    const TeacherAssignment = require('../models/TeacherAssignment');
    const assignments = await TeacherAssignment.find({ courseId, isActive: true })
      .populate('teacherId', 'fullName email phone avatar isActive')
      .populate('assignedBy', 'fullName')
      .sort({ assignedAt: -1 });
    
    sendSuccess(res, {
      teachers: assignments.map(a => ({
        assignmentId: a._id,
        ...a.teacherId.toObject(),
        id: a.teacherId._id,
        assignedBy: a.assignedBy,
        assignedAt: a.assignedAt,
        notes: a.notes
      }))
    }, 'Course teachers retrieved successfully');
  } catch (error) {
    console.error('Error in getCourseTeachers:', error);
    sendError(res, 'Failed to retrieve course teachers', 500, error.message);
  }
};

// Get teacher activity and performance tracking
const getTeacherActivity = async (req, res) => {
  try {
    const { teacherId } = req.params;
    const { days = 30 } = req.query;
    
    const teacher = await User.findById(teacherId).select('-password');
    if (!teacher) {
      return sendError(res, 'Teacher not found', 404);
    }
    
    const TeacherAssignment = require('../models/TeacherAssignment');
    const LiveSession = require('../models/LiveSession');
    const Conversation = require('../models/Conversation');
    const ChatMessage = require('../models/ChatMessage');
    
    const sinceDate = new Date();
    sinceDate.setDate(sinceDate.getDate() - parseInt(days));
    
    // Get assigned courses
    const assignments = await TeacherAssignment.find({
      teacherId,
      isActive: true
    }).populate('courseId', 'title thumbnail level');
    
    // Get live sessions conducted
    const liveSessions = await LiveSession.find({
      teacherId,
      createdAt: { $gte: sinceDate }
    }).sort({ createdAt: -1 });
    
    // Get total students across all assigned courses
    const courseIds = assignments.map(a => a.courseId._id);
    const totalStudents = await Enrollment.countDocuments({
      courseId: { $in: courseIds }
    });
    
    const activeStudents = await Enrollment.countDocuments({
      courseId: { $in: courseIds },
      completionStatus: { $in: ['enrolled', 'in-progress'] }
    });
    
    // Get chat conversations (student interactions)
    const chatConversations = await Conversation.countDocuments({
      'participants.userId': teacherId,
      updatedAt: { $gte: sinceDate }
    });
    
    // Get messages sent by teacher
    const messagesSent = await ChatMessage.countDocuments({
      senderId: teacherId,
      createdAt: { $gte: sinceDate }
    });
    
    // Calculate activity stats
    const completedSessions = liveSessions.filter(s => s.status === 'completed').length;
    const upcomingSessions = liveSessions.filter(s => s.status === 'scheduled' && s.scheduledAt > new Date()).length;
    
    // Get daily activity for chart
    const dailyActivity = [];
    for (let i = 0; i < 7; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dayStart = new Date(date.setHours(0, 0, 0, 0));
      const dayEnd = new Date(date.setHours(23, 59, 59, 999));
      
      const daySessions = await LiveSession.countDocuments({
        teacherId,
        scheduledAt: { $gte: dayStart, $lte: dayEnd }
      });
      
      dailyActivity.unshift({
        date: dayStart.toISOString().split('T')[0],
        sessions: daySessions
      });
    }
    
    sendSuccess(res, {
      teacher: {
        id: teacher._id,
        fullName: teacher.fullName,
        email: teacher.email,
        phone: teacher.phone,
        avatar: teacher.avatar,
        isActive: teacher.isActive,
        createdAt: teacher.createdAt,
        lastActive: teacher.lastActive
      },
      overview: {
        totalCourses: assignments.length,
        totalStudents,
        activeStudents,
        totalSessions: liveSessions.length,
        completedSessions,
        upcomingSessions,
        chatConversations,
        messagesSent
      },
      courses: assignments.map(a => ({
        id: a.courseId._id,
        title: a.courseId.title,
        thumbnail: a.courseId.thumbnail,
        level: a.courseId.level,
        assignedAt: a.assignedAt
      })),
      recentSessions: liveSessions.slice(0, 10).map(s => ({
        id: s._id,
        title: s.title,
        scheduledAt: s.scheduledAt,
        duration: s.duration,
        status: s.status,
        maxParticipants: s.maxParticipants,
        recordingUrl: s.recordingUrl
      })),
      dailyActivity,
      period: {
        days: parseInt(days),
        since: sinceDate
      }
    }, 'Teacher activity retrieved successfully');
  } catch (error) {
    console.error('Error in getTeacherActivity:', error);
    sendError(res, 'Failed to retrieve teacher activity', 500, error.message);
  }
};

// Update enrollment permissions (admin only)
const updateEnrollmentPermissions = async (req, res) => {
  try {
    const { id } = req.params;
    const { canAccessLiveSessions, canAccessChapters } = req.body;

    const Enrollment = require('../models/Enrollment');
    const enrollment = await Enrollment.findOne({ _id: id, status: Enrollment.ANY_STATUS });
    if (!enrollment) return sendError(res, 'Enrollment not found', 404);

    if (canAccessLiveSessions !== undefined) enrollment.canAccessLiveSessions = canAccessLiveSessions;
    if (canAccessChapters !== undefined) enrollment.canAccessChapters = canAccessChapters;

    await enrollment.save();

    sendSuccess(res, {
      id: enrollment._id,
      canAccessLiveSessions: enrollment.canAccessLiveSessions,
      canAccessChapters: enrollment.canAccessChapters,
    }, 'Enrollment permissions updated successfully');
  } catch (error) {
    console.error('Error in updateEnrollmentPermissions:', error);
    sendError(res, 'Failed to update enrollment permissions', 500, error.message);
  }
};

module.exports = {
  getStudents,
  getAdmins,
  getTeachers,
  createTeacher,
  updateTeacher,
  deleteTeacher,
  assignTeacherToCourse,
  unassignTeacherFromCourse,
  getTeacherAssignments,
  getCourseTeachers,
  getTeacherActivity,
  updateUserRole,
  updateStudent,
  getStudentDetail,
  deleteStudent,
  getCourseStats,
  getPaymentStats,
  getExamStats,
  getStudentAnalytics,
  getCourseAnalytics,
  getStudentCoursePerformance,
  createAdmin,
  syncFirebaseUser,
  deleteUserSync,
  manualSyncAllUsers,
  getUserDeviceInfo,
  resetUserDevice,
  toggleStudentStatus,
  updateEnrollmentPermissions,
  resetStudentPassword,
  unenrollStudent
};
