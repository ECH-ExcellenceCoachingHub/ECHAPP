// Renders the school screens with real API answers (test/fixtures/school) on
// phone and tablet sizes. A test fails on any layout overflow or exception.
//
// Screenshots: flutter test test/school_screens_phone_test.dart --dart-define=SHOTS_DIR=C:/path/to/dir
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:excellencecoachinghub/presentation/screens/auth/school_sign_in_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/school/class_code_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/school/class_detail_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/school/parent_screens.dart';
import 'package:excellencecoachinghub/presentation/screens/school/student_form_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/school/student_school_screens.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/school_admin_dashboard_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/sections/access_section.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/sections/billing_section.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/sections/parents_section.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/sections/progress_section.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/sections/results_section.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/sections/signins_section.dart';
import 'package:excellencecoachinghub/presentation/screens/school/group_screens.dart';
import 'package:excellencecoachinghub/presentation/screens/teacher/school/class_subject_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/teacher/school/homework_screens.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/sections/classes_section.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/sections/staff_section.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/sections/students_section.dart';
import 'package:excellencecoachinghub/presentation/screens/teacher/school/teacher_classes_screen.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/school_service.dart';
import 'package:excellencecoachinghub/services/infrastructure/api_client.dart';
import 'package:excellencecoachinghub/widgets/school/school_i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _shotsDir = String.fromEnvironment('SHOTS_DIR');

Map<String, dynamic> _fx(String name) => jsonDecode(File('test/fixtures/school/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// Answers school API calls from the fixtures.
class _FakeApi extends ApiClient {
  http.Response _answer(String url) {
    final path = Uri.parse(url).path;
    String? name;
    final ends = <String, String>{
      '/progress': 'progress',
      '/coverage': 'coverage',
      '/results': 'results',
      '/sign-ins': 'signins',
      '/parents': 'parents',
      '/terms': 'terms',
      '/syllabus': 'syllabus',
      '/assessments': 'assessments',
      '/messages': 'messages',
    };
    for (final e in ends.entries) {
      if (path.endsWith(e.key)) name = e.value;
    }
    if (name != null) {
      // matched above
    } else if (RegExp(r'/school/teaching/assessments/[^/]+$').hasMatch(path)) {
      name = 'assessment';
    } else if (RegExp(r'/school/groups/[^/]+$').hasMatch(path)) {
      name = 'group';
    } else if (path.endsWith('/overview')) {
      name = 'overview';
    } else if (RegExp(r'/schools/[^/]+/classes$').hasMatch(path)) {
      name = 'classes';
    } else if (path.contains('/school/classes/')) {
      name = 'class_detail';
    } else if (path.endsWith('/staff')) {
      name = 'staff';
    } else if (RegExp(r'/schools/[^/]+/students$').hasMatch(path)) {
      name = 'students';
    } else if (RegExp(r'/schools/[^/]+$').hasMatch(path)) {
      name = 'school';
    } else if (path.endsWith('/school/learning/home')) {
      name = 'student_home';
    } else if (path.endsWith('/school/groups')) {
      name = 'groups';
    } else if (path.endsWith('/school/parent/children')) {
      name = 'children';
    } else if (path.contains('/school/parent/children/')) {
      name = 'child';
    } else if (path.endsWith('/school/teaching/me')) {
      name = 'teaching_me';
    } else if (path.endsWith('/school/access-code')) {
      name = 'access_code';
    }
    final body = name == null ? {'success': true, 'data': <String, dynamic>{'ip': '41.186.1.2', 'onSchoolNetwork': false}} : _fx(name);
    return http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json; charset=utf-8'});
  }

  @override
  Future<http.Response> get(String url, {Map<String, String>? headers, Map<String, dynamic>? queryParams, bool authenticate = true}) async => _answer(url);
}

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      final file = File('$dir/$f');
      if (file.existsSync()) loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
    await loader.load();
  }

  await family('Roboto', ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']);
  // Widgets without a font family use the test font; make it Roboto too.
  await family('FlutterTest', ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']);
  await family('MaterialIcons', ['materialicons-regular.otf']);
}

final _shotKey = GlobalKey();

Future<void> _show(WidgetTester tester, String name, Widget screen, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(textTheme: AppTheme.lightTheme.textTheme.apply(fontFamily: 'Roboto')),
      home: RepaintBoundary(key: _shotKey, child: screen),
    ),
  ));
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (_shotsDir.isNotEmpty) {
    await tester.runAsync(() async {
      final boundary = _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_shotsDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }
  // Stop timers (class code refresh) before the test ends.
  await tester.pumpWidget(const SizedBox.shrink());
}

SchoolCtx _ctx() {
  final school = Map<String, dynamic>.from((_fx('school')['data'] as Map)['school'] as Map);
  return SchoolCtx(schoolId: '${school['id']}', superAdmin: false, svc: SchoolService(), school: school, reloadSchool: () async {}, go: (_) {});
}

Widget _section(Widget child) => Scaffold(appBar: AppBar(title: const Text('School')), body: child);

void main() {
  setUpAll(() async {
    SchoolService.testClient = _FakeApi();
    await _loadFonts();
  });

  final screens = <String, Widget Function()>{
    'sign_in': () => const SchoolSignInScreen(),
    'student_home': () => const StudentSchoolHomeScreen(),
    'parent_home': () => const ParentHomeScreen(),
    'parent_child': () => const ParentChildScreen(childId: 'c1'),
    'admin_overview': () => const SchoolAdminDashboardScreen(schoolId: 's1'),
    'admin_classes': () => _section(ClassesSection(c: _ctx())),
    'admin_staff': () => _section(StaffSection(c: _ctx())),
    'admin_students': () => _section(StudentsSection(c: _ctx())),
    'admin_access': () => _section(AccessSection(c: _ctx())),
    'class_detail': () => const ClassDetailScreen(classId: 'c1'),
    'class_code': () => const ClassCodeScreen(classId: 'c1'),
    'teacher_classes': () => const MyClassesScreen(),
    'student_form': () => const StudentFormScreen(schoolId: 's1'),
    'admin_progress': () => _section(ProgressSection(c: _ctx())),
    'admin_results': () => _section(ResultsSection(c: _ctx())),
    'admin_signins': () => _section(SignInsSection(c: _ctx())),
    'admin_parents': () => _section(ParentsSection(c: _ctx())),
    'admin_billing': () => _section(BillingSection(c: _ctx())),
    'teacher_subject': () => const ClassSubjectScreen(classSubjectId: 'cs1'),
    'homework_marking': () => const HomeworkDetailScreen(assessmentId: 'a1'),
    'groups': () => const GroupsScreen(),
    'group_chat': () => const GroupChatScreen(groupId: 'g1'),
  };

  // Kinyarwanda is longer than English: check the smallest phone in Kinyarwanda too.
  group('Kinyarwanda', () {
    setUp(() => debugForceKinyarwanda = true);
    tearDown(() => debugForceKinyarwanda = false);
    for (final e in screens.entries) {
      testWidgets('${e.key} fits 360x740 in Kinyarwanda', (tester) async {
        await _show(tester, '${e.key}_rw', e.value(), size: const Size(360, 740));
      });
    }
  });

  for (final size in const [Size(360, 740), Size(390, 844), Size(820, 1180)]) {
    for (final e in screens.entries) {
      testWidgets('${e.key} fits ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        await _show(tester, '${e.key}_${size.width.toInt()}', e.value(), size: size);
      });
    }
  }
}
