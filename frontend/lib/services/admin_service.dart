
import 'dart:convert';

import './infrastructure/api_client.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/enrollment.dart';
import '../models/student_performance.dart';

/// Service for admin-related API operations using the new professional architecture
class AdminService {
  final ApiClient _apiClient;

  AdminService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Get dashboard statistics
  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      // Fetch all required data in parallel
      final futures = [
        _getCourseStats(),
        _getPaymentStats(),
        _getUserStats(),
        _getExamStats(),
      ];
      
      final results = await Future.wait(futures);
      
      final courseStats = results[0] as CourseStats;
      final paymentStats = results[1] as PaymentStats;
      final userStats = results[2] as UserStats;
      final examStats = results[3] as Map<String, dynamic>;
      
      return AdminDashboardStats(
        totalCourses: courseStats.totalCourses,
        activeStudents: userStats.totalStudents,
        totalRevenue: paymentStats.totalRevenue,
        totalFinalExams: _toInt(examStats['totalFinalExamsDone']),
        recentActivity: _generateRecentActivity(courseStats, paymentStats, examStats),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch dashboard statistics: $e');
    }
  }

  /// Get exam statistics
  Future<Map<String, dynamic>> _getExamStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/exam-stats');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return data;
    } catch (e) {
      // If endpoint doesn't exist, return default
      return {'totalFinalExamsDone': 0};
    }
  }

  /// Get course statistics
  Future<CourseStats> _getCourseStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/course-stats');
      response.validateStatus();
      
      // Parse the response directly since data is a List
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'];
      
      if (data is List) {
        final courses = data.cast<Map<String, dynamic>>();
        
        // Calculate total courses (all courses, not just published)
        final totalCourses = courses.length;
        
        // Calculate published courses
        final publishedCourses = courses.where((course) => 
          course['isPublished'] == true).length;
        
        return CourseStats(
          totalCourses: totalCourses,
          publishedCourses: publishedCourses,
          courses: courses
        );
      } else {
        throw ApiException('Invalid response format: expected List but got ${data.runtimeType}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      // Return default values if API fails
      return CourseStats(totalCourses: 0, publishedCourses: 0, courses: []);
    }
  }

  /// Get payment statistics
  Future<PaymentStats> _getPaymentStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/payment-stats');
      response.validateStatus();
      
      // Parse the response directly
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return PaymentStats(
        totalRevenue: _toDouble(data['totalRevenue']),
        totalPayments: _toInt(data['totalPayments']),
        recentPayments: data['recentPayments'] is List ? data['recentPayments'] as List : [],
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      // Return default values if API fails
      return PaymentStats(totalRevenue: 0, totalPayments: 0, recentPayments: []);
    }
  }

  /// Get user statistics
  Future<UserStats> _getUserStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/students?page=1&limit=1&source=firebase');
      response.validateStatus();
      
      // Parse the response directly
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return UserStats(
        totalStudents: _toInt(data['total']),
        source: data['source'] as String? ?? 'unknown',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      // Return default values if API fails
      return UserStats(totalStudents: 0, source: 'fallback');
    }
  }

  /// Get students with pagination and search
  Future<StudentListResponse> getStudents({int page = 1, int limit = 10, String? search, String? source}) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (source != null) 'source': source,
      };
      
      final response = await _apiClient.get('${ApiConfig.admin}/students', queryParams: queryParams);
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      final students = (data['students'] as List)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return StudentListResponse(
        students: students,
        totalPages: _toInt(data['totalPages']) > 0 ? _toInt(data['totalPages']) : 1,
        currentPage: _toInt(data['currentPage']) > 0 ? _toInt(data['currentPage']) : 1,
        total: _toInt(data['total']),
        source: data['source'] as String? ?? 'unknown',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch students: $e');
    }
  }

  /// Get admins with pagination and search
  Future<AdminListResponse> getAdmins({int page = 1, int limit = 10, String? search, String? source}) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (source != null) 'source': source,
      };
      
      final response = await _apiClient.get('${ApiConfig.admin}/admins', queryParams: queryParams);
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      final admins = (data['admins'] as List)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return AdminListResponse(
        admins: admins,
        totalPages: _toInt(data['totalPages']) > 0 ? _toInt(data['totalPages']) : 1,
        currentPage: _toInt(data['currentPage']) > 0 ? _toInt(data['currentPage']) : 1,
        total: _toInt(data['total']),
        source: data['source'] as String? ?? 'unknown',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch admins: $e');
    }
  }

  /// Update student information (admin)
  Future<User> updateStudent(
    String studentId, {
    String? fullName,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (role != null) body['role'] = role;
      if (isActive != null) body['isActive'] = isActive;

      final response = await _apiClient.put(
        '${ApiConfig.admin}/students/$studentId',
        body: body,
      );
      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      return User.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update student: $e');
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String role) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.admin}/users/$userId/role',
        body: {'role': role},
      );
      response.validateStatus();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update user role: $e');
    }
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    } else if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    } else if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is Map<String, dynamic>) {
      // Handle case where date is stored as an object (e.g., Firestore timestamp)
      try {
        // Check if it's a Firestore Timestamp-like object with seconds and nanoseconds
        if (dateValue.containsKey('seconds') && dateValue.containsKey('nanoseconds')) {
          int seconds = dateValue['seconds'] as int? ?? 0;
          int nanoseconds = dateValue['nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds ~/ 1000000));
        } else if (dateValue.containsKey('_seconds')) {
          // Alternative format with _seconds
          int seconds = dateValue['_seconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } catch (e) {
        // If conversion fails, return current time
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  /// Get detailed student information including enrollments
  Future<StudentDetail> getStudentDetail(String studentId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/students/$studentId/detail');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final enrollments = (data['enrollments'] as List)
          .map((item) => Enrollment.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return StudentDetail(
        user: user,
        enrollments: enrollments,
        examResults: data['examResults'] as List? ?? [],
        payments: data['payments'] as List? ?? [],
        totalEnrollments: data['totalEnrollments'] as int? ?? 0,
        completedCourses: data['completedCourses'] as int? ?? 0,
        inProgressCourses: data['inProgressCourses'] as int? ?? 0,
        totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
        lastActive: data['lastActive'] != null 
            ? _parseDateTime(data['lastActive'])
            : null,
        timeSpentInApp: data['timeSpentInApp'] != null 
            ? Duration(seconds: data['timeSpentInApp'] as int? ?? 0)
            : null,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch student details: $e');
    }
  }

  /// Get student analytics data
  Future<StudentAnalytics> getStudentAnalytics() async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/analytics/students');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return StudentAnalytics(
        totalStudents: data['totalStudents'] as int? ?? 0,
        activeStudents: data['activeStudents'] as int? ?? 0,
        inactiveStudents: data['inactiveStudents'] as int? ?? 0,
        newStudentsThisMonth: data['newStudentsThisMonth'] as int? ?? 0,
        averageEnrollmentsPerStudent: (data['averageEnrollmentsPerStudent'] as num?)?.toDouble() ?? 0.0,
        topPerformingStudents: (data['topPerformingStudents'] as List)
            .map((item) => TopStudent.fromJson(item as Map<String, dynamic>))
            .toList(),
        enrollmentTrends: (data['enrollmentTrends'] as List)
            .map((item) => EnrollmentTrend.fromJson(item as Map<String, dynamic>))
            .toList(),
        studentActivityStats: StudentActivityStats.fromJson(
            data['studentActivityStats'] as Map<String, dynamic>),
        recentlyUnenrolledStudents: (data['recentlyUnenrolledStudents'] as List?)
            ?.map((item) => UnenrolledStudent.fromJson(item as Map<String, dynamic>))
            .toList() ?? [],
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch student analytics: $e');
    }
  }

  /// Get analytics for a specific course
  Future<CourseAnalytics> getCourseAnalytics(String courseId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/analytics/course/$courseId');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return CourseAnalytics.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch course analytics: $e');
    }
  }

  /// Get one student's chapter/lesson-level progress breakdown for a course
  Future<DetailedStudentPerformance> getStudentCourseProgress(
    String courseId,
    String studentId,
  ) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.admin}/courses/$courseId/students/$studentId/performance',
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      return DetailedStudentPerformance.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch student course progress: $e');
    }
  }

  /// Push delivery report: which push notifications reached devices and which
  /// did not. Pushes fail silently by design on the server, so this endpoint is
  /// the only place a failed delivery is visible.
  Future<PushReport> getPushReport({
    int days = 7,
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.admin}/push-report',
        queryParams: {
          'days': days,
          'status': status,
          if (search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      return PushReport.fromJson(jsonBody['data'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch push delivery report: $e');
    }
  }

  /// Get admin notifications
  Future<List<AdminNotification>> getNotifications() async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/notifications');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      final notifications = (data['notifications'] as List)
          .map((item) => AdminNotification.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return notifications;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch notifications: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await _apiClient.put('${ApiConfig.notifications}/read-all', body: {});
      response.validateStatus();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to mark all as read: $e');
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final response = await _apiClient.delete(ApiConfig.notifications);
      response.validateStatus();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete all notifications: $e');
    }
  }

  /// Delete a student and all related data
  Future<Map<String, dynamic>> deleteStudent(String studentId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.admin}/students/$studentId');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonBody['data'] as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete student: $e');
    }
  }

  /// Manual sync all users from Firebase to backend
  Future<Map<String, dynamic>> manualSyncUsers() async {
    try {
      final response = await _apiClient.post('${ApiConfig.admin}/manual-sync-users');
      response.validateStatus();
      
      // Parse the response directly
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Manual sync failed: $e');
    }
  }

  /// Unenroll a student from a specific course
  Future<void> unenrollStudent(String courseId, String studentId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.admin}/courses/$courseId/enrollments/$studentId');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] != true) {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to unenroll student');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to unenroll student: $e');
    }
  }

  /// Update enrollment permissions (admin)
  /// Suspend (`suspended`) or reinstate (`active`) a learner's enrollment.
  /// Progress is kept either way.
  Future<void> updateEnrollmentStatus(String enrollmentId, String status, {String? reason}) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.enrollments}/$enrollmentId/status',
        body: <String, dynamic>{
          'status': status,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] != true) {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to update enrollment status');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update enrollment status: $e');
    }
  }

  Future<void> updateEnrollmentPermissions(
    String enrollmentId, {
    required bool canAccessLiveSessions,
    required bool canAccessChapters,
  }) async {
    try {
      final body = <String, dynamic>{
        'canAccessLiveSessions': canAccessLiveSessions,
        'canAccessChapters': canAccessChapters,
      };

      final response = await _apiClient.put(
        '${ApiConfig.admin}/enrollments/$enrollmentId/permissions',
        body: body,
      );
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] != true) {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to update enrollment permissions');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update enrollment permissions: $e');
    }
  }

  /// Generate recent activity based on fetched data
  List<ActivityItem> _generateRecentActivity(CourseStats courseStats, PaymentStats paymentStats, Map<String, dynamic> examStats) {
    final List<ActivityItem> activity = [];
    
    // Add recent course activities
    for (var i = 0; i < courseStats.courses.length && i < 5; i++) {
      final course = courseStats.courses[i];
      final title = course['title'] ?? 'New Course';
      final isPublished = course['isPublished'] ?? false;
      final createdAt = _parseDateTime(course['createdAt']);
      
      activity.add(ActivityItem(
        icon: 'school',
        title: isPublished ? 'Course Published' : 'Course Created',
        subtitle: title,
        time: _formatDate(course['createdAt']),
        timestamp: createdAt,
      ));
    }
    
    // Add recent payment activities
    final recentPayments = paymentStats.recentPayments;
    for (var i = 0; i < recentPayments.length && i < 5; i++) {
      final payment = recentPayments[i];
      final amount = payment['amount'] ?? 0;
      final studentName = (payment['userId'] is Map) ? payment['userId']['fullName'] : 'A student';
      final courseName = (payment['courseId'] is Map) ? payment['courseId']['title'] : 'a course';
      final paymentDate = _parseDateTime(payment['paymentDate'] ?? payment['createdAt']);
      
      activity.add(ActivityItem(
        icon: 'payment',
        title: 'Enrollment: RWF $amount',
        subtitle: '$studentName enrolled in $courseName',
        time: _formatDate(payment['paymentDate'] ?? payment['createdAt']),
        timestamp: paymentDate,
      ));
    }

    // Add recent exam activities
    final recentResults = examStats['recentResults'] as List?;
    if (recentResults != null) {
      for (var i = 0; i < recentResults.length && i < 5; i++) {
        final result = recentResults[i];
        final studentName = (result['userId'] is Map) ? result['userId']['fullName'] : 'A student';
        final examTitle = (result['examId'] is Map) ? result['examId']['title'] : 'an exam';
        final score = result['score'] ?? 0;
        final totalPoints = result['totalPoints'] ?? 0;
        final submittedAt = _parseDateTime(result['submittedAt']);

        activity.add(ActivityItem(
          icon: 'quiz',
          title: 'Exam Completed',
          subtitle: '$studentName scored $score/$totalPoints in $examTitle',
          time: _formatDate(result['submittedAt']),
          timestamp: submittedAt,
        ));
      }
    }
    
    // Sort activity by timestamp (newest first)
    activity.sort((a, b) => (b.timestamp ?? DateTime(2000)).compareTo(a.timestamp ?? DateTime(2000)));
    
    // Add default activities if no real data
    if (activity.isEmpty) {
      activity.addAll([
        ActivityItem(
          icon: 'school',
          title: 'Platform Ready',
          subtitle: 'Your coaching platform is set up',
          time: 'Just now',
          timestamp: DateTime.now(),
        ),
        ActivityItem(
          icon: 'people',
          title: 'Welcome Admin',
          subtitle: 'Start managing your platform',
          time: 'Just now',
          timestamp: DateTime.now(),
        ),
      ]);
    }
    
    // Return most recent items first
    return activity.take(8).toList();
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Recently';
    
    final date = _parseDateTime(dateValue);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Get user device information and enrolled courses
  Future<UserDeviceInfo> getUserDeviceInfo(String userId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/students/$userId/device-info');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final enrolledCourses = (data['enrolledCourses'] as List)
          .map((item) => Enrollment.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return UserDeviceInfo(
        user: user,
        enrolledCourses: enrolledCourses,
        totalEnrollments: data['totalEnrollments'] as int? ?? 0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch user device info: $e');
    }
  }
  
  /// Reset user device binding
  Future<Map<String, dynamic>> resetUserDevice(String userId, {String? deviceId}) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.admin}/students/$userId/device-reset',
        body: deviceId != null ? {'deviceId': deviceId} : {},
      );
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonBody['data'] as Map<String, dynamic>;
    } catch (e) {
      throw 'Failed to reset user device: $e';
    }
  }

  /// Reset student password (admin only)
  Future<void> resetStudentPassword(String studentId, String newPassword) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.admin}/students/$studentId/reset-password',
        body: {'newPassword': newPassword},
      );
      response.validateStatus();
    } catch (e) {
      throw 'Failed to reset student password: $e';
    }
  }

  /// Toggle student account status (enable/disable)
  Future<Map<String, dynamic>> toggleStudentStatus(String userId, bool disabled) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.admin}/students/$userId/toggle-status',
        body: {'disabled': disabled},
      );
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonBody['data'] as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to toggle student status: $e');
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _apiClient.dispose();
  }
}

