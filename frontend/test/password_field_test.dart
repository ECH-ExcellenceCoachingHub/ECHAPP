import 'package:excellencecoachinghub/widgets/forms/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));

void main() {
  testWidgets('password is hidden until the eye is tapped', (tester) async {
    final c = TextEditingController(text: 'Secret123!');
    await tester.pumpWidget(_wrap(PasswordField(controller: c)));
    EditableText field() => tester.widget<EditableText>(find.byType(EditableText));
    expect(field().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(field().obscureText, isFalse);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(field().obscureText, isTrue);
  });

  testWidgets('generate fills a strong password and shows it', (tester) async {
    final c = TextEditingController();
    await tester.pumpWidget(_wrap(PasswordField(controller: c, showGenerate: true)));
    await tester.tap(find.byIcon(Icons.auto_fix_high_outlined));
    await tester.pump();
    expect(c.text.length, 12);
    expect(RegExp(r'[A-Z]').hasMatch(c.text) && RegExp(r'[a-z]').hasMatch(c.text) && RegExp(r'\d').hasMatch(c.text), isTrue);
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText, isFalse);
  });

  testWidgets('PIN field accepts 6 digits only', (tester) async {
    final c = TextEditingController();
    await tester.pumpWidget(_wrap(PasswordField.pin(controller: c)));
    await tester.enterText(find.byType(TextFormField), '12ab345678');
    expect(c.text, '123456');
  });
}
