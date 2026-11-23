const Payment = require('../models/Payment');
const Enrollment = require('../models/Enrollment');
const Course = require('../models/Course');
const User = require('../models/User');
const { hasSchoolCourseAccess } = require('../services/school/subscription.service');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');
const emailService = require('../services/email.service');
const { fulfillPayment, revokePayment } = require('../services/payments/fulfillment.service');

// Admin-initiated payment for a student
const adminInitiatePayment = async (req, res) => {
  try {
    const { userId, courseId, paymentMethod, contactInfo } = req.body;
    const adminId = req.user.id;

    console.log('=== ADMIN PAYMENT INITIATION DEBUG ===');
    console.log('Received courseId:', courseId);
    console.log('Received userId:', userId);
    console.log('Received paymentMethod:', paymentMethod);
    console.log('Received contactInfo:', contactInfo);
    console.log('Admin ID:', adminId);

    // Validate required fields
    if (!userId || !courseId || !paymentMethod || !contactInfo) {
      return sendError(res, 'User ID, Course ID, payment method, and contact info are required', 400);
    }

    // Check if course exists and is paid
    const course = await Course.findById(courseId);
    console.log('Course found:', course ? course.title : 'NOT FOUND');
    console.log('Course ID in DB:', course ? course._id : 'N/A');
    console.log('Course price:', course ? course.price : 'N/A');
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }

    if (course.price <= 0) {
      return sendError(res, 'This course is free and does not require payment', 400);
    }

    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      return sendNotFound(res, 'User not found');
    }

    // Check if user is already enrolled
    const existingEnrollment = await Enrollment.findOne({ userId, courseId });
    if (existingEnrollment) {
      return sendError(res, 'User is already enrolled in this course', 400);
    }

    // Check if there's an ACTIVE payment already in progress for this user and course
    // Allow new payments if previous payments were completed, approved, failed, or cancelled
    const existingActivePayment = await Payment.findOne({ 
      userId, 
      courseId,
      status: { $in: ['pending', 'admin_review'] }
    });
    if (existingActivePayment) {
      return sendError(res, 'Payment already in progress for this course', 400);
    }

    // Generate unique transaction ID
    const transactionId = `TXN${Date.now()}${Math.random().toString(36).substr(2, 9).toUpperCase()}`;

    // Create payment record
    console.log('Creating payment with courseId:', courseId);
    console.log('Payment amount:', course.price);
    console.log('Payment currency:', 'RWF');
    console.log('Payment method:', paymentMethod);
    
    const payment = await Payment.create({
      userId,
      courseId,
      amount: course.price,
      currency: 'RWF',
      paymentMethod,
      transactionId,
      contactInfo,
      status: 'pending',
      adminInitiated: true, // Flag to indicate this was initiated by admin
      initiatedBy: adminId // Track which admin initiated it
    });
    
    console.log('Payment created with ID:', payment._id);
    console.log('Payment courseId in created payment:', payment.courseId);

    // Notify admins about the new payment request
    try {
      const admins = await User.find({ role: 'admin' }, 'email');
      const adminEmails = admins.map(admin => admin.email);
      
      await emailService.sendAdminPaymentNotification(adminEmails, user, payment, course);
    } catch (notificationError) {
      console.error('Error in admin payment notification:', notificationError);
    }

    sendSuccess(res, {
      paymentId: payment._id,
      transactionId: payment.transactionId,
      amount: payment.amount,
      currency: payment.currency,
      status: payment.status,
      contactInfo: payment.contactInfo,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email
      },
      course: {
        id: course._id,
        title: course.title,
        price: course.price
      },
      adminContact: 'Contact admin at: info@excellencecoachinghub.com or +250 788 535 156 / +250 793 828 834',
      instructions: 'Payment initiated by admin. Please contact the student to complete the payment process.'
    }, 'Payment initiated successfully by admin', 201);

  } catch (error) {
    console.error('Error in adminInitiatePayment:', error);
    sendError(res, 'Failed to initiate payment', 500, error.message);
  }
};