class StudentListResponse {
  final List<User> students;
  final int totalPages;
  final int currentPage;
  final int total;
  final String source;

  StudentListResponse({
    required this.students,
    required this.totalPages,
    required this.currentPage,
    required this.total,
    required this.source,
  });
}

class AdminListResponse {
  final List<User> admins;
  final int totalPages;
  final int currentPage;
  final int total;
  final String source;

  AdminListResponse({
    required this.admins,
    required this.totalPages,
    required this.currentPage,
    required this.total,
    required this.source,
  });
}

/// Data models for admin statistics
class AdminDashboardStats {
  final int totalCourses;
  final int activeStudents;
  final double totalRevenue;
  final int totalFinalExams;
  final List<ActivityItem> recentActivity;

  AdminDashboardStats({
    required this.totalCourses,
    required this.activeStudents,
    required this.totalRevenue,
    required this.totalFinalExams,
    required this.recentActivity,
  });

  factory AdminDashboardStats.empty() {
    return AdminDashboardStats(
      totalCourses: 0,
      activeStudents: 0,
      totalRevenue: 0.0,
      totalFinalExams: 0,
      recentActivity: [],
    );
  }
}

class CourseStats {
  final int totalCourses;
  final int publishedCourses;
  final List<Map<String, dynamic>> courses;

