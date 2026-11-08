import '../../services/api/enrollment_service.dart';
import '../../models/course.dart';
import '../../models/enrollment.dart';

class EnrollmentRepository {
  final EnrollmentService _enrollmentService;

  EnrollmentRepository({EnrollmentService? enrollmentService}) 
      : _enrollmentService = enrollmentService ?? EnrollmentService();

  /// Enroll in a course
  Future<void> enrollInCourse(String courseId) async {
    return await _enrollmentService.enrollInCourse(courseId);
  }

  /// Unenroll from a course (progress is preserved server-side)
  Future<void> unenrollFromCourse(String courseId) async {
    return await _enrollmentService.unenrollFromCourse(courseId);
  }

  /// Enrollment status for one course (none/active/unenrolled/suspended)
  Future<EnrollmentStatusInfo> getEnrollmentStatus(String courseId) async {
    return await _enrollmentService.getEnrollmentStatus(courseId);
  }

  /// Get user's enrollment details
  Future<List<Enrollment>> getEnrollments() async {
    return await _enrollmentService.getEnrollments();
  }

  /// Get user's enrolled courses
  Future<List<Course>> getEnrolledCourses() async {
    return await _enrollmentService.getEnrolledCourses();
  }

  /// Check if user is enrolled in a specific course
  Future<bool> isEnrolledInCourse(String courseId) async {
    return await _enrollmentService.isEnrolledInCourse(courseId);
  }
  
  /// Check course access with expiration details
  Future<Map<String, dynamic>?> checkCourseAccess(String courseId) async {
    return await _enrollmentService.checkCourseAccess(courseId);
  }

  /// Update enrollment progress
  Future<Map<String, dynamic>> updateEnrollmentProgress(String enrollmentId, String lessonId, bool completed) async {
    return await _enrollmentService.updateEnrollmentProgress(enrollmentId, lessonId, completed);
  }

  /// Mark section as completed
  Future<Map<String, dynamic>> completeSection(String enrollmentId, String sectionId) async {
    return await _enrollmentService.completeSection(enrollmentId, sectionId);
  }

  /// Get enrollment progress
  Future<Map<String, dynamic>?> getEnrollmentProgress(String enrollmentId) async {
    return await _enrollmentService.getEnrollmentProgress(enrollmentId);
  }

  /// Submit course feedback
  Future<void> submitCourseFeedback(String courseId, double rating, String feedback) async {
    return await _enrollmentService.submitCourseFeedback(courseId, rating, feedback);
  }

  /// Mark lesson as completed
  Future<void> markLessonComplete(String lessonId, String courseId) async {
    return await _enrollmentService.markLessonComplete(lessonId, courseId);
  }
}