// Initiate payment for a course
const initiatePayment = async (req, res) => {
  try {
    const { courseId, paymentMethod, contactInfo } = req.body;
    const userId = req.user.id;

    // Validate required fields
    if (!courseId || !paymentMethod || !contactInfo) {
      return sendError(res, 'Course ID, payment method, and contact info are required', 400);
    }

    // Check if course exists and is paid
    const course = await Course.findById(courseId);
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }

    // School students get the courses meant for their class free: enroll directly.
    if (await hasSchoolCourseAccess(userId, course)) {
      return sendError(res, 'Your school already gives you this course for free. Please enroll directly from the course page.', 400);
    }

    if (course.price <= 0) {
      return sendError(res, 'This course is free and does not require payment', 400);
    }

    // Check if user is already enrolled
    const existingEnrollment = await Enrollment.findOne({ userId, courseId, status: Enrollment.ANY_STATUS });
    if (existingEnrollment && existingEnrollment.status === 'suspended') {
      return sendError(res, 'Your access to this course has been suspended by an administrator. Please contact support.', 403);
    }
    if (existingEnrollment && existingEnrollment.status === 'unenrolled') {
      // Unenrolling never refunds, so a still-valid payment means the learner
      // should simply re-enroll rather than pay twice.
      const expired = existingEnrollment.accessExpirationDate
        && new Date() > existingEnrollment.accessExpirationDate;
      const priorPayment = existingEnrollment.paymentId || await Payment.exists({
        userId, courseId, status: { $in: ['completed', 'approved'] }
      });
      if (!expired && priorPayment) {
        return sendError(res, 'You have already paid for this course. Re-enroll from the course page to continue where you left off.', 400);
      }
    } else if (existingEnrollment) {
      return sendError(res, 'You are already enrolled in this course', 400);
    }

    // Check if there's an ACTIVE payment already in progress for this user and course
    // Allow new payments if previous payments were completed, approved, failed, or cancelled
    const existingActivePayment = await Payment.findOne({ 
      userId, 
      courseId,
      status: { $in: ['pending', 'admin_review'] }
    });
    if (existingActivePayment) {
      return sendError(res, 'Payment already in progress for this course', 400);
    }

    // Generate unique transaction ID
    const transactionId = `TXN${Date.now()}${Math.random().toString(36).substr(2, 9).toUpperCase()}`;

    // Create payment record
    const payment = await Payment.create({
      userId,
      courseId,
      amount: course.price,
      currency: 'RWF',
      paymentMethod,
      transactionId,
      contactInfo,
      status: 'pending'
    });

    // Notify admins about the new payment request
    try {
      const user = await User.findById(userId);
      const admins = await User.find({ role: 'admin' }, 'email');
      const adminEmails = admins.map(admin => admin.email);
      
      await emailService.sendAdminPaymentNotification(adminEmails, user, payment, course);
    } catch (notificationError) {
      console.error('Error in admin payment notification:', notificationError);
    }

    sendSuccess(res, {
      paymentId: payment._id,
      transactionId: payment.transactionId,
      amount: payment.amount,
      currency: payment.currency,
      status: payment.status,
      contactInfo: payment.contactInfo,
      adminContact: 'Contact admin at: info@excellencecoachinghub.com or +250 788 535 156 / +250 793 828 834',
      instructions: 'Please contact the admin with your transaction ID to complete the payment process'
    }, 'Payment initiated successfully. Please contact admin to complete payment.', 201);

  } catch (error) {
    sendError(res, 'Failed to initiate payment', 500, error.message);
  }
};