  CourseStats({
    required this.totalCourses,
    required this.publishedCourses,
    required this.courses,
  });
}

class PaymentStats {
  final double totalRevenue;
  final int totalPayments;
  final List<dynamic> recentPayments;

  PaymentStats({
    required this.totalRevenue,
    required this.totalPayments,
    required this.recentPayments,
  });
}

class UserStats {
  final int totalStudents;
  final String source;

  UserStats({
    required this.totalStudents,
    required this.source,
  });
}

class ActivityItem {
  final String icon;
  final String title;
  final String subtitle;
  final String time;
  final DateTime? timestamp;

  ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    this.timestamp,
  });
}

/// Data models for student management
class StudentDetail {
  final User user;
  final List<Enrollment> enrollments;
  final List<dynamic> examResults;
  final List<dynamic> payments;
  final int totalEnrollments;
  final int completedCourses;
  final int inProgressCourses;
  final double totalSpent;
  final DateTime? lastActive;
  final Duration? timeSpentInApp;

  StudentDetail({
    required this.user,
    required this.enrollments,
    this.examResults = const [],
    this.payments = const [],
    required this.totalEnrollments,
    required this.completedCourses,
    required this.inProgressCourses,
    required this.totalSpent,
    this.lastActive,
    this.timeSpentInApp,
  });
}

