import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:excellencecoachinghub/presentation/providers/exam_provider.dart';
import 'package:excellencecoachinghub/widgets/admin_layout_wrapper.dart';
import 'package:excellencecoachinghub/presentation/screens/splash/splash_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/login_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/register_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/forgot_password_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/reset_password_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/auth_selection_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/email_auth_option_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/enter_reset_code_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/phone_collection_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/name_collection_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/phone_auth_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/onboarding/interest_selection_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/language/language_selection_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/courses/courses_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/courses/course_detail_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/profile/profile_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/settings/settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/certificates/certificates_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/certificates/certificate_verification_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/privacy/privacy_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/terms/terms_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/categories/categories_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/enrolled/enrolled_courses_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/help/help_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_courses_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/live/upcoming_sessions_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/create_course_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_course_content_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_create_lesson_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_students_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/course_videos_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/course_materials_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/payment_management_screen_riverpod.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_videos_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_recordings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_analytics_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/course_analytics_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_notifications_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_push_report_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_feedback_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_payment_settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_general_settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_user_mgmt_settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_content_moderation_settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_management_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_books_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_teachers_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_live_sessions_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/teacher/teacher_dashboard_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/teacher/teacher_course_detail_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/teacher/schedule_live_session_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/teacher/live_sessions_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/teacher/teacher_create_section_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/teacher/teacher_create_lesson_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/learning/professional_learning_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/learning/professional_lesson_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/learning/enhanced_quiz_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/notifications/notifications_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/exam_history_screen.dart';
import 'package:excellencecoachinghub/widgets/main_layout.dart';
import 'package:excellencecoachinghub/presentation/screens/downloads/downloads_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/landing/landing_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/payments/payment_history_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/payments/payment_pending_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/library/library_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/library/book_reader_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/community/community_hub_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/community/course_community_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/community/community_section.dart';
import 'package:excellencecoachinghub/presentation/screens/messages/messages_screen.dart';
import 'package:excellencecoachinghub/utils/navigation_performance_monitor.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/router/offline_route_policy.dart';
import 'package:excellencecoachinghub/services/connectivity_service.dart';
import 'package:excellencecoachinghub/presentation/screens/course_builder/course_builder_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/course_builder/course_build_job_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/course_builder/course_build_item_screen.dart';

/// Custom page transition for smooth navigation with performance monitoring
class _FadeTransitionPage extends CustomTransitionPage<void> {
  _FadeTransitionPage({
    required super.child,
    required super.name,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            NavigationPerformanceMonitor.startNavigation(name ?? 'unknown');
            return FadeTransition(
              opacity: animation.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut))),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 150),
          key: ValueKey('fade_$name'),
        );
}

/// Slide transition for modal-style navigation with performance monitoring
class _SlideUpTransitionPage extends CustomTransitionPage<void> {
  _SlideUpTransitionPage({
    required super.child,
    required super.name,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            NavigationPerformanceMonitor.startNavigation(name ?? 'unknown');
            const begin = Offset(0.0, 0.05);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
            final offsetAnimation = animation.drive(tween);
            return FadeTransition(
              opacity: animation.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut))),
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 180),
          key: ValueKey('slide_$name'),
        );
}

class AppRouter {
  // Static instance for singleton
  static final AppRouter _instance = AppRouter._internal();
  
  // Factory constructor
  factory AppRouter() => _instance;
  
  // Private internal constructor
  AppRouter._internal();

  // Lazy-loaded GoRouter (created once per app)
  late final GoRouter _router = _buildRouter();

  static GoRouter get routerInstance => _instance._router;

  GoRouter get router => _router;


