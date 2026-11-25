const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const User = require('../models/User');
const Section = require('../models/Section');
const Lesson = require('../models/Lesson');
const Notification = require('../models/Notification');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');
const { transformUrls } = require('../utils/url.utils');
const emailService = require('../services/email.service');
const notificationController = require('./notification.controller');
const { searchFilter, relevance } = require('../utils/courseSearch');

// Helper function to send notifications when a course is published
const sendCourseNotifications = async (course) => {
  try {
    // 1. Send emails to all active users
    const users = await User.find({ isActive: true }, 'fullName email');
    if (users.length > 0) {
      await emailService.sendNewCourseEmail(users, course);
      console.log(`New course email sent to ${users.length} users for course: ${course.title}`);
    }
    
    // 2. Send push notification to topic
    await notificationController.sendPushToTopic(
      'courses',
      'New Course Available!',
      `New course "${course.title}" is now available. Check it out!`,
      { route: '/course/' + course._id, id: course._id.toString() }
    );

    // 3. Create a real notification for all admins to track in their system notifications
    const admins = await User.find({ role: 'admin' }, '_id');
    for (const adminUser of admins) {
      await Notification.createNotification({
        userId: adminUser._id,
        title: 'Course Published Successfully',
        message: `Your course "${course.title}" has been published and notifications have been sent to all users.`,
        type: 'course',
        data: { courseId: course._id, severity: 'info' }
      });
    }
  } catch (error) {
    console.error('Error sending course notifications:', error);
  }
};

// Get all courses
const getCourses = async (req, res) => {
  try {
    const { page = 1, limit = 20, search, level, minPrice, maxPrice, category, showUnpublished } = req.query;
    const finalLimit = Math.min(parseInt(limit) || 20, 1000);
    
    
    // Build filter object
    const filter = {};
    
    // Show unpublished courses if specifically requested via query param
    // This allows both authenticated and unauthenticated requests to see unpublished courses
    if (showUnpublished !== 'true') {
      filter.isPublished = true;
    }
    
    
    // Partial words in any order ("bio s3" finds "Biology S3"); regex-safe.
    const searchMatch = search ? searchFilter(search) : null;
    if (searchMatch) Object.assign(filter, searchMatch);
    
    if (level) {
      filter.level = level;
    }
    
    if (category) {
      // Check if category is a valid ObjectId, if not try to find by name
      const ObjectId = require('mongoose').Types.ObjectId;
      if (ObjectId.isValid(category)) {
        // Convert string to ObjectId for proper MongoDB matching
        filter.category = new ObjectId(category);
      } else {
        // If it's not a valid ObjectId, try to find category by name and get its ID
        const Category = require('../models/Category');
        const categoryDoc = await Category.findOne({ 
          $or: [
            { name: { $regex: category, $options: 'i' } },
            { name: category.replace(/_/g, ' ') }
          ]
        });
        
        if (categoryDoc) {
          filter.category = categoryDoc._id;
        }
      }
    }
    
    if (minPrice || maxPrice) {
      filter.price = {};
      if (minPrice) filter.price.$gte = Number(minPrice);
      if (maxPrice) filter.price.$lte = Number(maxPrice);
    }
    
    
    // Use aggregation to calculate enrollmentCount and averageRating on the fly
    const aggregationPipeline = [
      { $match: filter },
      {
        $lookup: {
          from: 'enrollments', // MongoDB collection name for Enrollment model
          localField: '_id',
          foreignField: 'courseId',
          as: 'enrollments'
        }
      },
      {
        $addFields: {
          enrollmentCount: { $size: '$enrollments' },
          averageRating: { 
            $ifNull: [
              { $avg: '$enrollments.rating' }, 
              0 
            ] 
          }
        }
      },
      { $sort: { createdAt: -1 } },
      { $skip: (Number(page) - 1) * finalLimit },
      { $limit: finalLimit }
    ];

    let courses = await Course.aggregate(aggregationPipeline);
    
    // Since aggregation returns plain objects, we need to populate them manually
    courses = await Course.populate(courses, [
      { path: 'createdBy', select: 'fullName' },
      { path: 'category', select: 'name' }
    ]);
    
        
    const total = await Course.countDocuments(filter);
    
    sendSuccess(res, {
      courses: transformUrls(courses),
      totalPages: Math.ceil(total / finalLimit),
      currentPage: Number(page),
      total,
      hasNextPage: Number(page) < Math.ceil(total / finalLimit),
      limit: finalLimit
    }, 'Courses retrieved successfully');
  } catch (error) {
    console.error('Error in getCourses:', error);
    sendError(res, 'Failed to retrieve courses', 500, error.message);
  }
};

