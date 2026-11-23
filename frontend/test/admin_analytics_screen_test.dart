// The super admin analytics dashboard renders every tab without layout
// errors on phone and desktop widths, in light and dark mode.
import 'package:excellencecoachinghub/presentation/screens/admin/admin_analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

List<Map<String, dynamic>> _series(int n, double Function(int) f) => [
      for (var i = 0; i < n; i++)
        {'date': DateTime(2026, 10, 25).add(Duration(days: i)).toIso8601String().substring(0, 10), 'value': f(i)},
    ];

Map<String, dynamic> _fixture(int days) {
  final n = days > 90 ? 13 : days + 1;
  List<Map<String, dynamic>> s(double Function(int) f) => days > 90
      ? [for (var i = 0; i < 13; i++) {'date': '2026-${(i % 12 + 1).toString().padLeft(2, '0')}', 'value': f(i)}]
      : _series(n, f);
  return {
    'range': {'days': days, 'from': '2026-10-24T00:00:00Z', 'to': '2026-11-23T00:00:00Z', 'bucket': days > 90 ? 'month' : 'day'},
    'partial': false,
    'people': {
      'totalUsers': 305, 'students': 286, 'teachers': 9, 'parents': 2, 'schoolAdmins': 3, 'admins': 5,
      'byRole': [
        {'label': 'student', 'value': 286}, {'label': 'instructor', 'value': 9}, {'label': 'admin', 'value': 5},
        {'label': 'school_admin', 'value': 3}, {'label': 'parent', 'value': 2},
      ],
      'newStudents': {'value': 80, 'previous': 21},
      'newUsers': {'value': 92, 'previous': 21},
      'privateStudents': 283, 'schoolStudents': 3, 'verified': 169, 'inactiveAccounts': 2,
      'gender': [{'label': 'unknown', 'value': 283}, {'label': 'female', 'value': 2}, {'label': 'male', 'value': 1}],
      'provinces': [{'label': 'Southern', 'value': 2}, {'label': 'Kigali City', 'value': 1}],
      'signupSeries': s((i) => (i * 7 % 11).toDouble()),
      'studentSignupSeries': s((i) => (i * 5 % 9).toDouble()),
    },
    'engagement': {
      'dau': 10, 'wau': 61, 'mau': {'value': 103, 'previous': 20}, 'stickiness': 9.7, 'activeRate': 36,
      'totalStudyHours': 635, 'avgSessionMinutes': 12, 'totalSessions': 3280,
      'lastActiveSeries': s((i) => (i % 6).toDouble()),
    },
    'learning': {
      'courses': 51, 'publishedCourses': 49, 'draftCourses': 2, 'newCourses': 31, 'enrollments': 169, 'learners': 79,
      'newEnrollments': {'value': 75, 'previous': 20}, 'completions': {'value': 2, 'previous': 0},
      'completedTotal': 8, 'completionRate': 4.7, 'avgProgress': 8.5, 'enrollmentsPerLearner': 2.1,
      'enrollmentStatus': [{'label': 'active', 'value': 169}],
      'completionStatus': [
        {'label': 'in-progress', 'value': 82}, {'label': 'enrolled', 'value': 79}, {'label': 'completed', 'value': 8},
      ],
      'certificates': {'total': 2, 'value': 0, 'previous': 0},
      'rating': {'average': 4.3, 'count': 6},
      'levelMix': [{'label': 'beginner', 'value': 44}, {'label': 'intermediate', 'value': 6}, {'label': 'advanced', 'value': 1}],
      'categoryMix': [{'label': 'Secondary coaching', 'value': 26}, {'label': 'Primary School Coaching', 'value': 6}],
      'topCourses': [
        {'id': 'c1', 'title': 'Physics senior 6', 'enrollments': 9, 'completed': 0, 'avgProgress': 0, 'price': 1500, 'rating': 0},
        {
          'id': 'c2',
          'title': '(Upper Primary) SET Coaching | Science Elementary Technology Made Easy with a very long title',
          'enrollments': 7, 'completed': 0, 'avgProgress': 1.1, 'price': 0, 'rating': 4,
        },
      ],
      'topStudents': [
        {'id': 'u1', 'name': 'Student One', 'email': 'one@example.com', 'enrollments': 10, 'completed': 3, 'avgProgress': 45.5},
        {'id': 'u2', 'name': '', 'email': '', 'enrollments': 1, 'completed': 1, 'avgProgress': 100},
      ],
      'enrollmentSeries': s((i) => (i * 3 % 8).toDouble()),
      'completionSeries': s((i) => (i % 4 == 0 ? 1 : 0).toDouble()),
    },
    'exams': {
      'total': 56, 'passed': 4, 'passRate': 7.1, 'avgScore': 0, 'submissions': {'value': 0, 'previous': 0},
      'passRateInRange': 0, 'series': s((_) => 0), 'passedSeries': s((_) => 0),
    },
    'live': {'status': [], 'liveNow': 0, 'inRange': 3, 'upcoming': 1},
    'labs': {'attempts': 0, 'completed': 0, 'passed': 0, 'learners': 0, 'avgScore': 0, 'completionRate': 0},
    'revenue': {
      'currency': 'RWF', 'allTime': 1250000, 'paidPayments': 140,
      'total': {'value': 320000, 'previous': 410000}, 'transactions': {'value': 24, 'previous': 30},
      'averageOrder': 13333, 'payingUsers': 20, 'arpu': 16000, 'successRate': 82.5, 'failed': 4,
      'pending': {'count': 2, 'total': 3000}, 'awaitingReview': {'count': 1, 'total': 1500},
      'statusMix': [{'label': 'completed', 'value': 24}],
      'byMethod': [
        {'label': 'mtn_momo', 'value': 250000, 'count': 18}, {'label': 'airtel_money', 'value': 50000, 'count': 4},
        {'label': 'card', 'value': 20000, 'count': 2},
      ],
      'byPurpose': [{'label': 'course', 'value': 300000, 'count': 22}, {'label': 'school_term', 'value': 20000, 'count': 2}],
      'topCourses': [{'id': 'c1', 'title': 'Physics senior 6', 'revenue': 120000, 'sales': 80}],
      'series': s((i) => (i * 13 % 7) * 5000.0),
      'countSeries': s((i) => (i * 13 % 7).toDouble()),
      'recent': [
        {
          'id': 'p1', 'amount': 1500, 'currency': 'RWF', 'method': 'mtn_momo', 'purpose': 'course',
          'date': '2026-11-22T10:00:00Z', 'user': 'A very long user name that should be cut off nicely', 'item': 'Physics senior 6',
        },
      ],
    },
    'schools': {
      'total': 4, 'active': 3, 'newSchools': {'value': 1, 'previous': 0}, 'classrooms': 5, 'students': 3,
      'avgStudentsPerSchool': 0.8,
      'byPlan': [{'label': 'free', 'value': 3}, {'label': 'premium', 'value': 1}],
      'byType': [{'label': 'secondary', 'value': 3}, {'label': 'tvet', 'value': 1}],
      'top': [{'id': 's1', 'name': 'Example High School', 'students': 3, 'plan': 'free', 'district': 'Huye'}],
    },
    'feedback': {'unread': 3, 'inRange': 5},
  };
}