// Verify payment (admin only)
const verifyPayment = async (req, res) => {
  try {
    const { paymentId, status, adminNotes } = req.body;

    // Validate required fields
    if (!paymentId || !status) {
      return sendError(res, 'Payment ID and status are required', 400);
    }

    // Find payment
    console.log('Verifying payment with ID:', paymentId);
    const payment = await Payment.findById(paymentId)
      .populate('userId', 'fullName email')
      .populate('courseId', 'title price');
    
    if (!payment) {
      console.log('Payment not found with ID:', paymentId);
    } else {
      console.log('Payment found:', payment.transactionId, 'Current status:', payment.status);
    }

    if (!payment) {
      return sendNotFound(res, 'Payment not found');
    }

    try {
      // Store populated values before updating
      const userIdInfo = {
        id: payment.userId?._id || payment.userId,
        fullName: payment.userId?.fullName || 'Unknown User',
        email: payment.userId?.email || 'unknown@example.com'
      };
      
      const courseIdInfo = {
        id: payment.courseId?._id || payment.courseId,
        title: payment.courseId?.title || 'Unknown Course'
      };
      
      // Update payment status
      const adminId = req.user.id;
      console.log('Setting payment status to:', status);
      console.log('Admin ID:', adminId);
      
      payment.status = status;
      payment.adminApproval = {
        approvedBy: adminId,
        approvedAt: new Date(),
        adminNotes: adminNotes || ''
      };
      
      console.log('Admin approval object created:', payment.adminApproval);

      if (status === 'approved' || status === 'completed') {
        // Same fulfilment the automatic (iTechPay) path uses: course enrollment,
        // teacher's-guide access or school-term seats, depending on the purpose.
        payment.paymentDate = payment.paymentDate || new Date();
        await fulfillPayment(payment, { actorId: adminId });
      } else if (['failed', 'cancelled'].includes(status)) {
        // Reversing an approval takes a guide course away again.
        await revokePayment(payment);
      }

      // Save the updated payment to the database
      console.log('Saving updated payment with new status:', status);
      await payment.save();
      console.log('Payment saved successfully');

      // Construct response using preserved values
      console.log('Preparing response data...');
      const responseData = {
        paymentId: payment._id,
        transactionId: payment.transactionId,
        status: payment.status,
        userId: userIdInfo.id,
        userName: userIdInfo.fullName,
        userEmail: userIdInfo.email,
        courseId: courseIdInfo.id,
        courseTitle: courseIdInfo.title,
        amount: payment.amount,
        approvedBy: adminId,
        approvedAt: payment.adminApproval.approvedAt,
        adminNotes: payment.adminApproval.adminNotes
      };
      
      console.log('Response data prepared:', responseData);
      
      // Send email notification to user about payment status
      try {
        await emailService.sendPaymentStatusEmail(
          userIdInfo.email, 
          { fullName: userIdInfo.fullName }, 
          payment, 
          status
        );
        console.log(`Payment status email sent to user: ${userIdInfo.email}`);
      } catch (emailError) {
        console.error('Error sending payment status email:', emailError);
        // Don't fail the entire operation if email fails
      }
      
      sendSuccess(res, responseData, `Payment ${status} successfully`);
      
    } catch (updateError) {
      console.error('Error in verifyPayment update process:', updateError);
      console.error('Error stack:', updateError.stack);
      return sendError(res, 'Failed to verify payment due to internal error', 500, updateError.message);
    }

  } catch (error) {
    sendError(res, 'Failed to verify payment', 500, error.message);
  }
};

// Get user's payments
const getMyPayments = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status } = req.query;

    console.log('getMyPayments called with:', { userId, status });

    const filter = { userId };
    if (status) {
      filter.status = status;
    }

    // Online payments still waiting: ask iTechPay now (throttled per payment),
    // so screens polling this list see the purchase unlock straight away.
    try {
      const { refresh } = require('../services/payments/checkout.service');
      const inFlight = await Payment.find({ userId, status: 'pending', 'gateway.provider': 'itecpay' }).limit(5);
      await Promise.all(inFlight.map((p) => refresh(p, { via: 'poll' }).catch(() => null)));
    } catch (e) {
      console.warn('getMyPayments: refresh of online payments failed:', e.message);
    }

    console.log('Filter being used:', filter);

    const payments = await Payment.find(filter)
      .populate('courseId', 'title price')
      .sort({ createdAt: -1 });

    console.log('Found payments:', payments.length);

    // Handle potential population errors by ensuring courseId exists
    const sanitizedPayments = payments.map(payment => {
      const paymentObj = payment.toObject();
      // Ensure courseId is properly populated or provide fallback
      if (!paymentObj.courseId || typeof paymentObj.courseId === 'string') {
        console.log('CourseId not properly populated for payment:', paymentObj._id);
        paymentObj.courseId = paymentObj.courseId || 'unknown';
      }
      return paymentObj;
    });

    console.log('Sending response with', sanitizedPayments.length, 'payments');
    sendSuccess(res, sanitizedPayments, 'Payments retrieved successfully');

  } catch (error) {
    console.error('Error in getMyPayments:', error);
    console.error('Error stack:', error.stack);
    sendError(res, 'Failed to retrieve payments', 500, error.message);
  }
};

// Get payment by ID
const getPaymentById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const payment = await Payment.findById(id)
      .populate('courseId', 'title price')
      .populate('userId', 'fullName email');

    if (!payment) {
      return sendNotFound(res, 'Payment not found');
    }

    // Check if user owns this payment or is admin
    if (payment.userId._id.toString() !== userId && req.user.role !== 'admin') {
      return sendForbidden(res, 'You do not have permission to view this payment');
    }

    sendSuccess(res, payment, 'Payment retrieved successfully');

  } catch (error) {
    sendError(res, 'Failed to retrieve payment', 500, error.message);
  }
};