// Get course by ID
const getCourseById = async (req, res) => {
  try {
    const mongoose = require('mongoose');
    const ObjectId = mongoose.Types.ObjectId;
    
    if (!ObjectId.isValid(req.params.id)) {
      return sendNotFound(res, 'Invalid course ID');
    }

    const courses = await Course.aggregate([
      { $match: { _id: new ObjectId(req.params.id) } },
      {
        $lookup: {
          from: 'enrollments',
          localField: '_id',
          foreignField: 'courseId',
          as: 'enrollments'
        }
      },
      {
        $addFields: {
          enrollmentCount: { $size: '$enrollments' },
          averageRating: { 
            $ifNull: [
              { $avg: '$enrollments.rating' }, 
              0 
            ] 
          }
        }
      },
      { $limit: 1 }
    ]);
    
    if (!courses || courses.length === 0) {
      return sendNotFound(res, 'Course not found');
    }
    
    let course = courses[0];
    
    // Manually populate course createdBy and category
    course = await Course.populate(course, [
      { path: 'createdBy', select: 'fullName' },
      { path: 'category', select: 'name' }
    ]);
    
    // If course is not published, only allow admin access
    if (!course.isPublished) {
      // Check if user is authenticated and is admin
      if (!req.user || req.user.role !== 'admin') {
        return sendNotFound(res, 'Course not found');
      }
    }
    
    sendSuccess(res, transformUrls(course), 'Course retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve course', 500, error.message);
  }
};

// Create course (admin only)
const createCourse = async (req, res) => {
  try {
    const { 
      title, description, price, duration, durationUnit, 
      level, thumbnail, instructorName, categoryId, 
      accessDuration, accessDurationUnit, accessDurationDays 
    } = req.body;
    
    // Validate required fields
    if (!title || !title.trim()) {
      return sendError(res, 'Title is required', 400);
    }
    if (!description || !description.trim()) {
      return sendError(res, 'Description is required', 400);
    }
    // Convert to number if it's a string and validate
    const parsedPrice = typeof price === 'string' ? parseFloat(price) : price;
    if (isNaN(parsedPrice) || parsedPrice < 0) {
      return sendError(res, 'Valid price is required', 400);
    }
    // Convert to number if it's a string and validate
    const parsedDuration = typeof duration === 'string' ? parseInt(duration) : duration;
    if (isNaN(parsedDuration) || parsedDuration <= 0) {
      return sendError(res, 'Valid duration is required', 400);
    }
    if (!level || !['beginner', 'intermediate', 'advanced'].includes(level)) {
      return sendError(res, 'Valid level is required (beginner, intermediate, advanced)', 400);
    }
    
    const courseData = {
      title: title.trim(),
      description: description.trim(),
      price: parsedPrice,
      duration: parsedDuration,
      durationUnit: durationUnit || 'minutes',
      level,
      thumbnail: thumbnail || null, // Ensure thumbnail is null if not provided
      instructorName: instructorName || null,
      createdBy: req.user.id,
      accessDuration: accessDuration || null,
      accessDurationUnit: accessDurationUnit || 'days'
    };
    
    // Calculate accessDurationDays for backward compatibility
    if (accessDuration) {
      const value = parseInt(accessDuration);
      const unit = accessDurationUnit || 'days';
      let days = value;
      
      switch (unit) {
        case 'hours':
          days = value / 24;
          break;
        case 'weeks':
          days = value * 7;
          break;
        case 'months':
          days = value * 30; // Approximation
          break;
        case 'years':
          days = value * 365; // Approximation
          break;
      }
      courseData.accessDurationDays = Math.ceil(days);
    } else if (accessDurationDays !== undefined) {
      courseData.accessDurationDays = accessDurationDays === null || accessDurationDays === '' ? null : parseInt(accessDurationDays);
      courseData.accessDuration = courseData.accessDurationDays;
      courseData.accessDurationUnit = 'days';
    }
    
    // Add learning objectives and requirements if provided
    if (req.body.learningObjectives && Array.isArray(req.body.learningObjectives)) {
      courseData.learningObjectives = req.body.learningObjectives.filter(obj => obj.trim() !== '');
    }
    if (req.body.requirements && Array.isArray(req.body.requirements)) {
      courseData.requirements = req.body.requirements.filter(req => req.trim() !== '');
    }
    
    // Add category if provided
    if (categoryId) {
      courseData.category = categoryId;
    }
    
    const course = await Course.create(courseData);
    
    // Populate the course with user details before sending response
    const populatedCourse = await Course.findById(course._id)
      .populate('createdBy', 'id fullName email role createdAt');

    // If the course is published, send notification email and push notification
    if (populatedCourse.isPublished) {
      await sendCourseNotifications(populatedCourse);
    }

    sendSuccess(res, transformUrls(populatedCourse), 'Course created successfully', 201);
  } catch (error) {
    console.error('Error creating course:', error);
    sendError(res, 'Failed to create course', 500, error.message);
  }
};

