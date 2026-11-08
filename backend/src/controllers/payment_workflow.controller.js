const Payment = require('../models/Payment');
const Enrollment = require('../models/Enrollment');
const Course = require('../models/Course');
const User = require('../models/User');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');
const emailService = require('../services/email.service');
const notificationController = require('./notification.controller');

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

      if (status === 'approved') {
        payment.paymentDate = new Date();
        
        console.log('Checking for existing enrollment for user:', userIdInfo.id, 'course:', courseIdInfo.id);
        
        // Check if enrollment already exists for this user and course
        // Include unenrolled/suspended records: a learner may buy a course again
        // after leaving it, and (userId, courseId) is unique.
        const existingEnrollment = await Enrollment.findOne({
          userId: userIdInfo.id,
          courseId: courseIdInfo.id,
          status: Enrollment.ANY_STATUS
        });
        
        if (!existingEnrollment) {
          console.log('Creating new enrollment for user:', userIdInfo.id, 'course:', courseIdInfo.id);
          
          // Create enrollment for the user
          await Enrollment.create({
            userId: userIdInfo.id,
            courseId: courseIdInfo.id,
            completionStatus: 'in-progress',
            paymentId: payment._id
          });
          
          console.log('Enrollment created successfully');
        } else if (existingEnrollment.status === 'unenrolled') {
          // Learner bought the course again after leaving it: reactivate the
          // same record so their earlier progress comes back.
          existingEnrollment.setStatus('active', {
            changedBy: req.user?.id || null,
            reason: 'Re-enrolled after payment approval'
          });
          existingEnrollment.unenrolledAt = null;
          existingEnrollment.paymentId = payment._id;
          if (existingEnrollment.accessExpirationDate && new Date() > existingEnrollment.accessExpirationDate) {
            // Match new paid enrollments created above, which carry no expiry
            existingEnrollment.accessExpirationDate = null;
          }
          await existingEnrollment.save();
          await Course.findByIdAndUpdate(courseIdInfo.id, { $inc: { enrollmentCount: 1 } });
          console.log('Reactivated unenrolled enrollment after payment approval');
        } else {
          console.log('Enrollment already exists for user:', userIdInfo.id, 'course:', courseIdInfo.id);

          // Update existing enrollment with the new payment ID if it doesn't have one
          if (!existingEnrollment.paymentId) {
            existingEnrollment.paymentId = payment._id;
            await existingEnrollment.save();
            console.log('Updated existing enrollment with payment ID');
          }
        }

        // Send payment notification to user
        try {
          const NotificationController = notificationController.NotificationController;
          await NotificationController.createPaymentNotification(userIdInfo.id, payment.amount, courseIdInfo.id);
        } catch (notificationError) {
          console.error('Error creating payment notification:', notificationError);
        }
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
const getAllPayments = async (req, res) => {
  try {
    const { status, courseId, userId, page = 1, limit = 20 } = req.query;
    
    // Ensure limit doesn't exceed 100 for performance
    const finalLimit = Math.min(parseInt(limit) || 20, 100);
    
    console.log('getAllPayments called with params:', { status, courseId, userId, page, limit, finalLimit });
    console.log('User ID:', req.user?.id);
    console.log('User role:', req.user?.role);

    const filter = {};
    if (status) filter.status = status;
    if (courseId) filter.courseId = courseId;
    if (userId) filter.userId = userId;

    const payments = await Payment.find(filter)
      .populate('userId', 'fullName email')
      .populate('courseId', 'title price')
      .populate('adminApproval.approvedBy', 'fullName')
      .limit(finalLimit)
      .skip((page - 1) * finalLimit)
      .sort({ createdAt: -1 });

    const total = await Payment.countDocuments(filter);
    
    const responseData = {
      payments,
      totalPages: Math.ceil(total / finalLimit),
      currentPage: Number(page),
      total
    };
    
    console.log('getAllPayments response structure:', {
      paymentsLength: payments.length,
      paymentsType: typeof payments,
      isArray: Array.isArray(payments),
      paymentsSample: payments.length > 0 ? payments[0] : 'empty array',
      totalPages: responseData.totalPages,
      currentPage: responseData.currentPage,
      total: responseData.total,
      responseDataPaymentsType: typeof responseData.payments,
      responseDataPaymentsIsArray: Array.isArray(responseData.payments)
    });

    console.log('Sending response data:', JSON.stringify(responseData, null, 2));

    sendSuccess(res, responseData, 'Payments retrieved successfully');

  } catch (error) {
    console.error('Error in getAllPayments:', error);
    sendError(res, 'Failed to retrieve payments', 500, error.message);
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