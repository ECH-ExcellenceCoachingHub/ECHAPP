import 'package:excellencecoachinghub/widgets/school/school_i18n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _inLocale(String code, Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: Localizations(locale: Locale(code), delegates: const [DefaultWidgetsLocalizations.delegate], child: child),
    );

void main() {
  testWidgets('school text is Kinyarwanda in rw and English otherwise', (tester) async {
    await tester.pumpWidget(_inLocale('rw', const Column(children: [T('Homework & work to do'), T('Due tomorrow'), T('Something not translated')])));
    expect(find.text("Umukoro n'imirimo yo gukora"), findsOneWidget);
    expect(find.text('Igihe ntarengwa: ejo'), findsOneWidget); // pattern + translated part
    expect(find.text('Something not translated'), findsOneWidget); // falls back to English

    // Patterns never swallow a whole composite line.
    const line = 'Jean Bosco Habimana · 4 lessons taught, last 2 days ago';
    await tester.pumpWidget(_inLocale('rw', const T(line)));
    expect(find.text(line), findsOneWidget);
    await tester.pumpWidget(_inLocale('rw', const T('2 days ago')));
    expect(find.text('hashize iminsi 2'), findsOneWidget);

    await tester.pumpWidget(_inLocale('en', const T('Homework & work to do')));
    expect(find.text('Homework & work to do'), findsOneWidget);
  });
}