// Update course (admin only)
const updateCourse = async (req, res) => {
  try {
    // Prepare update data
    const updateData = { ...req.body };
    
    // Map categoryId to category for MongoDB
    if (req.body.categoryId) {
      updateData.category = req.body.categoryId;
      delete updateData.categoryId; // Remove categoryId to avoid confusion
    }
    
    // Calculate accessDurationDays for backward compatibility if accessDuration is updated
    if (req.body.accessDuration) {
      const value = parseInt(req.body.accessDuration);
      const unit = req.body.accessDurationUnit || 'days';
      let days = value;
      
      switch (unit) {
        case 'hours':
          days = value / 24;
          break;
        case 'weeks':
          days = value * 7;
          break;
        case 'months':
          days = value * 30; // Approximation
          break;
        case 'years':
          days = value * 365; // Approximation
          break;
      }
      updateData.accessDurationDays = Math.ceil(days);
    } else if (req.body.accessDurationDays !== undefined) {
      updateData.accessDurationDays = req.body.accessDurationDays === null || req.body.accessDurationDays === '' ? null : parseInt(req.body.accessDurationDays);
      if (updateData.accessDurationDays) {
        updateData.accessDuration = updateData.accessDurationDays;
        updateData.accessDurationUnit = 'days';
      }
    }
    
    // Check if isPublished is being changed from false to true
    const oldCourse = await Course.findById(req.params.id);
    if (!oldCourse) {
      return sendNotFound(res, 'Course not found');
    }
    
    const wasPublished = oldCourse.isPublished;
    const isNowPublished = req.body.isPublished === true || req.body.isPublished === 'true';

    const course = await Course.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );
    
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }

    // Trigger notifications if course was just published
    if (!wasPublished && isNowPublished) {
      await sendCourseNotifications(course);
    }
    
    // Update existing enrollments if access duration changed
    if (req.body.accessDuration || req.body.accessDurationDays !== undefined) {
      const Enrollment = require('../models/Enrollment');
      const enrollments = await Enrollment.find({ courseId: req.params.id });
      
      console.log(`Updating ${enrollments.length} existing enrollments with new access duration`);
      
      for (const enrollment of enrollments) {
        // Calculate new expiration date based on updated course access duration
        let newExpirationDate = null;
        
        if (req.body.accessDuration) {
          const value = parseInt(req.body.accessDuration);
          const unit = req.body.accessDurationUnit || 'days';
          let days = value;
          
          switch (unit) {
            case 'hours':
              days = value / 24;
              break;
            case 'weeks':
              days = value * 7;
              break;
            case 'months':
              days = value * 30; // Approximation
              break;
            case 'years':
              days = value * 365; // Approximation
              break;
          }
          
          newExpirationDate = new Date(enrollment.enrollmentDate);
          newExpirationDate.setDate(newExpirationDate.getDate() + Math.ceil(days));
        } else if (req.body.accessDurationDays !== undefined) {
          const days = req.body.accessDurationDays === null || req.body.accessDurationDays === '' ? null : parseInt(req.body.accessDurationDays);
          if (days) {
            newExpirationDate = new Date(enrollment.enrollmentDate);
            newExpirationDate.setDate(newExpirationDate.getDate() + days);
          }
        }
        
        // Check if enrollment should be unenrolled (already expired)
        const now = new Date();
        if (newExpirationDate && newExpirationDate < now) {
          console.log(`Unenrolling student ${enrollment.userId} - access expired on ${newExpirationDate}`);
          await Enrollment.findByIdAndDelete(enrollment._id);
        } else if (newExpirationDate) {
          console.log(`Updating expiration for student ${enrollment.userId} to ${newExpirationDate}`);
          await Enrollment.findByIdAndUpdate(enrollment._id, {
            accessExpirationDate: newExpirationDate
          });
        } else {
          console.log(`Removing expiration for student ${enrollment.userId} - unlimited access`);
          await Enrollment.findByIdAndUpdate(enrollment._id, {
            accessExpirationDate: null
          });
        }
      }
    }
    
    sendSuccess(res, transformUrls(course), 'Course updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update course', 500, error.message);
  }
};

