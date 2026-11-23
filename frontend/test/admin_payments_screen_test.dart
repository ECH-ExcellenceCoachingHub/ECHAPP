// Super-admin payments screen at phone, tablet and desktop widths, with fake data.
// Screenshots: flutter test test/admin_payments_screen_test.dart --dart-define=SHOTS_DIR=C:/path/to/dir
import 'dart:io';
import 'dart:ui' as ui;

import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/payment.dart';
import 'package:excellencecoachinghub/models/payment_status.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/payment_management_screen_riverpod.dart';
import 'package:excellencecoachinghub/services/api/admin_payments_service.dart';
import 'package:excellencecoachinghub/services/api/checkout_service.dart';
import 'package:excellencecoachinghub/services/api/payment_api_service.dart';
import 'package:excellencecoachinghub/services/infrastructure/api_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _shotsDir = String.fromEnvironment('SHOTS_DIR');

Map<String, dynamic> _p(
  String id, {
  required String name,
  required num amount,
  String status = 'completed',
  String purpose = 'course',
  String method = 'mtn_momo',
  bool online = true,
  String? failure,
  int minutesAgo = 5,
}) =>
    {
      '_id': id,
      'userId': {'_id': 'u$id', 'fullName': name, 'email': '${name.split(' ').first.toLowerCase()}@mail.rw', 'phone': '0788123456'},
      if (purpose != 'school_term') 'courseId': {'_id': 'c$id', 'title': purpose == 'teacher_guide' ? 'Biology S2' : 'Chemistry for S4 — Organic basics', 'price': amount},
      if (purpose == 'school_term') 'schoolId': {'_id': 's1', 'name': 'Lycée de Kigali'},
      if (purpose == 'school_term') 'termId': {'_id': 't1', 'academicYear': '2026', 'term': 3},
      if (purpose == 'school_term') 'seats': 120,
      'amount': amount,
      'currency': 'RWF',
      'paymentMethod': method,
      'transactionId': 'ITP17${id}ABC',
      'status': status,
      'purpose': purpose,
      'contactInfo': '0788123456',
      if (online) 'gateway': {'provider': 'itecpay', 'reference': '5f1c-$id-9a2b', 'lastStatus': status == 'completed' ? 'successful' : 'pending', 'failureReason': failure},
      'createdAt': DateTime.now().subtract(Duration(minutes: minutesAgo)).toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

final _all = [
  _p('1', name: 'Alice Uwase', amount: 8000),
  _p('2', name: 'Jean Bosco Habimana', amount: 5000, status: 'pending', online: false, minutesAgo: 90),
  _p('3', name: 'Head Teacher GSK', amount: 180000, status: 'admin_review', purpose: 'school_term', method: 'card', failure: 'iTechPay reports RWF 100000, expected RWF 180000'),
  _p('4', name: 'Teacher Claudine', amount: 3000, purpose: 'teacher_guide', method: 'airtel_money'),
  _p('5', name: 'Eric Mugisha', amount: 8000, status: 'failed', failure: 'declined', minutesAgo: 300),
  _p('6', name: 'Grace Ingabire', amount: 8000, status: 'pending', minutesAgo: 2),
  _p('7', name: 'Patrick N.', amount: 12000, status: 'approved', online: false, method: 'mtn_momo', minutesAgo: 3000),
];

class FakeAdminPayments extends AdminPaymentsService {
  final queries = <Map<String, String>>[];

  @override
  Future<AdminPaymentsPage> list(AdminPaymentsQuery q, {int page = 1, int limit = 25}) async {
    final params = q.toParams();
    queries.add(params);
    var items = _all.map(Payment.fromJson).toList();
    if (q.purpose != null) items = items.where((p) => (p.purpose) == q.purpose).toList();
    if (q.attention) items = items.where((p) => p.status == PaymentStatus.adminReview || (p.status == PaymentStatus.pending && !p.isOnline)).toList();
    if (q.status != null) items = items.where((p) => q.status!.split(',').contains(p.status.value)).toList();
    return AdminPaymentsPage(items, items.length, 1, 1);
  }

  @override
  Future<PaymentsOverview> overview() async => PaymentsOverview.fromJson({
        'total': {'revenue': 2450000, 'count': 214},
        'thisMonth': {'revenue': 640000, 'count': 52},
        'lastMonth': {'revenue': 520000, 'count': 47},
        'byPurpose': {
          'course': {'revenue': 1380000, 'count': 160},
          'teacher_guide': {'revenue': 270000, 'count': 40},
          'school_term': {'revenue': 800000, 'count': 14},
        },
        'byMethod': {
          'mtn_momo': {'revenue': 1500000, 'count': 150},
          'airtel_money': {'revenue': 450000, 'count': 50},
          'card': {'revenue': 500000, 'count': 14},
        },
        'byChannel': {'online': {'revenue': 1800000, 'count': 150}, 'manual': {'revenue': 650000, 'count': 64}},
        'statusCounts': {'completed': 150, 'approved': 64, 'pending': 9, 'admin_review': 1, 'failed': 12, 'cancelled': 6},
        'needsAttention': 2,
        'daily': [
          for (var i = 0; i < 30; i++)
            {
              'date': DateTime.now().subtract(Duration(days: 29 - i)).toIso8601String().substring(0, 10),
              'revenue': i % 6 == 0 ? 0 : (i * 7919 % 50) * 1000,
              'count': i % 6 == 0 ? 0 : 1 + i % 4,
            },
        ],
        'online30': {'started': 60, 'notPaid': 8},
      });
}

/// An older server: no /payments/admin/overview (falls into /:id → 500), only /payments/stats.
class OldServerApi extends ApiClient {
  @override
  Future<http.Response> get(String url, {Map<String, String>? headers, Map<String, dynamic>? queryParams, bool authenticate = true}) async {
    if (url.endsWith('/payments/stats')) {
      return http.Response(jsonEncode({'success': true, 'data': {
        'totalPayments': 20, 'pendingPayments': 3, 'adminReviewPayments': 1, 'approvedPayments': 10,
        'completedPayments': 4, 'failedPayments': 1, 'cancelledPayments': 1, 'totalRevenue': 98000, 'recentPayments': [],
      }}), 200);
    }
    return http.Response(jsonEncode({'success': false, 'message': 'Failed to retrieve payment'}), 500);
  }
}

class BrokenOverview extends FakeAdminPayments {
  @override
  Future<PaymentsOverview> overview() async => throw Exception('Server unreachable');
}

class FakeCheckout extends CheckoutService {
  final rechecked = <String>[];
  @override
  Future<CheckoutState> recheck(String paymentId) async {
    rechecked.add(paymentId);
    return const CheckoutState(reference: 'r', status: 'completed', amount: 8000, paymentMethod: 'mtn_momo');
  }
}

class FakePaymentApi extends PaymentApiService {
  final verified = <String>[];
  @override
  Future<PaymentVerificationResponse> verifyPayment({required String paymentId, required PaymentStatus status, String? adminNotes}) async {
    verified.add('$paymentId:${status.value}');
    throw Exception('stop'); // the screen shows the error; we only check the call
  }
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
  await family('FlutterTest', ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']);
  await family('MaterialIcons', ['materialicons-regular.otf']);
}

final _shotKey = GlobalKey();

Future<void> _pumpScreen(WidgetTester tester, Size size, {FakeAdminPayments? svc, FakeCheckout? checkout, FakePaymentApi? api, bool dark = false}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme.copyWith(textTheme: theme.textTheme.apply(fontFamily: 'Roboto')),
    home: RepaintBoundary(
      key: _shotKey,
      child: PaymentManagementScreen(service: svc ?? FakeAdminPayments(), checkout: checkout ?? FakeCheckout(), paymentApi: api ?? FakePaymentApi()),
    ),
  ));
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (_shotsDir.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_shotsDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(_loadFonts);

  for (final (name, size) in const [('phone', Size(390, 3000)), ('small_phone', Size(360, 3000)), ('tablet', Size(820, 2600)), ('desktop', Size(1440, 1500))]) {
    testWidgets('renders without overflow on $name', (tester) async {
      await _pumpScreen(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.text('Payments'), findsWidgets);
      expect(find.text('Alice Uwase'), findsOneWidget);
      expect(find.textContaining('need your attention'), findsOneWidget);
      expect(find.text('Lycée de Kigali · 2026 Term 3'), findsOneWidget);
      expect(find.text('Needs review'), findsWidgets);
      expect(find.text('Declined'), findsOneWidget);
      await _shot(tester, 'payments_$name');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('dark mode desktop', (tester) async {
    await _pumpScreen(tester, const Size(1440, 1500), dark: true);
    expect(tester.takeException(), isNull);
    await _shot(tester, 'payments_desktop_dark');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('filters go to the server; attention banner filters; details + recheck', (tester) async {
    final svc = FakeAdminPayments();
    final checkout = FakeCheckout();
    await _pumpScreen(tester, const Size(1440, 1500), svc: svc, checkout: checkout);

    await tester.tap(find.text('School term').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(svc.queries.last['purpose'], 'school_term');

    await tester.tap(find.textContaining('need your attention'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(svc.queries.last, {'attention': '1'});
    expect(find.text('Alice Uwase'), findsNothing);
    expect(find.text('Jean Bosco Habimana'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Grace');
    await tester.pump(const Duration(milliseconds: 500));
    expect(svc.queries.last['search'], 'Grace');

    await tester.tap(find.text('Clear filters'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(svc.queries.last, isEmpty);

    // Open the declined online payment and ask iTechPay again.
    await tester.tap(find.text('Eric Mugisha'));
    await tester.pumpAndSettle();
    expect(find.text('iTechPay reference'), findsOneWidget);
    await _shot(tester, 'payments_details');
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Check with iTechPay')));
    await tester.pumpAndSettle();
    expect(checkout.rechecked, ['5']);
    expect(find.textContaining('iTechPay confirmed it'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('approving an unconfirmed online payment warns first (phone)', (tester) async {
    final api = FakePaymentApi();
    await _pumpScreen(tester, const Size(390, 3000), api: api);
    await tester.tap(find.text('Grace Ingabire'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Approve'));
    await tester.pumpAndSettle();
    expect(find.textContaining('iTechPay has not confirmed this payment'), findsOneWidget);
    await _shot(tester, 'payments_approve_dialog');
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();
    expect(api.verified, ['6:approved']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('overview falls back to /payments/stats on a server without the new endpoint', () async {
    final o = await AdminPaymentsService(apiClient: OldServerApi()).overview();
    expect(o.partial, isTrue);
    expect(o.total.revenue, 98000);
    expect(o.total.count, 14);
    expect(o.needsAttention, 4);
  });

  testWidgets('a failed summary shows the error and a retry, not endless placeholders', (tester) async {
    await _pumpScreen(tester, const Size(1440, 1500), svc: BrokenOverview());
    expect(tester.takeException(), isNull);
    expect(find.textContaining('could not be loaded: Server unreachable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(4));
    expect(find.text('Alice Uwase'), findsOneWidget, reason: 'the list still works');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