// Get all payments (admin only)
const escapeRegex = (v) => String(v).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const ONLINE_STUCK_MS = 15 * 60 * 1000;

/** Payments an admin has to act on. */
function needsAttentionFilter() {
  return { $or: [
    { status: 'admin_review' },
    // manual request waiting for approval
    { status: 'pending', 'gateway.provider': { $exists: false } },
    // online payment with no answer from iTechPay for a while
    { status: 'pending', 'gateway.provider': 'itecpay', createdAt: { $lt: new Date(Date.now() - ONLINE_STUCK_MS) } },
  ] };
}

/**
 * Builds the admin list filter from the query string. Everything is filtered
 * on the server so search and status work across all payments, not one page.
 *   status, purpose (course|teacher_guide|school_term), channel (online|manual),
 *   method, from, to (ISO dates), attention=1, search (user, course, school,
 *   transaction id, iTechPay reference, phone), courseId, userId
 */
async function adminPaymentFilter(q) {
  const and = [];
  if (q.status) and.push({ status: { $in: String(q.status).split(',').map((x) => x.trim()).filter(Boolean) } });
  if (q.courseId) and.push({ courseId: String(q.courseId) });
  if (q.userId) and.push({ userId: String(q.userId) });
  if (['teacher_guide', 'school_term'].includes(q.purpose)) and.push({ purpose: q.purpose });
  else if (q.purpose === 'course') and.push({ purpose: { $nin: ['teacher_guide', 'school_term'] } });
  if (q.channel === 'online') and.push({ 'gateway.provider': 'itecpay' });
  else if (q.channel === 'manual') and.push({ 'gateway.provider': { $exists: false } });
  if (q.method) and.push({ paymentMethod: String(q.method) });
  const from = q.from ? new Date(q.from) : null;
  const to = q.to ? new Date(q.to) : null;
  if (from && !Number.isNaN(+from)) and.push({ createdAt: { $gte: from } });
  if (to && !Number.isNaN(+to)) and.push({ createdAt: { $lte: to } });
  if (q.attention === '1' || q.attention === 'true') and.push(needsAttentionFilter());

  const search = String(q.search || '').trim().slice(0, 80);
  if (search) {
    const rx = new RegExp(escapeRegex(search), 'i');
    const School = require('../models/School');
    const [users, courses, schools] = await Promise.all([
      User.find({ $or: [{ fullName: rx }, { email: rx }, { phone: rx }] }).select('_id').limit(300).lean(),
      Course.find({ title: rx }).select('_id').limit(300).lean(),
      School.find({ name: rx }).select('_id').limit(100).lean(),
    ]);
    and.push({ $or: [
      { transactionId: rx },
      { 'gateway.reference': rx },
      { 'gateway.phone': rx },
      { contactInfo: rx },
      { userId: { $in: users.map(u => u._id) } },
      { courseId: { $in: courses.map(c => c._id) } },
      { schoolId: { $in: schools.map(x => x._id) } },
    ] });
  }
  return and.length ? { $and: and } : {};
}

// Get all payments (admin only)
const getAllPayments = async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const finalLimit = Math.min(parseInt(req.query.limit, 10) || 20, 100);
    const filter = await adminPaymentFilter(req.query);

    const [payments, total] = await Promise.all([
      Payment.find(filter)
        .populate('userId', 'fullName email phone')
        .populate('courseId', 'title price')
        .populate('schoolId', 'name')
        .populate('termId', 'academicYear term')
        .populate('adminApproval.approvedBy', 'fullName')
        .sort({ createdAt: -1 })
        .skip((page - 1) * finalLimit)
        .limit(finalLimit),
      Payment.countDocuments(filter),
    ]);

    sendSuccess(res, {
      payments,
      totalPages: Math.ceil(total / finalLimit),
      currentPage: page,
      total
    }, 'Payments retrieved successfully');
  } catch (error) {
    console.error('Error in getAllPayments:', error);
    sendError(res, 'Failed to retrieve payments', 500, error.message);
  }
};

