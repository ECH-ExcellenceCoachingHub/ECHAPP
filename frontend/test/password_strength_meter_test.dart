import 'package:excellencecoachinghub/presentation/widgets/password_strength_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('score grows with each rule', () {
    expect(PasswordStrengthMeter.score(''), 0);
    expect(PasswordStrengthMeter.score('abc'), 1);
    expect(PasswordStrengthMeter.score('abcdef'), 2);
    expect(PasswordStrengthMeter.score('Abcdefgh1!'), 5);
  });

  testWidgets('shows the missing rule and match state on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final pw = TextEditingController();
    final cf = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          PasswordStrengthMeter(controller: pw),
          PasswordMatchHint(password: pw, confirm: cf),
        ]),
      ),
    ));
    pw.text = 'abc';
    await tester.pump();
    expect(find.text('Too short'), findsOneWidget);
    expect(find.text('At least 6 characters (required)'), findsOneWidget);
    pw.text = 'Abcdefgh1!';
    cf.text = 'Abcdefgh1';
    await tester.pump();
    expect(find.text('Strong'), findsOneWidget);
    expect(find.text("Passwords don't match yet"), findsOneWidget);
    cf.text = 'Abcdefgh1!';
    await tester.pump();
    expect(find.text('Passwords match'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
