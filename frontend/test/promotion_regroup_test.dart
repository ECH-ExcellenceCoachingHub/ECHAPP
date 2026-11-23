// Year-end promotion: students of one class can be sent to another
// combination / stream next year, alone or several at once.
import 'dart:convert';

import 'package:excellencecoachinghub/presentation/screens/school_admin/promotion_screen.dart';
import 'package:excellencecoachinghub/services/api/school_service.dart';
import 'package:excellencecoachinghub/services/infrastructure/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _Api extends ApiClient {
  Map<String, dynamic>? posted;

  http.Response _ok(Object data) => http.Response(jsonEncode({'success': true, 'data': data}), 200, headers: {'content-type': 'application/json'});

  @override
  Future<http.Response> get(String url, {Map<String, String>? headers, Map<String, dynamic>? queryParams, bool authenticate = true}) async {
    if (url.contains('/promotion/preview')) {
      return _ok({
        'fromYear': '2026',
        'toYear': '2027',
        'years': ['2026'],
        'combinations': ['MS-PURE'],
        'classes': [
          {'id': 'c3a', 'name': 'S3 A', 'level': 'S3', 'combination': '', 'stream': 'A', 'studentCount': 3, 'needsCombination': true,
            'suggested': {'action': 'promote', 'level': 'S4', 'combination': '', 'stream': 'A'}},
        ],
      });
    }
    return _ok({
      'class': {'id': 'c3a', 'name': 'S3 A'},
      'students': [
        {'id': 's1', 'fullName': 'Aline Mukamana'},
        {'id': 's2', 'fullName': 'Eric Habimana'},
        {'id': 's3', 'fullName': 'Grace Uwera'},
      ],
      'subjects': [],
      'access': {'isAdmin': true},
    });
  }

  @override
  Future<http.Response> post(String url, {Object? body, Map<String, String>? headers, bool authenticate = true}) async {
    posted = Map<String, dynamic>.from((body is String ? jsonDecode(body) : body) as Map);
    return _ok({'summary': {'promoted': 3, 'regrouped': 2, 'repeated': 0, 'graduated': 0, 'left': 0, 'classesCreated': 2, 'subjectsCopied': 0, 'classesArchived': 1}});
  }
}

void main() {
  testWidgets('send two students to another stream; the plan carries their moves', (tester) async {
    final api = _Api();
    SchoolService.testClient = api;
    addTearDown(() => SchoolService.testClient = null);
    tester.view.physicalSize = const Size(360, 740) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PromotionScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Students next year'), 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Students next year'));
    await tester.pumpAndSettle();
    expect(find.text('S3 A: next year'), findsOneWidget);

    // Tick Eric and Grace, then "send to…" another stream.
    await tester.tap(find.text('Eric Habimana'));
    await tester.tap(find.text('Grace Uwera'));
    await tester.pump();
    await tester.tap(find.text('2 selected: send to…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Another combination or stream…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to S4 B'));
    await tester.pumpAndSettle();
    expect(find.text('→ S4 B: 2'), findsOneWidget);
    expect(find.text('→ S4 A: 1'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 to other classes'), findsOneWidget);

    await tester.tap(find.text('Start 2027'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new year'));
    // A spinner runs while the result dialog is open: pump a little instead of settling.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.textContaining('(2 to other classes)'), findsOneWidget); // the result dialog

    final plan = (api.posted!['plan'] as List).first as Map;
    final moves = (plan['moves'] as List).map((m) => '${m['studentId']}:${m['toStream']}').toSet();
    expect(moves, {'s2:B', 's3:B'});
    expect(plan['toStream'], 'A');
    expect(tester.takeException(), isNull);
  });
}