void main() {
  for (final size in const [Size(1440, 900), Size(390, 844)]) {
    for (final brightness in Brightness.values) {
      testWidgets('analytics dashboard renders every tab (${size.width.toInt()} px, ${brightness.name})', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final requested = <int>[];
        final router = GoRouter(initialLocation: '/admin/analytics', routes: [
          GoRoute(path: '/admin', builder: (_, __) => const SizedBox()),
          GoRoute(
            path: '/admin/analytics',
            builder: (_, __) => AdminAnalyticsScreen(loader: (days) async {
              requested.add(days);
              return _fixture(days);
            }),
          ),
        ]);
        await tester.pumpWidget(ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData(brightness: brightness),
          ),
        ));
        await tester.pump(const Duration(seconds: 2));

        expect(find.text('Platform Analytics'), findsOneWidget);
        expect(requested, [30]);

        for (final tab in ['revenue', 'learning', 'people', 'schools', 'overview']) {
          final t = find.byKey(ValueKey('analytics-tab-$tab'));
          expect(t, findsOneWidget, reason: tab);
          await tester.ensureVisible(t);
          await tester.tap(t);
          await tester.pump(const Duration(seconds: 2));
          // Scroll through the whole tab so every panel lays out and paints.
          await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -4000));
          await tester.pump(const Duration(seconds: 1));
          await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 8000));
          await tester.pump(const Duration(seconds: 1));
        }

        // Switching period reloads with that period.
        await tester.tap(find.text('12M'));
        await tester.pump(const Duration(seconds: 2));
        expect(requested, [30, 365]);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
