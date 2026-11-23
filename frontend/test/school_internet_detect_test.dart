// Sign-in rules: the school internet is detected from the admin's own
// connection, so nobody has to look up an IP address.
import 'dart:convert';

import 'package:excellencecoachinghub/presentation/screens/school_admin/school_admin_dashboard_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/school_admin/sections/access_section.dart';
import 'package:excellencecoachinghub/services/api/school_service.dart';
import 'package:excellencecoachinghub/services/infrastructure/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _Api extends ApiClient {
  Map<String, dynamic>? patched;
  http.Response _ok(Object data) => http.Response(jsonEncode({'success': true, 'data': data}), 200, headers: {'content-type': 'application/json'});

  @override
  Future<http.Response> get(String url, {Map<String, String>? headers, Map<String, dynamic>? queryParams, bool authenticate = true}) async =>
      _ok({'ip': '2c0f:eb68:601:3c00:1111:2222:3333:4444', 'version': 6, 'suggestedRule': '2c0f:eb68:601:3c00::/64', 'usable': true, 'onSchoolNetwork': false});

  @override
  Future<http.Response> patch(String url, {Object? body, Map<String, String>? headers, bool authenticate = true}) async {
    patched = Map<String, dynamic>.from((body is String ? jsonDecode(body) : body) as Map);
    return _ok({'school': {'studentAccess': patched!['studentAccess']}});
  }
}

void main() {
  testWidgets('detects the connection and saves it with one tap (IPv6 → whole /64 network)', (tester) async {
    final api = _Api();
    SchoolService.testClient = api;
    addTearDown(() => SchoolService.testClient = null);
    tester.view.physicalSize = const Size(360, 1600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final c = SchoolCtx(
      schoolId: 's1',
      superAdmin: false,
      svc: SchoolService(),
      school: {'id': 's1', 'studentAccess': {'mode': 'network', 'allowedIps': []}},
      reloadSchool: () async {},
      go: (_) {},
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AccessSection(c: c))));
    await tester.pumpAndSettle();

    expect(find.text('Your connection now'), findsOneWidget);
    expect(find.text('2c0f:eb68:601:3c00::/64'), findsOneWidget);
    await tester.dragUntilVisible(find.text('Use this connection as school internet'), find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this connection as school internet'));
    await tester.pumpAndSettle();

    final rules = (api.patched!['studentAccess'] as Map)['allowedIps'] as List;
    expect(rules, ['2c0f:eb68:601:3c00::/64']);
    expect(find.text('This connection is a school internet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