// Delete course (admin only)
const deleteCourse = async (req, res) => {
  try {
    const course = await Course.findByIdAndDelete(req.params.id);
    
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }
    
    sendSuccess(res, null, 'Course deleted successfully');
  } catch (error) {
    sendError(res, 'Failed to delete course', 500, error.message);
  }
};

// Get recommended courses for the user
const getRecommendedCourses = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : null;
    const limit = parseInt(req.query.limit) || 8;

    let enrolledCourseIds = [];
    const interestedCategoryIds = new Set();
    const levelProgress = {
      'beginner': 0,
      'intermediate': 0,
      'advanced': 0
    };
    
    // User preferences from onboarding
    let userInterests = [];
    let userShortTermGoal = null;
    let userMidTermGoal = null;
    let userLongTermGoal = null;

    if (userId) {
      // 1. Get user's enrolled courses
      const enrollments = await Enrollment.find({ userId }).populate('courseId');
      enrolledCourseIds = enrollments.map(e => e.courseId ? e.courseId._id : null).filter(id => id !== null);
      
      // 2. Identify categories and levels user is interested in from enrollments
      enrollments.forEach(e => {
        if (e.courseId) {
          if (e.courseId.category) interestedCategoryIds.add(e.courseId.category.toString());
          if (e.courseId.level) levelProgress[e.courseId.level]++;
        }
      });
      
      // 3. Get user's onboarding preferences
      const user = await User.findById(userId);
      if (user) {
        userInterests = user.interests || [];
        userShortTermGoal = user.shortTermGoal;
        userMidTermGoal = user.midTermGoal;
        userLongTermGoal = user.longTermGoal;
      }
    }

    // Determine target level (if they've done many beginner, suggest intermediate)
    let targetLevel = 'beginner';
    if (levelProgress['beginner'] > 2) targetLevel = 'intermediate';
    if (levelProgress['intermediate'] > 1) targetLevel = 'advanced';

    // Get categories that match user interests
    const Category = require('../models/Category');
    const interestCategoryIds = new Set();
    if (userInterests.length > 0) {
      const matchingCategories = await Category.find({
        name: { $in: userInterests.map(i => new RegExp(i, 'i')) }
      });
      matchingCategories.forEach(cat => interestCategoryIds.add(cat._id.toString()));
    }

    // Combine category interests from enrollments and onboarding
    interestCategoryIds.forEach(id => interestedCategoryIds.add(id));

    // 3. Recommendation aggregation pipeline
    const aggregationPipeline = [
      { 
        $match: { 
          isPublished: true,
          _id: { $nin: enrolledCourseIds } // Exclude already enrolled
        } 
      },
      {
        $lookup: {
          from: 'enrollments',
          localField: '_id',
          foreignField: 'courseId',
          as: 'allEnrollments'
        }
      },
      {
        $addFields: {
          enrollmentCount: { $size: '$allEnrollments' },
          averageRating: { 
            $ifNull: [
              { $avg: '$allEnrollments.rating' }, 
              0 
            ] 
          },
          // Scoring factors
          categoryScore: {
            $cond: [
              { $in: [{ $toString: '$category' }, Array.from(interestedCategoryIds)] },
              15, // Higher weight for category matching
              0
            ]
          },
          levelScore: {
            $cond: [
              { $eq: ['$level', targetLevel] },
              8,
              0
            ]
          },
          // Bonus for matching user goals
          goalScore: {
            $cond: [
              {
                $or: [
                  { $regexMatch: { input: '$title', regex: userShortTermGoal || '', options: 'i' } },
                  { $regexMatch: { input: '$description', regex: userShortTermGoal || '', options: 'i' } },
                  { $regexMatch: { input: '$title', regex: userMidTermGoal || '', options: 'i' } },
                  { $regexMatch: { input: '$description', regex: userMidTermGoal || '', options: 'i' } },
                  { $regexMatch: { input: '$title', regex: userLongTermGoal || '', options: 'i' } },
                  { $regexMatch: { input: '$description', regex: userLongTermGoal || '', options: 'i' } }
                ]
              },
              10,
              0
            ]
          }
        }
      },
      {
        $addFields: {
          totalScore: {
            $add: [
              '$categoryScore',
              '$levelScore',
              '$goalScore',
              { $multiply: ['$averageRating', 2] }, // Rating weight
              { $divide: ['$enrollmentCount', 10] }  // Popularity weight
            ]
          }
        }
      },
      { $sort: { totalScore: -1, createdAt: -1 } },
      { $limit: limit }
    ];

    let recommendedCourses = await Course.aggregate(aggregationPipeline);
    
    // Populate
    recommendedCourses = await Course.populate(recommendedCourses, [
      { path: 'createdBy', select: 'fullName' },
      { path: 'category', select: 'name' }
    ]);

    sendSuccess(res, transformUrls(recommendedCourses), 'Recommended courses retrieved successfully');
  } catch (error) {
    console.error('Error in getRecommendedCourses:', error);
    sendError(res, 'Failed to retrieve recommended courses', 500, error.message);
  }
};

