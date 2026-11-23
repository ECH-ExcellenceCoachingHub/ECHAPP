import 'package:excellencecoachinghub/presentation/screens/school_admin/school_admin_dashboard_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/sections/staff_section.dart';
import 'package:excellencecoachinghub/services/api/school_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSvc extends SchoolService {
  @override
  Future<Map<String, dynamic>> staff(String schoolId, {String? role, String? search, String active = 'true'}) async => {
        'staff': [
          {'id': 'a1', 'fullName': 'Uwase Claudine', 'role': 'school_admin', 'email': 'h@x.rw', 'teaches': [], 'classTeacherOf': []},
        ],
      };
}

void main() {
  testWidgets('staff section: actions are separate buttons for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    final c = SchoolCtx(schoolId: 's1', superAdmin: false, svc: _FakeSvc(), school: {'id': 's1', 'admin': 'a1'}, reloadSchool: () async {}, go: (_) {});
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StaffSection(c: c))));
    await tester.pumpAndSettle();
    final add = tester.getSemantics(find.text('Add teacher'));
    expect(add.label, 'Add teacher');
    // The empty "Teachers" card must not be merged into the admin row's button.
    final empty = tester.getSemantics(find.text('No teachers yet'));
    expect(empty.label.contains('Uwase Claudine'), isFalse);
    final admin = tester.getSemantics(find.text('Uwase Claudine'));
    expect(admin.label.contains('Teachers (0)'), isFalse);
    expect(admin.label.contains('Uwase Claudine'), isTrue);
    handle.dispose();
  });
}