class StudentAnalytics {
  final int totalStudents;
  final int activeStudents;
  final int inactiveStudents;
  final int newStudentsThisMonth;
  final double averageEnrollmentsPerStudent;
  final List<TopStudent> topPerformingStudents;
  final List<EnrollmentTrend> enrollmentTrends;
  final StudentActivityStats studentActivityStats;
  final List<UnenrolledStudent> recentlyUnenrolledStudents;

  StudentAnalytics({
    required this.totalStudents,
    required this.activeStudents,
    required this.inactiveStudents,
    required this.newStudentsThisMonth,
    required this.averageEnrollmentsPerStudent,
    required this.topPerformingStudents,
    required this.enrollmentTrends,
    required this.studentActivityStats,
    this.recentlyUnenrolledStudents = const [],
  });
}

class UnenrolledStudent {
  final String id;
  final String name;
  final String email;
  final String courseTitle;
  final String unenrollmentReason;
  final DateTime unenrollmentDate;
  final DateTime accessExpirationDate;

  UnenrolledStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.courseTitle,
    required this.unenrollmentReason,
    required this.unenrollmentDate,
    required this.accessExpirationDate,
  });

  factory UnenrolledStudent.fromJson(Map<String, dynamic> json) {
    return UnenrolledStudent(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      courseTitle: json['courseTitle'] as String,
      unenrollmentReason: json['unenrollmentReason'] as String,
      unenrollmentDate: AdminService._parseDateTime(json['unenrollmentDate']),
      accessExpirationDate: AdminService._parseDateTime(json['accessExpirationDate']),
    );
  }
}

