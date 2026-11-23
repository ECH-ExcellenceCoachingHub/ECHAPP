import 'package:excellencecoachinghub/widgets/school/combinations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog: new REB streams, old combinations and TVET trades, no duplicate codes', () {
    final codes = [for (final g in combinationGroups) for (final c in g.items) c.code];
    expect(codes.toSet().length, codes.length);
    expect(codes, containsAll(['MS-PURE', 'MS-APPLIED', 'ARTS-HUM', 'LANGUAGES', 'MPC', 'PCB', 'SOD', 'NIT', 'BDC']));
    // Codes become part of class names: short, uppercase, server limit 20.
    for (final c in codes) {
      expect(c.length <= 20 && c == c.toUpperCase() && !c.contains(' '), isTrue, reason: c);
    }
    expect(combinationName('ms-pure'), 'Mathematics & Sciences: Pure Sciences');
  });

  testWidgets('picker: search filters, TVET first for L levels, single choice returns the code', (tester) async {
    Set<String>? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await showCombinationPicker(context, level: 'L4'),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // TVET groups come before the REB streams for an L4 class.
    final tvetY = tester.getTopLeft(find.text('TVET: ICT & multimedia')).dy;
    expect(find.text('New REB streams'), findsNothing); // below the fold, not built yet
    expect(tvetY, greaterThan(0));

    await tester.enterText(find.byType(TextField), 'software');
    await tester.pumpAndSettle();
    expect(find.text('Software Development'), findsOneWidget);
    expect(find.text('Physics, Chemistry, Biology'), findsNothing);
    await tester.tap(find.text('Software Development'));
    await tester.pumpAndSettle();
    expect(result, {'SOD'});
  });
}
