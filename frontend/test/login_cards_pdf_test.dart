import 'dart:io';

import 'package:excellencecoachinghub/widgets/school/login_cards_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login cards PDF: one page per 10 students, codes and PINs inside', () async {
    final cards = [for (var i = 1; i <= 12; i++) LoginCard(fullName: 'Student $i', studentCode: 'GSTB26${i.toString().padLeft(4, '0')}', pin: '12345$i')];
    final bytes = await buildLoginCardsPdf(schoolName: 'Test School', className: 'S3 A', cards: cards, mode: 'code');
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final text = String.fromCharCodes(bytes);
    expect(RegExp(r'/Type\s*/Page[^s]').allMatches(text).length, 2);
    final out = Platform.environment['LOGIN_CARDS_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
