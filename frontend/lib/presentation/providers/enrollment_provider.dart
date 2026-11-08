import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/data/repositories/enrollment_repository.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository();
});

// Provider to check if user is enrolled in a specific course
final isEnrolledInCourseProvider = FutureProvider.family<bool, String>((ref, courseId) async {
  final repository = ref.read(enrollmentRepositoryProvider);
  print('Checking enrollment status for course: $courseId');
  try {
    final result = await repository.isEnrolledInCourse(courseId);
    print('Enrollment check result for course $courseId: $result');
    return result;
  } catch (e) {
    print('Error checking enrollment for course $courseId: $e');
    return false;
  }
});

// Provider to get course access information including expiration
final courseAccessProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, courseId) async {
  final repository = ref.read(enrollmentRepositoryProvider);
  print('Checking course access for course: $courseId');
  try {
    final result = await repository.checkCourseAccess(courseId);
    print('Course access check result for course $courseId: $result');
    return result;
  } catch (e) {
    print('Error checking course access for course $courseId: $e');
    return null;
  }
});

// Enrollment status for a course (none/active/unenrolled/suspended), used to
// offer "Re-enroll" or show a suspension notice on the course page.
final enrollmentStatusProvider = FutureProvider.family<EnrollmentStatusInfo, String>((ref, courseId) async {
  final repository = ref.read(enrollmentRepositoryProvider);
  try {
    return await repository.getEnrollmentStatus(courseId);
  } catch (_) {
    return const EnrollmentStatusInfo(status: 'none');
  }
});

// Provider for enrolled courses with offline support
final enrolledCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.read(enrollmentRepositoryProvider);
  
  // Check connectivity
  final connectivityResult = await Connectivity().checkConnectivity();
  final isOffline = connectivityResult.isEmpty || 
                   connectivityResult.every((result) => result == ConnectivityResult.none);
  
  if (isOffline) {
    print('Device is offline, loading enrolled courses from cache');
    return await _loadCachedEnrolledCourses();
  }
  
  try {
    final courses = await repository.getEnrolledCourses();
    // Cache the courses for offline use
    await _cacheEnrolledCourses(courses);
    return courses;
  } catch (e) {
    print('Error fetching enrolled courses: $e, trying cache');
    return await _loadCachedEnrolledCourses();
  }
});

// Provider for user enrollments with completion status.
// Failures are surfaced as AsyncError rather than an empty list - every
// consumer handles `error`, and swallowing here made a failed load
// indistinguishable from "you are not enrolled in anything".
final userEnrollmentsProvider = FutureProvider<List<Enrollment>>((ref) async {
  final repository = ref.read(enrollmentRepositoryProvider);
  return repository.getEnrollments();
});

// Cache enrolled courses to SharedPreferences
Future<void> _cacheEnrolledCourses(List<Course> courses) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = courses.map((c) => c.toJson()).toList();
    await prefs.setString('cached_enrolled_courses', json.encode(coursesJson));
    print('Cached ${courses.length} enrolled courses');
  } catch (e) {
    print('Error caching enrolled courses: $e');
  }
}

// Load cached enrolled courses from SharedPreferences
Future<List<Course>> _loadCachedEnrolledCourses() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString('cached_enrolled_courses');
    if (coursesJson != null) {
      final List<dynamic> decoded = json.decode(coursesJson);
      final courses = decoded.map((json) => Course.fromJson(json)).toList();
      print('Loaded ${courses.length} cached enrolled courses');
      return courses;
    }
  } catch (e) {
    print('Error loading cached enrolled courses: $e');
  }
  return [];
}

// Async notifier for enrollment actions
final enrollmentNotifierProvider = AsyncNotifierProvider<EnrollmentNotifier, void>(
  () => EnrollmentNotifier(),
);

class EnrollmentNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> enrollInCourse(String courseId) async {
    final repository = ref.read(enrollmentRepositoryProvider);
    state = const AsyncValue.loading();

    try {
      await repository.enrollInCourse(courseId);
      state = const AsyncValue.data(null);

      // Refresh enrolled courses
      _invalidateCourse(courseId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      // Callers show the failure to the learner
      rethrow;
    }
  }

  /// Leave a course. Completed lessons, quiz results and certificates are
  /// kept on the server, and the learner can enroll again later.
  Future<void> unenrollFromCourse(String courseId) async {
    final repository = ref.read(enrollmentRepositoryProvider);
    state = const AsyncValue.loading();

    try {
      await repository.unenrollFromCourse(courseId);
      state = const AsyncValue.data(null);
      _invalidateCourse(courseId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  void _invalidateCourse(String courseId) {
    ref.invalidate(enrolledCoursesProvider);
    ref.invalidate(userEnrollmentsProvider);
    ref.invalidate(isEnrolledInCourseProvider(courseId));
    ref.invalidate(courseAccessProvider(courseId));
    ref.invalidate(enrollmentStatusProvider(courseId));
  }

  Future<void> markLessonComplete(String lessonId, String courseId) async {
    final repository = ref.read(enrollmentRepositoryProvider);
    state = const AsyncValue.loading();
    
    try {
      await repository.markLessonComplete(lessonId, courseId);
      state = const AsyncValue.data(null);
      
      // Refresh all relevant providers to update progress across app
      ref.invalidate(enrolledCoursesProvider);
      ref.invalidate(courseAccessProvider(courseId));
      ref.invalidate(userEnrollmentsProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> completeSection(String enrollmentId, String sectionId, String courseId) async {
    final repository = ref.read(enrollmentRepositoryProvider);
    state = const AsyncValue.loading();
    
    try {
      await repository.completeSection(enrollmentId, sectionId);
      state = const AsyncValue.data(null);
      
      // Refresh all relevant providers to update progress across app
      ref.invalidate(enrolledCoursesProvider);
      ref.invalidate(courseAccessProvider(courseId));
      ref.invalidate(userEnrollmentsProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