class TopStudent {
  final String id;
  final String name;
  final String email;
  final int totalEnrollments;
  final int completedCourses;
  final double averageProgress;
  final double totalSpent;

  TopStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.totalEnrollments,
    required this.completedCourses,
    required this.averageProgress,
    required this.totalSpent,
  });

  factory TopStudent.fromJson(Map<String, dynamic> json) {
    return TopStudent(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      totalEnrollments: json['totalEnrollments'] as int,
      completedCourses: json['completedCourses'] as int,
      averageProgress: (json['averageProgress'] as num).toDouble(),
      totalSpent: (json['totalSpent'] as num).toDouble(),
    );
  }
}

class EnrollmentTrend {
  final String date;
  final int enrollments;
  final int completions;

  EnrollmentTrend({
    required this.date,
    required this.enrollments,
    required this.completions,
  });

  factory EnrollmentTrend.fromJson(Map<String, dynamic> json) {
    return EnrollmentTrend(
      date: json['date'] as String,
      enrollments: json['enrollments'] as int,
      completions: json['completions'] as int,
    );
  }
}

class StudentActivityStats {
  final int dailyActiveStudents;
  final int weeklyActiveStudents;
  final int monthlyActiveStudents;
  final double avgSessionDuration;
  final int totalStudyHours;

