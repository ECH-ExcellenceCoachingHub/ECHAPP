// Desktop opens the email sign-in screen first (no sign-in choice screen),
// so it must offer "School code & PIN" for school students and parents.
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/email_auth_option_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final size in const [Size(1366, 768), Size(390, 844)]) {
    testWidgets('email sign-in screen offers School code & PIN (${size.width.toInt()} px)', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const EmailAuthOptionScreen()),
        GoRoute(path: '/school-sign-in', builder: (_, __) => const Scaffold(body: Text('school sign-in page'))),
      ]);
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pump(const Duration(seconds: 2));

      final option = find.text('School code & PIN');
      expect(option, findsOneWidget);
      await tester.ensureVisible(option);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(option);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('school sign-in page'), findsOneWidget);
    });
  }
}
