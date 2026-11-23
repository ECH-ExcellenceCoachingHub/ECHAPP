import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../services/api/school_service.dart';
import '../../services/api/teacher_tools_service.dart' show saveAndOpenDocument;
import 'school_ui.dart';

/// One printable login card.
class LoginCard {
  const LoginCard({required this.fullName, required this.studentCode, this.pin});
  final String fullName;
  final String studentCode;
  final String? pin;
}

/// A4 sheet of login cards (2 × 5 per page), cut along the dashed lines.
Future<Uint8List> buildLoginCardsPdf({
  required String schoolName,
  required String className,
  required List<LoginCard> cards,
  String mode = 'anywhere',
  bool pinless = false,
}) async {
  final doc = pw.Document(title: 'ECH login cards - $className', author: 'Excellence Coaching Hub');
  const green = PdfColor.fromInt(0xFF047857);
  const grey = PdfColor.fromInt(0xFF6B7280);

  String howTo() {
    if (pinless) return 'Open ECH > School code & PIN > Young pupil. Type the class code your teacher shows, then tap your name.';
    final base = 'Open ECH > School code & PIN > Student. Type your student code and PIN.';
    return mode == 'code' ? '$base At school, also type the class code your teacher shows.' : base;
  }

  String howToRw() {
    if (pinless) return 'Fungura ECH > School code & PIN > Young pupil. Andika kode y\'ishuri mwarimu akwereka, ukande izina ryawe.';
    final base = 'Fungura ECH > School code & PIN > Student. Andika kode yawe na PIN.';
    return mode == 'code' ? '$base Ku ishuri, andika na kode y\'ishuri mwarimu akwereka.' : base;
  }

  pw.Widget card(LoginCard c) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey500, width: 0.6, style: pw.BorderStyle.dashed),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(children: [
            pw.Expanded(child: pw.Text(schoolName, maxLines: 1, style: pw.TextStyle(fontSize: 8, color: grey))),
            pw.Text('ECH', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: green)),
          ]),
          pw.SizedBox(height: 4),
          pw.Text(c.fullName, maxLines: 1, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text(className, style: pw.TextStyle(fontSize: 9, color: grey)),
          pw.SizedBox(height: 8),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Student code', style: pw.TextStyle(fontSize: 7.5, color: grey)),
                pw.Text(c.studentCode, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, font: pw.Font.courierBold())),
              ]),
            ),
            if (c.pin != null)
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('PIN', style: pw.TextStyle(fontSize: 7.5, color: grey)),
                pw.Text(c.pin!, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, font: pw.Font.courierBold())),
              ]),
          ]),
          pw.Spacer(),
          pw.Text(howTo(), style: const pw.TextStyle(fontSize: 6.8)),
          pw.SizedBox(height: 2),
          pw.Text(howToRw(), style: pw.TextStyle(fontSize: 6.8, color: grey)),
          pw.SizedBox(height: 2),
          pw.Text(c.pin != null ? 'Keep your PIN secret. Lost it? Ask your class teacher.' : 'Lost this card? Ask your class teacher.',
              style: pw.TextStyle(fontSize: 6.5, fontStyle: pw.FontStyle.italic, color: grey)),
        ]),
      );

  const perPage = 10;
  for (var i = 0; i < cards.length; i += perPage) {
    final page = cards.sublist(i, (i + perPage).clamp(0, cards.length));
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => pw.Column(children: [
        pw.Row(children: [
          // Plain separators: the built-in PDF font has no long dash.
          pw.Expanded(child: pw.Text([if (schoolName.isNotEmpty) schoolName, className, 'login cards'].join('  |  '), style: pw.TextStyle(fontSize: 9, color: grey))),
          pw.Text('Page ${i ~/ perPage + 1} of ${(cards.length / perPage).ceil()}', style: pw.TextStyle(fontSize: 9, color: grey)),
        ]),
        pw.SizedBox(height: 8),
        // Fixed-size cards from the top-left (2 columns x 5 rows on A4).
        pw.Wrap(
          children: [
            for (final c in page)
              pw.SizedBox(
                width: (PdfPageFormat.a4.width - 48) / 2,
                height: (PdfPageFormat.a4.height - 48 - 24) / 5,
                child: card(c),
              ),
          ],
        ),
      ]),
    ));
  }
  return doc.save();
}

/// Asks to confirm, creates new PINs for the class and opens the PDF.
Future<void> printClassLoginCards(BuildContext context, SchoolService svc, {required String classId, required String className, List<String>? studentIds}) async {
  final ok = await confirm(
    context,
    title: 'Print login cards for $className?',
    message: 'ECH creates NEW PINs for ${studentIds == null ? 'every student of the class' : 'the chosen students'}. Old cards and PINs stop working, and students are signed out. Hand out the new cards right after printing.',
    confirmLabel: 'Create cards',
  );
  if (!ok || !context.mounted) return;
  try {
    final r = await svc.loginCards(classId, studentIds: studentIds);
    final cards = SchoolService.list(r['cards']).map((c) => LoginCard(fullName: '${c['fullName']}', studentCode: '${c['studentCode']}', pin: c['pin'] as String?)).toList();
    final bytes = await buildLoginCardsPdf(
      schoolName: '${r['schoolName'] ?? ''}',
      className: '${r['className'] ?? className}',
      cards: cards,
      mode: '${r['mode'] ?? 'anywhere'}',
      pinless: r['pinless'] == true,
    );
    final where = await saveAndOpenDocument(bytes, 'login-cards-${className.replaceAll(' ', '-')}.pdf');
    if (context.mounted) showSnack(context, where == null ? '${cards.length} login cards downloaded' : '${cards.length} login cards saved to $where');
  } catch (e) {
    if (context.mounted) showSnack(context, e.toString(), error: true);
  }
}