/**
 * GET /api/courses/suggest?q=bio&limit=8
 * Small, ranked list for search-as-you-type. Admins may add
 * `showUnpublished=true` to include draft courses.
 */
const suggestCourses = async (req, res) => {
  try {
    const q = String(req.query.q || '').trim();
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 8, 1), 20);
    const match = searchFilter(q, ['title', 'description', 'instructorName']);
    if (!match) return sendSuccess(res, { suggestions: [] }, 'No query');

    const filter = { ...match };
    const isAdmin = req.user && req.user.role === 'admin';
    if (!(isAdmin && req.query.showUnpublished === 'true')) filter.isPublished = true;

    const candidates = await Course.find(filter)
      .select('title description thumbnail level instructorName category isPublished')
      .populate('category', 'name')
      .limit(80)
      .lean();

    const ranked = candidates
      .map((c) => ({ c, score: relevance(q, c.title, `${c.instructorName || ''} ${c.category?.name || ''} ${c.description || ''}`) }))
      .filter((r) => r.score > 0)
      .sort((a, b) => b.score - a.score || String(a.c.title).localeCompare(String(b.c.title)))
      .slice(0, limit)
      .map(({ c }) => ({
        id: String(c._id),
        title: c.title,
        thumbnail: c.thumbnail || null,
        level: c.level || null,
        category: c.category?.name || null,
        instructorName: c.instructorName || null,
        isPublished: !!c.isPublished,
      }));

    return sendSuccess(res, { suggestions: transformUrls(ranked) }, 'Suggestions');
  } catch (error) {
    console.error('suggestCourses error:', error);
    return sendError(res, 'Could not load suggestions', 500);
  }
};

module.exports = {
  suggestCourses,
  getCourses,
  getCourseById,
  createCourse,
  updateCourse,
  deleteCourse,
  getRecommendedCourses
};