  StudentActivityStats({
    required this.dailyActiveStudents,
    required this.weeklyActiveStudents,
    required this.monthlyActiveStudents,
    required this.avgSessionDuration,
    required this.totalStudyHours,
  });

  factory StudentActivityStats.fromJson(Map<String, dynamic> json) {
    return StudentActivityStats(
      dailyActiveStudents: json['dailyActiveStudents'] as int,
      weeklyActiveStudents: json['weeklyActiveStudents'] as int,
      monthlyActiveStudents: json['monthlyActiveStudents'] as int,
      avgSessionDuration: (json['avgSessionDuration'] as num).toDouble(),
      totalStudyHours: json['totalStudyHours'] as int,
    );
  }
}

/// Model for user device information
class UserDeviceInfo {
  final User user;
  final List<Enrollment> enrolledCourses;
  final int totalEnrollments;

  UserDeviceInfo({
    required this.user,
    required this.enrolledCourses,
    required this.totalEnrollments,
  });

  factory UserDeviceInfo.fromJson(Map<String, dynamic> json) {
    return UserDeviceInfo(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      enrolledCourses: (json['enrolledCourses'] as List)
          .map((item) => Enrollment.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalEnrollments: json['totalEnrollments'] as int? ?? 0,
    );
  }
}

class CourseAnalytics {
  final Map<String, dynamic> course;
  final CourseStatsDetail stats;
  final List<CourseStudentPerformance> students;
  final List<CourseReview> reviews;

  CourseAnalytics({
    required this.course,
    required this.stats,
    required this.students,
    required this.reviews,
  });