  GoRouter _buildRouter() {
    // Safety net in case the app entry point didn't initialize it: the offline
    // guard below is only correct once the service is listening.
    unawaited(ConnectivityService.instance.initialize());
    return GoRouter(
        initialLocation: '/',
        debugLogDiagnostics: false,
        // Re-runs the redirect below whenever connectivity flips, which is what
        // moves a user off an online-only screen the moment the network drops.
        refreshListenable: ConnectivityService.instance,
        errorBuilder: (context, state) => Scaffold(
          body: Center(
            child: Text('Route not found: ${state.uri.path}'),
          ),
        ),
        routes: [
          // Authentication & Onboarding Routes - Outside MainLayout for full-screen experience
          GoRoute(
            path: '/',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/landing',
            builder: (context, state) => const LandingScreen(),
          ),
          GoRoute(
            path: '/language-selection',
            builder: (context, state) => const LanguageSelectionScreen(),
          ),
          GoRoute(
            path: '/auth-selection',
            builder: (context, state) => const AuthSelectionScreen(),
          ),
          GoRoute(
            path: '/email-auth-option',
            builder: (context, state) => const EmailAuthOptionScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/enter-reset-code',
            builder: (context, state) => const EnterResetCodeScreen(),
          ),
          // Reset Password Route
          GoRoute(
            path: '/reset-password',
            builder: (context, state) {
              final mode = state.uri.queryParameters['mode'];
              final oobCode = state.uri.queryParameters['oobCode'];
              
              // Only return oobCode if mode is resetPassword
              final resetCode = (mode == 'resetPassword' || mode == 'verifyEmail') ? oobCode : oobCode;
              return ResetPasswordScreen(oobCode: resetCode);
            },
          ),
          // Phone Auth - Outside MainLayout to prevent layout duplication
          GoRoute(
            path: '/phone-auth',
            builder: (context, state) => const PhoneAuthScreen(),
          ),
          // Phone Collection - Outside MainLayout to prevent layout duplication
          GoRoute(
            path: '/phone-collection',
            builder: (context, state) => const PhoneCollectionScreen(),
          ),
          // Name Collection - for phone sign-in users without a name
          GoRoute(
            path: '/name-collection',
            builder: (context, state) => const NameCollectionScreen(),
          ),
          // Onboarding Screens - Outside MainLayout for full-screen experience
          GoRoute(
            path: '/interest-selection',
            builder: (context, state) {
              bool isEditMode = false;
              if (state.extra is Map) {
                final extra = state.extra as Map;
                isEditMode = extra['isEditMode'] == true;
              }
              return InterestSelectionScreen(isEditMode: isEditMode);
            },
          ),
          // Privacy, Terms, Help - Outside MainLayout to prevent layout duplication
          GoRoute(
            path: '/privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: '/terms',
            builder: (context, state) => const TermsScreen(),
          ),
          GoRoute(
            path: '/help',
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: '/verify-certificate/:serial',
            builder: (context, state) {
              final serial = state.pathParameters['serial'] ?? '';
              return CertificateVerificationScreen(serialNumber: serial);
            },
          ),

          // Admin Routes - Outside MainLayout because they have their own sidebar/layout
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Dashboard',
              child: AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/courses',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Courses',
              child: AdminCoursesScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/courses/create',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Create Course',
              child: AdminCreateCourseScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/courses/:courseId/sections/:sectionId/lessons/:lessonId/edit',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              final sectionId = state.pathParameters['sectionId'] ?? '';
              final lessonId = state.pathParameters['lessonId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Edit Lesson',
                child: AdminCreateLessonScreen(
                  courseId: courseId,
                  sectionId: sectionId,
                  lessonId: lessonId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Admin Course Content',
                child: AdminCourseContentScreen(courseId: courseId, courseTitle: 'Course Content'),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/edit',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Edit Course',
                child: AdminCreateCourseScreen(courseId: courseId),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/content',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Admin Course Content',
                child: AdminCourseContentScreen(courseId: courseId, courseTitle: 'Course Content'),
              );
            },
          ),
          // AI Course Builder (book → course draft → review → publish)
          GoRoute(
            path: '/admin/courses/:courseId/ai-builder',
            builder: (context, state) => AdminLayoutWrapper(
              screenName: 'AI Course Builder',
              child: CourseBuilderScreen(courseId: state.pathParameters['courseId'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/admin/ai-builds/:jobId',
            builder: (context, state) => AdminLayoutWrapper(
              screenName: 'AI Course Build',
              child: CourseBuildJobScreen(jobId: state.pathParameters['jobId'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/admin/ai-build-items/:itemId',
            builder: (context, state) => AdminLayoutWrapper(
              screenName: 'Review AI Draft',
              child: CourseBuildItemScreen(itemId: state.pathParameters['itemId'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/admin/courses/:courseId/videos',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Course Videos',
                child: CourseVideosScreen(courseId: courseId),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/materials',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Course Materials',
                child: CourseMaterialsScreen(courseId: courseId),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/analytics',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Course Analytics',
                child: CourseAnalyticsScreen(courseId: courseId),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/sections/:sectionId/lessons/create',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              final sectionId = state.pathParameters['sectionId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Create Lesson',
                child: AdminCreateLessonScreen(
                  courseId: courseId,
                  sectionId: sectionId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/admin/videos',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Videos',
              child: AdminVideosScreen(),
            ),
          ),
          // Platform-wide recordings library — admins are the only role that
          // can download a course recording, so this is where they do it.
          GoRoute(
            path: '/admin/recordings',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Recordings',
              child: AdminRecordingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/students',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Students',
              child: AdminStudentsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/admins',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Management',
              child: AdminManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/students/:studentId',
            builder: (context, state) {
              final studentId = state.pathParameters['studentId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Admin Student Details',
                child: AdminStudentsScreen(studentId: studentId),
              );
            },
          ),
          GoRoute(
            path: '/admin/payments',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Payments',
              child: PaymentManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Settings',
              child: AdminSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings/payments',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Payment Settings',
              child: AdminPaymentSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings/general',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin General Settings',
              child: AdminGeneralSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings/users',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin User Settings',
              child: AdminUserManagementSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings/moderation',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Moderation Settings',
              child: AdminContentModerationSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/analytics',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Analytics',
              child: AdminAnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/user-feedback',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin User Feedback',
              child: AdminFeedbackScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Notifications',
              child: AdminNotificationsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/push-report',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Push Report',
              child: AdminPushReportScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/books',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Books',
              child: AdminBooksScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/teachers',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Teachers',
              child: AdminTeachersScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/live-sessions',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Live Sessions',
              child: AdminLiveSessionsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/exams-review',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Exams Review',
              child: AdminLiveSessionsScreen(),
            ),
          ),

          // Teacher Routes - Outside MainLayout for full-screen experience
          GoRoute(
            path: '/teacher/dashboard',
            builder: (context, state) => const TeacherDashboardScreen(),
          ),
          GoRoute(
            path: '/teacher/courses',
            builder: (context, state) => const TeacherDashboardScreen(),
          ),
          GoRoute(
            path: '/teacher/courses/:courseId',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return TeacherCourseDetailScreen(courseId: courseId);
            },
          ),
          GoRoute(
            path: '/teacher/courses/:courseId/ai-builder',
            builder: (context, state) => CourseBuilderScreen(courseId: state.pathParameters['courseId'] ?? '', isTeacher: true),
          ),
          GoRoute(
            path: '/teacher/ai-builds/:jobId',
            builder: (context, state) => CourseBuildJobScreen(jobId: state.pathParameters['jobId'] ?? '', isTeacher: true),
          ),
          GoRoute(
            path: '/teacher/ai-build-items/:itemId',
            builder: (context, state) => CourseBuildItemScreen(itemId: state.pathParameters['itemId'] ?? ''),
          ),
          GoRoute(
            path: '/teacher/sessions',
            builder: (context, state) => const LiveSessionsScreen(),
          ),
          GoRoute(
            path: '/teacher/sessions/create',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ScheduleLiveSessionScreen(
                courseId: extra?['courseId'],
                sectionId: extra?['sectionId'],
                lessonId: extra?['lessonId'],
              );
            },
          ),
          GoRoute(
            path: '/teacher/courses/:courseId/students/:studentId',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              final studentId = state.pathParameters['studentId'] ?? '';
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Student Details'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Student ID: $studentId',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Course ID: $courseId',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Student detail screen coming soon',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: '/teacher/courses/:courseId/create-section',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return TeacherCreateSectionScreen(courseId: courseId);
            },
          ),
          GoRoute(
            path: '/teacher/courses/:courseId/sections/:sectionId/create-lesson',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              final sectionId = state.pathParameters['sectionId'] ?? '';
              return TeacherCreateLessonScreen(
                courseId: courseId,
                sectionId: sectionId,
              );
            },
          ),

          // Learning Routes - Outside MainLayout for full-screen focus
          GoRoute(
            path: '/learning/:courseId',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return ProfessionalLearningScreen(courseId: courseId);
            },
          ),
                    // AI Course Builder draft shown in the real lesson viewer (teacher/admin preview)
          GoRoute(
            path: '/ai-preview/:itemId',
            builder: (context, state) {
              final itemId = state.pathParameters['itemId'] ?? '';
              return ProfessionalLessonScreen(
                key: ValueKey('ai-preview-$itemId'),
                lessonId: itemId,
                draftItemId: itemId,
                isAdminPreview: true,
              );
            },
          ),
          GoRoute(
            path: '/lesson/:lessonId',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId'] ?? '';
              final isAdminPreview = state.uri.queryParameters['admin'] == 'true';
              // ?tab=notes / video / quiz — lets callers open the lesson on the
              // tab matching the material the student tapped
              final initialTab = state.uri.queryParameters['tab'];
              return ProfessionalLessonScreen(
                lessonId: lessonId,
                isAdminPreview: isAdminPreview,
                initialTab: initialTab,
              );
            },
          ),
          GoRoute(
            path: '/learning/:courseId/video',
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(title: const Text('Video Learning')),
                body: const Center(child: Text('Video learning screen')),
              );
            },
          ),
          GoRoute(
            path: '/learning/:courseId/notes',
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(title: const Text('Notes Learning')),
                body: const Center(child: Text('Notes learning screen')),
              );
            },
          ),
          GoRoute(
            path: '/learning/:courseId/section/:sectionId',
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(title: const Text('Section Learning')),
                body: const Center(child: Text('Section learning screen')),
              );
            },
          ),
          GoRoute(
            path: '/enhanced-quiz/:quizId',
            builder: (context, state) {
              final quizId = state.pathParameters['quizId'] ?? '';
              final lessonTitle = state.uri.queryParameters['lessonTitle'] ?? '';
              return EnhancedQuizScreen(
                quizId: quizId,
                lessonTitle: Uri.decodeComponent(lessonTitle),
              );
            },
          ),

          // Shell Route for Student Dashboard and Main App Pages
          ShellRoute(
            builder: (context, state, child) => MainLayout(
              key: const ValueKey('main_shell'),
              child: child,
            ),
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => _FadeTransitionPage(
                  name: state.matchedLocation,
                  child: const DashboardScreen(),
                ),
              ),
              GoRoute(
                path: '/courses',
                pageBuilder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  // Create unique key based on parameters to force widget recreation
                  final uniqueKey = ValueKey(
                    '${extra?['categoryId'] ?? 'all'}_${extra?['searchQuery'] ?? ''}_${DateTime.now().millisecondsSinceEpoch}',
                  );
                  return _SlideUpTransitionPage(
                    name: state.matchedLocation,
                    child: CoursesScreen(
                      key: uniqueKey,
                      categoryId: extra?['categoryId'] as String?,
                      categoryName: extra?['categoryName'] as String?,
                      searchQuery: extra?['searchQuery'] as String?,
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/course/:id',
                pageBuilder: (context, state) {
                  final courseId = state.pathParameters['id'] ?? '';
                  return _SlideUpTransitionPage(
                    name: state.matchedLocation,
                    child: CourseDetailScreen(courseId: courseId),
                  );
                },
              ),
              GoRoute(
                path: '/payment/pending',
                pageBuilder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  if (extra == null) {
                    return _FadeTransitionPage(
                      name: state.matchedLocation,
                      child: Scaffold(
                        appBar: AppBar(title: const Text('Error')),
                        body: const Center(
                          child: Text('Payment information not found'),
                        ),
                      ),
                    );
                  }
                  return _FadeTransitionPage(
                    name: state.matchedLocation,
                    child: PaymentPendingScreen(
                      course: extra['course'],
                      transactionId: extra['transactionId'] as String,
                      amount: extra['amount'] as double,
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/downloads',
                builder: (context, state) => DownloadsScreen(
                  initialTab: state.uri.queryParameters['tab'],
                ),
              ),
              GoRoute(
                path: '/my-courses',
                builder: (context, state) => const EnrolledCoursesScreen(),
              ),
              // Course Community — the hub asks which course, then opens that
              // course's community (students, groups, discussions, work).
              GoRoute(
                path: '/community',
                builder: (context, state) => const CommunityHubScreen(),
              ),
              GoRoute(
                path: '/community/:courseId',
                builder: (context, state) => CourseCommunityScreen(
                  courseId: state.pathParameters['courseId'] ?? '',
                  initialSection: CommunitySectionInfo.fromSlug(
                    state.uri.queryParameters['section'],
                  ),
                ),
              ),
              // One-to-one messaging inbox
              GoRoute(
                path: '/messages',
                builder: (context, state) => const MessagesScreen(),
              ),
              GoRoute(
                path: '/upcoming-sessions',
                builder: (context, state) => const UpcomingSessionsScreen(),
              ),
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
              GoRoute(
                path: '/books/:bookId',
                builder: (context, state) {
                  final bookId = state.pathParameters['bookId'] ?? '';
                  final extra = state.extra;
                  
                  if (extra != null) {
                    return BookReaderScreen(book: extra);
                  } else {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Book Not Found')),
                      body: const Center(
                        child: Text('Book not found or could not be loaded'),
                      ),
                    );
                  }
                },
              ),
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: '/payments/history',
                builder: (context, state) => const PaymentHistoryScreen(),
              ),
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoriesScreen(),
              ),
              GoRoute(
                path: '/my-courses',
                builder: (context, state) => const EnrolledCoursesScreen(),
              ),
              GoRoute(
                path: '/certificates',
                builder: (context, state) => const CertificatesScreen(),
              ),
              GoRoute(
                path: '/exams/history',
                // ExamHistoryScreen reads ExamProvider via package:provider;
                // nothing above it provides one, so scope it to this route.
                builder: (context, state) => legacy_provider.ChangeNotifierProvider(
                  create: (_) => ExamProvider(),
                  child: const ExamHistoryScreen(),
                ),
              ),
            ],
          ),
        ],
        redirect: (context, state) {
          // Offline guard: online-only screens fall back to Downloads. This
          // covers both directions — navigating to such a screen while already
          // offline, and the connection dropping while the screen is open
          // (refreshListenable re-runs this callback on every change).
          final connectivity = ConnectivityService.instance;
          if (connectivity.isOffline &&
              OfflineRoutePolicy.requiresInternet(state.matchedLocation)) {
            connectivity.recordBlockedLocation(state.uri.toString());
            return OfflineRoutePolicy.offlineFallbackRoute;
          }

          // Auth guard: prevent landing on auth selection when a valid session exists.
          if (state.matchedLocation == '/auth-selection') {
            // Using Riverpod directly from GoRouter redirect is not reliable because
            // BuildContext here is not tied to a ProviderScope.
            // So we rely on a lightweight check: if auth restoration has already
            // populated backend tokens, the user should not stay on auth-selection.
            // (If needed, replace this with an async redirect that waits for authProvider.)
            // TODO: implement auth-aware redirect using an async redirect or a
            // provider-backed listener outside the redirect callback.
            return null;
          }
          return null;
        },
      );
  }
}