/**
 * GET /api/payments/admin/overview (admin) — revenue and workload at a glance:
 * totals, this month vs last month, by service, by method, online vs manual,
 * status counts, what needs attention and the last 30 days.
 */
const getPaymentOverview = async (req, res) => {
  try {
    const PAID = { status: { $in: ['completed', 'approved'] } };
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const since30 = new Date(now.getTime() - 29 * 864e5);
    since30.setHours(0, 0, 0, 0);
    const paidAt = { $ifNull: ['$paymentDate', '$createdAt'] };
    const sum = { revenue: { $sum: '$amount' }, count: { $sum: 1 } };

    const [facets] = await Payment.aggregate([
      { $facet: {
        status: [{ $group: { _id: '$status', count: { $sum: 1 } } }],
        total: [{ $match: PAID }, { $group: { _id: null, ...sum } }],
        thisMonth: [{ $match: PAID }, { $match: { $expr: { $gte: [paidAt, monthStart] } } }, { $group: { _id: null, ...sum } }],
        lastMonth: [{ $match: PAID }, { $match: { $expr: { $and: [{ $gte: [paidAt, lastMonthStart] }, { $lt: [paidAt, monthStart] }] } } }, { $group: { _id: null, ...sum } }],
        byPurpose: [{ $match: PAID }, { $group: { _id: { $ifNull: ['$purpose', 'course'] }, ...sum } }],
        byMethod: [{ $match: PAID }, { $group: { _id: '$paymentMethod', ...sum } }],
        byChannel: [{ $match: PAID }, { $group: { _id: { $cond: [{ $eq: ['$gateway.provider', 'itecpay'] }, 'online', 'manual'] }, ...sum } }],
        daily: [
          { $match: PAID },
          { $match: { $expr: { $gte: [paidAt, since30] } } },
          { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: paidAt, timezone: 'Africa/Kigali' } }, ...sum } },
        ],
        onlineNotPaid30: [
          { $match: { 'gateway.provider': 'itecpay', status: { $in: ['failed', 'cancelled'] }, createdAt: { $gte: since30 } } },
          { $count: 'n' },
        ],
        online30: [{ $match: { 'gateway.provider': 'itecpay', createdAt: { $gte: since30 } } }, { $count: 'n' }],
      } },
    ]);
    const needsAttention = await Payment.countDocuments(needsAttentionFilter());

    const one = (arr) => ({ revenue: arr?.[0]?.revenue || 0, count: arr?.[0]?.count || 0 });
    const map = (arr) => Object.fromEntries((arr || []).map((x) => [x._id || 'unknown', { revenue: x.revenue, count: x.count }]));
    const dailyMap = map(facets.daily);
    const daily = [];
    for (let i = 0; i < 30; i++) {
      const d = new Date(since30.getTime() + i * 864e5 + 12 * 3600e3);
      const key = d.toLocaleDateString('en-CA', { timeZone: 'Africa/Kigali' });
      daily.push({ date: key, ...(dailyMap[key] || { revenue: 0, count: 0 }) });
    }

    sendSuccess(res, {
      total: one(facets.total),
      thisMonth: one(facets.thisMonth),
      lastMonth: one(facets.lastMonth),
      byPurpose: map(facets.byPurpose),
      byMethod: map(facets.byMethod),
      byChannel: map(facets.byChannel),
      statusCounts: Object.fromEntries((facets.status || []).map((x) => [x._id, x.count])),
      needsAttention,
      daily,
      online30: { started: facets.online30?.[0]?.n || 0, notPaid: facets.onlineNotPaid30?.[0]?.n || 0 },
      currency: 'RWF',
    });
  } catch (error) {
    console.error('Error in getPaymentOverview:', error);
    sendError(res, 'Failed to load the payments overview', 500, error.message);
  }
};

// Cancel payment
const cancelPayment = async (req, res) => {
  try {
    const { paymentId } = req.params;
    const userId = req.user.id;

    const payment = await Payment.findById(paymentId);
    if (!payment) {
      return sendNotFound(res, 'Payment not found');
    }

    // Check if user owns this payment
    if (payment.userId.toString() !== userId) {
      return sendForbidden(res, 'You do not have permission to cancel this payment');
    }

    // Only allow cancellation of pending payments
    if (payment.status !== 'pending') {
      return sendError(res, 'Only pending payments can be cancelled', 400);
    }

    payment.status = 'cancelled';
    await payment.save();

    // Delete associated enrollment
    await Enrollment.findOneAndDelete({ paymentId: payment._id });
    if (payment.purpose === 'teacher_guide') {
      await require('../models/TeacherAssignment').updateOne({ paymentId: payment._id, source: 'guide_purchase' }, { $set: { isActive: false } });
    }

    sendSuccess(res, {
      paymentId: payment._id,
      status: payment.status
    }, 'Payment cancelled successfully');

  } catch (error) {
    sendError(res, 'Failed to cancel payment', 500, error.message);
  }
};

