import 'user.dart';
import 'course.dart';

/// Learner-facing enrollment state for a single course.
class EnrollmentStatusInfo {
  /// One of `none`, `active`, `unenrolled`, `suspended`.
  final String status;
  final bool canReenrollWithoutPayment;
  final double progress;

  const EnrollmentStatusInfo({
    required this.status,
    this.canReenrollWithoutPayment = false,
    this.progress = 0,
  });

  bool get isActive => status == 'active';
  bool get isUnenrolled => status == 'unenrolled';
  bool get isSuspended => status == 'suspended';

  factory EnrollmentStatusInfo.fromJson(Map<String, dynamic> json) {
    return EnrollmentStatusInfo(
      status: json['status']?.toString() ?? 'none',
      canReenrollWithoutPayment: json['canReenrollWithoutPayment'] == true,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Enrollment {
  final String id;
  final String userId;
  final String courseId;
  final DateTime enrollmentDate;
  final String completionStatus;
  final double progress;
  final List<String> completedLessons;
  final bool certificateEligible;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? accessExpirationDate;
  final double? rating;
  final String? feedback;
  final bool canAccessLiveSessions;
  final bool canAccessChapters;
  /// active | unenrolled | suspended
  final String status;
  final DateTime? unenrolledAt;
  final DateTime? suspendedAt;
  
  // Populated fields (from backend populate)
  final User? user;
  final Course? course;

  Enrollment({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.enrollmentDate,
    required this.completionStatus,
    required this.progress,
    required this.completedLessons,
    required this.certificateEligible,
    this.paymentId,
    required this.createdAt,
    required this.updatedAt,
    this.accessExpirationDate,
    this.rating,
    this.feedback,
    this.canAccessLiveSessions = true,
    this.canAccessChapters = true,
    this.status = 'active',
    this.unenrolledAt,
    this.suspendedAt,
    this.user,
    this.course,
  });

  static String? _getStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      // If it's a Map, try to convert to string representation
      return value.toString();
    }
    // For other types, convert to string
    return value.toString();
  }

  static Course? _parseCourseData(dynamic courseData) {
    if (courseData == null) return null;
    
    try {
      if (courseData is Map<String, dynamic>) {
        return Course.fromJson(courseData);
      } else {
        // If courseData is not a Map, create a minimal Course object with the available data
        return Course(
          id: '',
          title: _getStringValue(courseData) ?? 'Unknown Course',
          description: '',
          price: 0.0,
          duration: 0,
          level: 'Beginner',
          isPublished: false,
          createdBy: User(id: '', fullName: 'Unknown', email: '', role: 'user', createdAt: DateTime.now()),
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      // If parsing fails, return a default course
      return Course(
        id: '',
        title: 'Unknown Course',
        description: '',
        price: 0.0,
        duration: 0,
        level: 'Beginner',
        isPublished: false,
        createdBy: User(id: '', fullName: 'Unknown', email: '', role: 'user', createdAt: DateTime.now()),
        createdAt: DateTime.now(),
      );
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

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    // Check if courseId is populated as an object
    dynamic courseData = json['course'];
    dynamic courseIdData = json['courseId'];
    String courseIdStr = '';

    if (courseIdData is Map<String, dynamic>) {
      // It's populated, so move it to courseData and extract the ID
      courseData ??= courseIdData;
      courseIdStr = _getStringValue(courseIdData['_id']) ?? 
                    _getStringValue(courseIdData['id']) ?? '';
    } else {
      courseIdStr = _getStringValue(courseIdData) ?? '';
    }

    return Enrollment(
      id: _getStringValue(json['_id']) ?? _getStringValue(json['id']) ?? '',
      userId: _getStringValue(json['userId']) ?? '',
      courseId: courseIdStr,
      enrollmentDate: _parseDateTime(json['enrollmentDate']),
      completionStatus: _getStringValue(json['completionStatus']) ?? 'enrolled',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completedLessons: json['completedLessons'] is List
          ? (json['completedLessons'] as List).map((e) => _getStringValue(e)?.toString() ?? '').toList()
          : [],
      certificateEligible: json['certificateEligible'] as bool? ?? false,
      paymentId: _getStringValue(json['paymentId']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      accessExpirationDate: json['accessExpirationDate'] != null 
          ? _parseDateTime(json['accessExpirationDate'])
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      canAccessLiveSessions: json['canAccessLiveSessions'] != false,
      canAccessChapters: json['canAccessChapters'] != false,
      status: json['status']?.toString() ?? 'active',
      unenrolledAt: json['unenrolledAt'] != null ? _parseDateTime(json['unenrolledAt']) : null,
      suspendedAt: json['suspendedAt'] != null ? _parseDateTime(json['suspendedAt']) : null,
      user: json['user'] != null 
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      course: _parseCourseData(courseData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'courseId': courseId,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'completionStatus': completionStatus,
      'progress': progress,
      'completedLessons': completedLessons,
      'certificateEligible': certificateEligible,
      'paymentId': paymentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (accessExpirationDate != null) 'accessExpirationDate': accessExpirationDate!.toIso8601String(),
      'rating': rating,
      'feedback': feedback,
      'canAccessLiveSessions': canAccessLiveSessions,
      'canAccessChapters': canAccessChapters,
      'status': status,
      if (user != null) 'user': user!.toJson(),
      if (course != null) 'course': course!.toJson(),
    };
  }

  // Helper getters
  bool get isCompleted => completionStatus == 'completed';
  bool get isInProgress => completionStatus == 'in-progress';
  bool get isEnrolled => completionStatus == 'enrolled';
  
  String get statusDisplay {
    switch (completionStatus) {
      case 'completed':
        return 'Completed';
      case 'in-progress':
        return 'In Progress';
      case 'enrolled':
        return 'Enrolled';
      default:
        return completionStatus;
    }
  }

  String get progressDisplay => '${progress.toStringAsFixed(1)}%';
  
  bool get isActiveEnrollment => status == 'active';
  bool get isUnenrolled => status == 'unenrolled';
  bool get isSuspended => status == 'suspended';

  bool get isExpired => accessExpirationDate != null && DateTime.now().isAfter(accessExpirationDate!);
  
  Duration? get timeRemaining => accessExpirationDate?.difference(DateTime.now());
  
  bool get isExpiringSoon => accessExpirationDate != null && 
      !isExpired && 
      accessExpirationDate!.difference(DateTime.now()).inDays <= 7;
}
