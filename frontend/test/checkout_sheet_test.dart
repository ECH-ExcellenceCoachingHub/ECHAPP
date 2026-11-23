import 'package:excellencecoachinghub/services/api/checkout_service.dart';
import 'package:excellencecoachinghub/widgets/payments/checkout_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake gateway: the payment stays pending for [pendingPolls] polls, then ends as [finalStatus].
class FakeCheckout extends CheckoutService {
  FakeCheckout({this.pendingPolls = 1, this.finalStatus = 'completed'});
  final int pendingPolls;
  final String finalStatus;
  int polls = 0;
  Map<String, String?>? started;

  CheckoutState _s(String status) => CheckoutState(
        reference: 'ref-1',
        status: status,
        amount: 8000,
        paymentMethod: started?['method'] ?? 'mtn_momo',
        phone: started?['phone'],
        message: status == 'failed' ? 'The payment was declined or cancelled on the phone. You were not charged.' : null,
      );

  @override
  Future<List<PaymentMethodOption>> methods() async => PaymentMethodOption.defaults;

  @override
  Future<CheckoutState> start(CheckoutItem item, {required String method, String? phone, String? email}) async {
    started = {'method': method, 'phone': phone, 'email': email, 'purpose': item.purpose};
    return _s('pending');
  }

  @override
  Future<CheckoutState> status(String reference) async {
    polls++;
    return _s(polls > pendingPolls ? finalStatus : 'pending');
  }
}

Widget host(FakeCheckout svc, void Function(CheckoutState?) onResult) => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => onResult(await showCheckoutSheet(
                context,
                item: const CheckoutItem.course('c1'),
                title: 'Chemistry S4',
                amount: 8000,
                defaultPhone: '0731234567',
                service: svc,
              )),
              child: const Text('Buy'),
            ),
          ),
        ),
      ),
    );

void main() {
  test('methodForPhone and formatRwf', () {
    expect(methodForPhone('0788123456'), 'mtn_momo');
    expect(methodForPhone('+250 731 234 567'), 'airtel_money');
    expect(methodForPhone('0712'), isNull);
    expect(formatRwf(1234567), 'RWF 1,234,567');
  });

  testWidgets('pays with the phone network picked from the number, waits, then shows success', (tester) async {
    final svc = FakeCheckout(pendingPolls: 1);
    CheckoutState? result;
    await tester.pumpWidget(host(svc, (r) => result = r));
    await tester.tap(find.text('Buy'));
    await tester.pumpAndSettle();

    expect(find.text('Airtel Money number'), findsOneWidget, reason: '073 → Airtel picked automatically');
    await tester.tap(find.text('Pay RWF 8,000'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(svc.started, {'method': 'airtel_money', 'phone': '0731234567', 'email': null, 'purpose': 'course'});
    expect(find.text('Check your phone'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // poll 1: pending
    await tester.pump(const Duration(seconds: 4)); // poll 2: paid
    await tester.pumpAndSettle();
    expect(find.text('Payment received'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(result?.isPaid, isTrue);
  });

  testWidgets('a declined payment offers Try again', (tester) async {
    final svc = FakeCheckout(pendingPolls: 0, finalStatus: 'failed');
    await tester.pumpWidget(host(svc, (_) {}));
    await tester.tap(find.text('Buy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MTN MoMo'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '0788123456');
    await tester.tap(find.text('Pay RWF 8,000'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Payment did not go through'), findsOneWidget);
    expect(find.textContaining('You were not charged'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Pay RWF 8,000'), findsOneWidget);
  });
}