  factory CourseAnalytics.fromJson(Map<String, dynamic> json) {
    return CourseAnalytics(
      course: json['course'] as Map<String, dynamic>,
      stats: CourseStatsDetail.fromJson(json['stats'] as Map<String, dynamic>),
      students: (json['students'] as List)
          .map((item) => CourseStudentPerformance.fromJson(item as Map<String, dynamic>))
          .toList(),
      reviews: json['reviews'] != null 
          ? (json['reviews'] as List).map((item) => CourseReview.fromJson(item as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class CourseStatsDetail {
  final int totalStudents;
  final int activeStudents;
  final int completedCount;
  final double completionRate;
  final double averageProgress;
  final int newStudentsThisMonth;
  final double averageRating;
  final int totalRatings;

  CourseStatsDetail({
    required this.totalStudents,
    required this.activeStudents,
    required this.completedCount,
    required this.completionRate,
    required this.averageProgress,
    required this.newStudentsThisMonth,
    required this.averageRating,
    required this.totalRatings,
  });

  factory CourseStatsDetail.fromJson(Map<String, dynamic> json) {
    return CourseStatsDetail(
      totalStudents: json['totalStudents'] as int? ?? 0,
      activeStudents: json['activeStudents'] as int? ?? 0,
      completedCount: json['completedCount'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      averageProgress: (json['averageProgress'] as num?)?.toDouble() ?? 0.0,
      newStudentsThisMonth: json['newStudentsThisMonth'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] as int? ?? 0,
    );
  }
}

class CourseReview {
  final String userName;
  final double? rating;
  final String? feedback;
  final DateTime date;

  CourseReview({
    required this.userName,
    this.rating,
    this.feedback,
    required this.date,
  });

  factory CourseReview.fromJson(Map<String, dynamic> json) {
    return CourseReview(
      userName: json['userName'] as String? ?? 'Unknown Student',
      rating: (json['rating'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
    );
  }
}

class CourseStudentPerformance {
  final String id;
  final String name;
  final String email;
  final DateTime enrollmentDate;
  final double progress;
  final String completionStatus;
  final DateTime? lastAccessed;
  final double? rating;
  final String? feedback;
  final DateTime? accessExpirationDate;
  final String? timeRemaining;
  final String status;
  final bool isExpired;

  CourseStudentPerformance({
    required this.id,
    required this.name,
    required this.email,
    required this.enrollmentDate,
    required this.progress,
    required this.completionStatus,
    this.lastAccessed,
    this.rating,
    this.feedback,
    this.accessExpirationDate,
    this.timeRemaining,
    required this.status,
    required this.isExpired,
  });

  factory CourseStudentPerformance.fromJson(Map<String, dynamic> json) {
    return CourseStudentPerformance(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      enrollmentDate: DateTime.parse(json['enrollmentDate'] as String),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completionStatus: json['completionStatus'] as String,
      lastAccessed: json['lastAccessed'] != null ? DateTime.parse(json['lastAccessed'] as String) : null,
      rating: (json['rating'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      accessExpirationDate: json['accessExpirationDate'] != null ? DateTime.parse(json['accessExpirationDate'] as String) : null,
      timeRemaining: json['timeRemaining'] as String?,
      status: json['status'] as String? ?? 'active',
      isExpired: json['isExpired'] as bool? ?? false,
    );
  }
}

class AdminNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isVirtual;
  final String severity;

  AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.data,
    required this.timestamp,
    required this.isVirtual,
    this.severity = 'info',
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isVirtual: json['isVirtual'] as bool? ?? false,
      severity: json['severity'] as String? ?? 'info',
    );
  }
}

/// One push-notification attempt, as recorded server-side.
class PushLogEntry {
  final String id;
  final String? userName;
  final String? userEmail;
  final String title;
  final String message;

  /// 'sent' (FCM accepted it), 'failed' (FCM rejected it) or 'skipped'
  /// (it never left the server — no token, or the daily cap).
  final String status;

  /// FCM's id for the accepted message; only present when [status] is 'sent'.
  final String? messageId;
  final String? errorCode;
  final String? errorMessage;

  /// Plain-language reason, supplied by the backend for known error codes.
  final String? explanation;
  final int attempts;
  final String? tokenTail;
  final String tokenSource;
  final DateTime timestamp;

  PushLogEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.status,
    required this.timestamp,
    this.userName,
    this.userEmail,
    this.messageId,
    this.errorCode,
    this.errorMessage,
    this.explanation,
    this.attempts = 0,
    this.tokenTail,
    this.tokenSource = 'none',
  });

  bool get isSent => status == 'sent';
  bool get isFailed => status == 'failed';
  bool get isSkipped => status == 'skipped';

  factory PushLogEntry.fromJson(Map<String, dynamic> json) {
    return PushLogEntry(
      id: json['id']?.toString() ?? '',
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'failed',
      messageId: json['messageId'] as String?,
      errorCode: json['errorCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
      explanation: json['explanation'] as String?,
      attempts: AdminService._toInt(json['attempts']),
      tokenTail: json['tokenTail'] as String?,
      tokenSource: json['tokenSource'] as String? ?? 'none',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String).toLocal()
          : DateTime.now(),
    );
  }
}

/// Attempt totals for the selected window.
class PushReportSummary {
  final int total;
  final int sent;
  final int failed;
  final int skipped;
  final double deliveryRate;

  PushReportSummary({
    required this.total,
    required this.sent,
    required this.failed,
    required this.skipped,
    required this.deliveryRate,
  });

  factory PushReportSummary.fromJson(Map<String, dynamic> json) {
    return PushReportSummary(
      total: AdminService._toInt(json['total']),
      sent: AdminService._toInt(json['sent']),
      failed: AdminService._toInt(json['failed']),
      skipped: AdminService._toInt(json['skipped']),
      deliveryRate: AdminService._toDouble(json['deliveryRate']),
    );
  }
}

/// A single failure reason and how often it occurred.
class PushFailureReason {
  final String code;
  final String status;
  final int count;
  final String? explanation;

  PushFailureReason({
    required this.code,
    required this.status,
    required this.count,
    this.explanation,
  });

  factory PushFailureReason.fromJson(Map<String, dynamic> json) {
    return PushFailureReason(
      code: json['code'] as String? ?? 'unknown-error',
      status: json['status'] as String? ?? 'failed',
      count: AdminService._toInt(json['count']),
      explanation: json['explanation'] as String?,
    );
  }
}

/// Per-day totals, used for the trend bars.
class PushDailyPoint {
  final String date;
  final int sent;
  final int failed;
  final int skipped;

  PushDailyPoint({
    required this.date,
    required this.sent,
    required this.failed,
    required this.skipped,
  });

  int get total => sent + failed + skipped;

  factory PushDailyPoint.fromJson(Map<String, dynamic> json) {
    return PushDailyPoint(
      date: json['date'] as String? ?? '',
      sent: AdminService._toInt(json['sent']),
      failed: AdminService._toInt(json['failed']),
      skipped: AdminService._toInt(json['skipped']),
    );
  }
}

class PushReport {
  final PushReportSummary summary;
  final List<PushFailureReason> breakdown;
  final List<PushDailyPoint> daily;
  final List<PushLogEntry> logs;
  final int page;
  final int totalPages;
  final int totalLogs;
  final bool hasMore;

  PushReport({
    required this.summary,
    required this.breakdown,
    required this.daily,
    required this.logs,
    required this.page,
    required this.totalPages,
    required this.totalLogs,
    required this.hasMore,
  });

  factory PushReport.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return PushReport(
      summary: PushReportSummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? const {}),
      breakdown: (json['breakdown'] as List? ?? [])
          .map((e) => PushFailureReason.fromJson(e as Map<String, dynamic>))
          .toList(),
      daily: (json['daily'] as List? ?? [])
          .map((e) => PushDailyPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      logs: (json['logs'] as List? ?? [])
          .map((e) => PushLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: AdminService._toInt(pagination['page']),
      totalPages: AdminService._toInt(pagination['totalPages']),
      totalLogs: AdminService._toInt(pagination['total']),
      hasMore: pagination['hasMore'] as bool? ?? false,
    );
  }
}