// Delete payment (admin only)
const deletePayment = async (req, res) => {
  try {
    const { paymentId } = req.params;
    
    console.log('deletePayment called for payment ID:', paymentId);
    console.log('User ID:', req.user?.id);
    console.log('User role:', req.user?.role);

    // Find payment
    const payment = await Payment.findById(paymentId)
      .populate('userId', 'fullName email')
      .populate('courseId', 'title price');
    
    if (!payment) {
      console.log('Payment not found with ID:', paymentId);
      return sendNotFound(res, 'Payment not found');
    }

    console.log('Payment found:', payment.transactionId, 'Status:', payment.status);

    // Store payment info for response before deletion
    const paymentInfo = {
      id: payment._id,
      transactionId: payment.transactionId,
      status: payment.status,
      amount: payment.amount,
      currency: payment.currency,
      user: payment.userId?.fullName || 'Unknown User',
      course: payment.courseId?.title || 'Unknown Course'
    };

    // Delete associated enrollment if it exists
    if (payment.status === 'approved' || payment.status === 'completed') {
      try {
        if (payment.purpose === 'teacher_guide') {
          await require('../models/TeacherAssignment').updateOne({ paymentId: payment._id, source: 'guide_purchase' }, { $set: { isActive: false } });
        }
        const deletedEnrollment = await Enrollment.findOneAndDelete({ paymentId: payment._id });
        if (deletedEnrollment) {
          console.log('Deleted associated enrollment for payment:', payment.transactionId);
        }
      } catch (enrollmentError) {
        console.error('Error deleting enrollment:', enrollmentError);
        // Don't fail the payment deletion if enrollment deletion fails
      }
    }

    // Delete the payment
    await Payment.findByIdAndDelete(paymentId);
    console.log('Payment deleted successfully:', payment.transactionId);

    sendSuccess(res, paymentInfo, 'Payment deleted successfully');

  } catch (error) {
    console.error('Error in deletePayment:', error);
    sendError(res, 'Failed to delete payment', 500, error.message);
  }
};

// Get payment statistics (admin only)
const getPaymentStats = async (req, res) => {
  try {
    console.log('getPaymentStats called by user:', req.user?.id);
    
    const totalPayments = await Payment.countDocuments();
    const pendingPayments = await Payment.countDocuments({ status: 'pending' });
    const adminReviewPayments = await Payment.countDocuments({ status: 'admin_review' });
    const approvedPayments = await Payment.countDocuments({ status: 'approved' });
    const completedPayments = await Payment.countDocuments({ status: 'completed' });
    const failedPayments = await Payment.countDocuments({ status: 'failed' });
    const cancelledPayments = await Payment.countDocuments({ status: 'cancelled' });

    const totalRevenue = await Payment.aggregate([
      { $match: { status: { $in: ['completed', 'approved'] } } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);

    const recentPayments = await Payment.find({ status: { $in: ['completed', 'approved'] } })
      .populate('userId', 'fullName email')
      .populate('courseId', 'title')
      .sort({ updatedAt: -1, paymentDate: -1 })
      .limit(20);

    const responseData = {
      totalPayments,
      pendingPayments,
      adminReviewPayments,
      approvedPayments,
      completedPayments,
      failedPayments,
      cancelledPayments,
      totalRevenue: totalRevenue[0]?.total || 0,
      recentPayments
    };
    
    console.log('getPaymentStats response data:', responseData);
    
    sendSuccess(res, responseData, 'Payment statistics retrieved successfully');

  } catch (error) {
    console.error('Error in getPaymentStats:', error);
    sendError(res, 'Failed to retrieve payment statistics', 500, error.message);
  }
};

module.exports = {
  getPaymentOverview,
  initiatePayment,
  adminInitiatePayment,
  verifyPayment,
  getMyPayments,
  getPaymentById,
  getAllPayments,
  cancelPayment,
  deletePayment,
  getPaymentStats
};