import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../services/api/school_service.dart';
import '../../services/api/teacher_tools_service.dart' show saveAndOpenDocument;
import 'school_ui.dart';

/// Printable reports: one student, one class, or the whole school.
/// The data comes ready from the API (studentReport / classReport / schoolReport).

const _green = PdfColor.fromInt(0xFF047857);
const _grey = PdfColor.fromInt(0xFF6B7280);
const _light = PdfColor.fromInt(0xFFF1F5F9);
const _red = PdfColor.fromInt(0xFFB91C1C);
const _amber = PdfColor.fromInt(0xFFB45309);

/// The built-in PDF font only knows Latin-1: swap common symbols, drop the rest.
String _s(dynamic v) {
  if (v == null) return '';
  final t = '$v'
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('·', '|')
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('…', '...');
  return String.fromCharCodes(t.runes.where((r) => r == 10 || (r >= 32 && r <= 255)));
}

String _d(dynamic v) {
  final d = parseDate(v);
  return d == null ? '-' : DateFormat('d MMM yyyy').format(d);
}

String _pct(dynamic v) => v == null ? '-' : '${(v as num).round()}%';

PdfColor? _toneOf(dynamic v) {
  if (v == null) return null;
  final n = (v as num).toDouble();
  return n >= 70 ? _green : n >= 50 ? _amber : _red;
}

String _gender(dynamic g) => g == 'female' ? 'F' : g == 'male' ? 'M' : g == 'other' ? 'Other' : '-';

String _address(dynamic a) {
  if (a is! Map) return '-';
  final parts = ['village', 'cell', 'sector', 'district', 'province'].map((k) => '${a[k] ?? ''}'.trim()).where((e) => e.isNotEmpty).toList();
  return parts.isEmpty ? '-' : parts.join(', ');
}

String _stateLabel(String? s) => switch (s) {
      'graded' => 'Marked',
      'submitted' => 'Handed in',
      'missing' => 'Not handed in',
      'pending' => 'Not due yet',
      'no_hand_in' => 'No hand-in',
      _ => s ?? '-',
    };

pw.Widget _header(Map school, String title, String subtitle, dynamic generatedAt) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _green, width: 1.5))),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(_s(school['name']), style: pw.TextStyle(fontSize: 10, color: _grey)),
            pw.SizedBox(height: 2),
            pw.Text(_s(title), style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
            if (subtitle.isNotEmpty) pw.Text(_s(subtitle), style: const pw.TextStyle(fontSize: 10, color: _grey)),
          ]),
        ),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('ECH', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _green)),
          pw.Text('Printed ${_d(generatedAt ?? DateTime.now())}', style: const pw.TextStyle(fontSize: 8, color: _grey)),
        ]),
      ]),
    );

pw.Widget _footer(pw.Context ctx, String label) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(children: [
        pw.Expanded(child: pw.Text(_s(label), style: const pw.TextStyle(fontSize: 8, color: _grey))),
        pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _grey)),
      ]),
    );

pw.Widget _section(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 5),
      child: pw.Text(_s(title), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _green)),
    );

pw.Widget _note(String text) => pw.Text(_s(text), style: pw.TextStyle(fontSize: 9, color: _grey, fontStyle: pw.FontStyle.italic));

/// A row of boxed numbers.
pw.Widget _stats(List<(String, String, PdfColor?)> items) => pw.Row(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            decoration: pw.BoxDecoration(color: _light, borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(_s(items[i].$2), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: items[i].$3 ?? PdfColors.black)),
              pw.Text(_s(items[i].$1), style: const pw.TextStyle(fontSize: 8, color: _grey)),
            ]),
          ),
        ),
      ],
    ]);

/// Two-column "label: value" grid.
pw.Widget _facts(List<(String, String)> rows) {
  final half = (rows.length / 2).ceil();
  pw.Widget col(List<(String, String)> list) => pw.Column(children: [
        for (final r in list)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.SizedBox(width: 82, child: pw.Text(_s(r.$1), style: const pw.TextStyle(fontSize: 9, color: _grey))),
              pw.Expanded(child: pw.Text(_s(r.$2.isEmpty ? '-' : r.$2), style: const pw.TextStyle(fontSize: 9.5))),
            ]),
          ),
      ]);
  return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Expanded(child: col(rows.sublist(0, half))),
    pw.SizedBox(width: 16),
    pw.Expanded(child: col(rows.sublist(half))),
  ]);
}

/// Table with a green header; [colors] can colour single cells (row, col) e.g. marks.
pw.Widget _table(List<String> headers, List<List<String>> rows, {Map<int, pw.TableColumnWidth>? widths, Set<int> right = const {}, PdfColor? Function(int row, int col)? color, double fontSize = 8.5}) {
  return pw.Table(
    border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5), bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
    columnWidths: widths,
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _green),
        repeat: true,
        children: [
          for (var c = 0; c < headers.length; c++)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: pw.Text(_s(headers[c]), textAlign: right.contains(c) ? pw.TextAlign.right : pw.TextAlign.left, style: pw.TextStyle(fontSize: fontSize, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ),
        ],
      ),
      for (var r = 0; r < rows.length; r++)
        pw.TableRow(
          decoration: r.isOdd ? const pw.BoxDecoration(color: _light) : null,
          children: [
            for (var c = 0; c < rows[r].length; c++)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: pw.Text(_s(rows[r][c]), textAlign: right.contains(c) ? pw.TextAlign.right : pw.TextAlign.left, style: pw.TextStyle(fontSize: fontSize, color: color?.call(r, c))),
              ),
          ],
        ),
    ],
  );
}

// ── One student ──────────────────────────────────────────────────────────

Future<Uint8List> buildStudentReportPdf(Map<String, dynamic> d) async {
  final school = Map<String, dynamic>.from(d['school'] as Map? ?? {});
  final st = Map<String, dynamic>.from(d['student'] as Map? ?? {});
  final cls = d['classroom'] as Map?;
  final stats = Map<String, dynamic>.from(d['stats'] as Map? ?? {});
  final subjects = SchoolService.list(d['subjects']);
  final work = SchoolService.list(d['assessments']);
  final exams = SchoolService.list(d['exams']);
  final guardians = SchoolService.list(st['guardians']);
  final doc = pw.Document(title: _s('Student report - ${st['fullName']}'), author: 'Excellence Coaching Hub');

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 24),
    header: (ctx) => ctx.pageNumber == 1 ? pw.SizedBox() : pw.Text(_s('${st['fullName']} | ${cls?['name'] ?? ''}'), style: const pw.TextStyle(fontSize: 8, color: _grey)),
    footer: (ctx) => _footer(ctx, '${school['name'] ?? ''} | Student report | ${st['fullName']}'),
    build: (ctx) => [
      _header(school, '${st['fullName']}', ['Student report', if (cls != null) '${cls['name']}', if (cls?['academicYear'] != null) 'Year ${cls!['academicYear']}'].join('  |  '), d['generatedAt']),
      _facts([
        ('Student code', '${st['studentCode'] ?? ''}'),
        ('Class', '${cls?['name'] ?? 'No class'}'),
        ('Gender', _gender(st['gender']) == '-' ? '' : (st['gender'] == 'female' ? 'Female' : st['gender'] == 'male' ? 'Male' : 'Other')),
        ('Date of birth', st['dateOfBirth'] == null ? '' : _d(st['dateOfBirth'])),
        ('Class teacher', '${cls?['classTeacher']?['fullName'] ?? ''}'),
        ('Status', st['isActive'] == false ? 'Removed from school' : 'Active'),
        ('Home address', _address(st['address']) == '-' ? '' : _address(st['address'])),
        ('Last seen on ECH', st['lastActive'] == null ? 'Never' : _d(st['lastActive'])),
        ('Registered', _d(st['createdAt'])),
        if ('${st['phone'] ?? ''}'.isNotEmpty) ('Phone', '${st['phone']}'),
      ]),
      _section('Parents and guardians'),
      if (guardians.isEmpty)
        _note('No parent or guardian recorded.')
      else
        _table(['Name', 'Relationship', 'Phone', 'ECH parent account'], [
          for (final g in guardians) ['${g['name'] ?? ''}', '${g['relationship'] ?? ''}', '${g['phone'] ?? ''}', g['hasAccount'] == true ? 'Yes' : 'No'],
        ]),
      _section('Summary'),
      _stats([
        ('Overall average', _pct(stats['average']), _toneOf(stats['average'])),
        ('Hand-in rate', _pct(stats['handInRate']), _toneOf(stats['handInRate'])),
        ('Handed in', '${stats['handedIn'] ?? 0} / ${stats['expected'] ?? 0}', null),
        ('Not handed in', '${stats['missing'] ?? 0}', (stats['missing'] ?? 0) > 0 ? _red : null),
        ('eexams average', _pct(stats['examAverage']), _toneOf(stats['examAverage'])),
      ]),
      _section('Subjects'),
      if (subjects.isEmpty)
        _note('The class has no subjects yet.')
      else
        _table(
          ['Subject', 'Teacher', 'Lessons taught', 'Average'],
          [
            for (final s in subjects)
              ['${s['subject']}', '${s['teacher']?['fullName'] ?? '-'}', s['syllabusLessons'] != null && s['syllabusLessons'] > 0 ? '${s['lessonsTaught']} of ${s['syllabusLessons']}' : '${s['lessonsTaught'] ?? 0}', _pct(s['average'])],
          ],
          right: {2, 3},
          color: (r, c) => c == 3 ? _toneOf(subjects[r]['average']) : null,
        ),
      _section('Homework, quizzes and tests'),
      if (work.isEmpty)
        _note('Nothing given yet.')
      else
        _table(
          ['Due', 'Subject', 'Title', 'Type', 'Status', 'Mark'],
          [
            for (final a in work)
              [
                _d(a['dueAt']),
                '${a['subject'] ?? ''}',
                '${a['title'] ?? ''}',
                '${a['type'] ?? ''}',
                '${_stateLabel(a['state'] as String?)}${a['isLate'] == true ? ' (late)' : ''}',
                a['score'] != null ? '${a['score']}/${a['maxScore']} (${a['percent']}%)' : '-',
              ],
          ],
          widths: {0: const pw.FixedColumnWidth(58), 1: const pw.FlexColumnWidth(1.3), 2: const pw.FlexColumnWidth(2.6), 3: const pw.FixedColumnWidth(48), 4: const pw.FlexColumnWidth(1.3), 5: const pw.FixedColumnWidth(66)},
          right: {5},
          color: (r, c) => c == 4 && work[r]['state'] == 'missing' ? _red : c == 5 ? _toneOf(work[r]['percent']) : null,
        ),
      _section('eexams results'),
      if (exams.isEmpty)
        _note('No eexams results yet.')
      else
        _table(
          ['Date', 'Exam', 'Score', 'Result'],
          [for (final e in exams) [_d(e['completedAt']), '${e['title'] ?? ''}', '${e['score'] ?? ''}/${e['maxScore'] ?? ''}', _pct(e['percentage'])]],
          right: {2, 3},
          color: (r, c) => c == 3 ? _toneOf(exams[r]['percentage']) : null,
        ),
      pw.SizedBox(height: 18),
      _note('Averages use marked homework, quizzes and class tests. eexams results are listed separately.'),
      pw.SizedBox(height: 28),
      pw.Row(children: [
        pw.Expanded(child: _signLine('Class teacher')),
        pw.SizedBox(width: 30),
        pw.Expanded(child: _signLine('Head teacher')),
        pw.SizedBox(width: 30),
        pw.Expanded(child: _signLine('Parent / guardian')),
      ]),
    ],
  ));
  return doc.save();
}

pw.Widget _signLine(String who) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Container(height: 0.6, color: PdfColors.grey600),
      pw.SizedBox(height: 3),
      pw.Text(who, style: const pw.TextStyle(fontSize: 8, color: _grey)),
    ]);

// ── One class (also used for each class in the school report) ──────────

List<pw.Widget> _classBody(Map<String, dynamic> c, {bool showHeaderFacts = true}) {
  final cls = Map<String, dynamic>.from(c['class'] as Map? ?? {});
  final sum = Map<String, dynamic>.from(c['summary'] as Map? ?? {});
  final subjects = SchoolService.list(c['subjects']);
  final students = SchoolService.list(c['students']);
  final genders = Map<String, dynamic>.from(sum['genders'] as Map? ?? {});
  final atRisk = SchoolService.list(sum['atRisk']);
  final missing = SchoolService.list(sum['mostMissing']);
  // Abbreviate subject headers so many subjects still fit on the page.
  String short(String s) => s.length <= 9 ? s : '${s.substring(0, 8)}.';
  final subjNames = subjects.map((s) => '${s['subject']}').toList();

  return [
    if (showHeaderFacts)
      _facts([
        ('Class teacher', '${cls['classTeacher']?['fullName'] ?? 'Not set'}'),
        ('Academic year', '${cls['academicYear'] ?? ''}'),
        ('Students', '${sum['studentCount'] ?? students.length}  (F ${genders['female'] ?? 0}, M ${genders['male'] ?? 0})'),
        ('Parents on ECH', '${sum['withParentAccount'] ?? 0} of ${sum['studentCount'] ?? students.length}'),
      ]),
    pw.SizedBox(height: 6),
    _stats([
      ('Class average', _pct(sum['classAverage']), _toneOf(sum['classAverage'])),
      ('Hand-in rate', _pct(sum['handInRate']), _toneOf(sum['handInRate'])),
      ('eexams average', _pct(sum['examAverage']), _toneOf(sum['examAverage'])),
      ('Work given', '${sum['assessmentsGiven'] ?? 0}', null),
      ('Below 50%', '${atRisk.length}', atRisk.isEmpty ? _green : _red),
    ]),
    _section('Subjects'),
    if (subjects.isEmpty)
      _note('No subjects yet.')
    else
      _table(
        ['Subject', 'Teacher', 'Lessons taught', 'Syllabus covered', 'Class average'],
        [
          for (final s in subjects)
            ['${s['subject']}', '${s['teacher']?['fullName'] ?? 'No teacher'}', '${s['lessonsTaught'] ?? 0}', _pct(s['coveragePercent']), _pct(s['average'])],
        ],
        right: {2, 3, 4},
        color: (r, col) => col == 4 ? _toneOf(subjects[r]['average']) : null,
      ),
    _section('Students'),
    if (students.isEmpty)
      _note('No students in this class.')
    else
      _table(
        ['#', 'Name', 'Code', 'Sex', for (final s in subjNames) short(s), 'Avg', 'Pos', 'Handed in', 'Missing', 'eexams', 'Parent phone'],
        [
          for (var i = 0; i < students.length; i++)
            [
              '${i + 1}',
              '${students[i]['fullName']}',
              '${students[i]['studentCode'] ?? ''}',
              _gender(students[i]['gender']),
              for (final s in subjNames) _pct((students[i]['bySubject'] as Map?)?[s]),
              _pct(students[i]['stats']?['average']),
              '${students[i]['position'] ?? '-'}',
              '${students[i]['stats']?['handedIn'] ?? 0}/${students[i]['stats']?['expected'] ?? 0}',
              '${students[i]['stats']?['missing'] ?? 0}',
              _pct(students[i]['stats']?['examAverage']),
              () {
                final g = SchoolService.list(students[i]['guardians']);
                return g.isEmpty ? '' : '${g.first['phone'] ?? ''}';
              }(),
            ],
        ],
        fontSize: subjNames.length > 8 ? 7 : 8,
        widths: {0: const pw.FixedColumnWidth(18), 1: const pw.FlexColumnWidth(3), 2: const pw.FlexColumnWidth(1.6)},
        right: {for (var i = 4; i < 4 + subjNames.length + 5; i++) i},
        color: (r, col) {
          if (col >= 4 && col < 4 + subjNames.length) return _toneOf((students[r]['bySubject'] as Map?)?[subjNames[col - 4]]);
          if (col == 4 + subjNames.length) return _toneOf(students[r]['stats']?['average']);
          if (col == 4 + subjNames.length + 3 && (students[r]['stats']?['missing'] ?? 0) > 0) return _red;
          return null;
        },
      ),
    if (students.isNotEmpty && subjNames.any((s) => short(s) != s)) ...[
      pw.SizedBox(height: 4),
      _note('Subjects: ${subjNames.where((s) => short(s) != s).map((s) => '${short(s)} = $s').join(';  ')}'),
    ],
    if (atRisk.isNotEmpty || missing.isNotEmpty) _section('Needs attention'),
    if (atRisk.isNotEmpty) pw.Text(_s('Below 50%: ${atRisk.map((s) => '${s['fullName']} (${s['average']}%)').join(', ')}'), style: const pw.TextStyle(fontSize: 9)),
    if (missing.isNotEmpty) ...[
      pw.SizedBox(height: 3),
      pw.Text(_s('Often not handing in: ${missing.map((s) => '${s['fullName']} (${s['missing']})').join(', ')}'), style: const pw.TextStyle(fontSize: 9)),
    ],
  ];
}

Future<Uint8List> buildClassReportPdf(Map<String, dynamic> d) async {
  final school = Map<String, dynamic>.from(d['school'] as Map? ?? {});
  final cls = Map<String, dynamic>.from(d['class'] as Map? ?? {});
  final doc = pw.Document(title: _s('Class report - ${cls['name']}'), author: 'Excellence Coaching Hub');
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 20),
    footer: (ctx) => _footer(ctx, '${school['name'] ?? ''} | Class report | ${cls['name']}'),
    build: (ctx) => [
      _header(school, 'Class report: ${cls['name']}', 'Year ${cls['academicYear'] ?? ''}', d['generatedAt']),
      ..._classBody(d),
      pw.SizedBox(height: 14),
      _note('Avg = average of marked homework, quizzes and class tests. Pos = position in the class by that average. Handed in = work handed in / work that was due.'),
      pw.SizedBox(height: 24),
      pw.Row(children: [pw.Expanded(child: _signLine('Class teacher')), pw.SizedBox(width: 60), pw.Expanded(child: _signLine('Head teacher / Director of studies')), pw.Spacer()]),
    ],
  ));
  return doc.save();
}

// ── Whole school ─────────────────────────────────────────────────────────

Future<Uint8List> buildSchoolReportPdf(Map<String, dynamic> d) async {
  final school = Map<String, dynamic>.from(d['school'] as Map? ?? {});
  final sum = Map<String, dynamic>.from(d['summary'] as Map? ?? {});
  final classes = SchoolService.list(d['classes']);
  final unassigned = SchoolService.list(d['unassignedStudents']);
  final doc = pw.Document(title: _s('School report - ${school['name']}'), author: 'Excellence Coaching Hub');

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 20),
    footer: (ctx) => _footer(ctx, '${school['name'] ?? ''} | School report'),
    build: (ctx) => [
      _header(school, 'School report', [if (school['district'] != null) '${school['district']}', if (school['phone'] != null) '${school['phone']}'].join('  |  '), d['generatedAt']),
      _stats([
        ('Classes', '${sum['classCount'] ?? classes.length}', null),
        ('Students', '${sum['studentCount'] ?? 0}', null),
        ('Teachers', '${sum['teacherCount'] ?? 0}', null),
        ('School average', _pct(sum['schoolAverage']), _toneOf(sum['schoolAverage'])),
        ('Hand-in rate', _pct(sum['handInRate']), _toneOf(sum['handInRate'])),
        ('Students below 50%', '${sum['atRiskCount'] ?? 0}', (sum['atRiskCount'] ?? 0) > 0 ? _red : _green),
      ]),
      _section('Classes at a glance'),
      if (classes.isEmpty)
        _note('No classes yet.')
      else
        _table(
          ['Class', 'Class teacher', 'Students', 'F', 'M', 'Subjects', 'Class average', 'Hand-in rate', 'eexams', 'Below 50%'],
          [
            for (final c in classes)
              [
                '${c['class']?['name'] ?? ''}',
                '${c['class']?['classTeacher']?['fullName'] ?? 'Not set'}',
                '${c['summary']?['studentCount'] ?? 0}',
                '${c['summary']?['genders']?['female'] ?? 0}',
                '${c['summary']?['genders']?['male'] ?? 0}',
                '${(c['subjects'] as List?)?.length ?? 0}',
                _pct(c['summary']?['classAverage']),
                _pct(c['summary']?['handInRate']),
                _pct(c['summary']?['examAverage']),
                '${(c['summary']?['atRisk'] as List?)?.length ?? 0}',
              ],
          ],
          right: {2, 3, 4, 5, 6, 7, 8, 9},
          color: (r, col) => col == 6 ? _toneOf(classes[r]['summary']?['classAverage']) : col == 7 ? _toneOf(classes[r]['summary']?['handInRate']) : null,
        ),
      if (unassigned.isNotEmpty) ...[
        _section('Students without a class (${unassigned.length})'),
        pw.Text(_s(unassigned.map((u) => '${u['fullName']}${u['studentCode'] != null ? ' (${u['studentCode']})' : ''}').join(', ')), style: const pw.TextStyle(fontSize: 9)),
      ],
      for (final c in classes) ...[
        pw.NewPage(),
        _header(school, 'Class ${c['class']?['name'] ?? ''}', 'Year ${c['class']?['academicYear'] ?? ''}', d['generatedAt']),
        ..._classBody(c),
      ],
    ],
  ));
  return doc.save();
}

// ── Download helpers used by the screens ────────────────────────────────

String _file(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

Future<void> _download(BuildContext context, String what, Future<Map<String, dynamic>> Function() load, Future<Uint8List> Function(Map<String, dynamic>) build, String fileName) async {
  showSnack(context, 'Preparing the $what…');
  try {
    final d = await load();
    final bytes = await build(d);
    final where = await saveAndOpenDocument(bytes, fileName);
    if (context.mounted) showSnack(context, where == null ? '${what[0].toUpperCase()}${what.substring(1)} downloaded' : '${what[0].toUpperCase()}${what.substring(1)} saved to $where');
  } catch (e) {
    if (context.mounted) showSnack(context, e.toString(), error: true);
  }
}

/// Downloads a student's report. Pass [data] when it is already loaded.
Future<void> downloadStudentReport(BuildContext context, SchoolService svc, {required String schoolId, required String studentId, required String name, Map<String, dynamic>? data}) =>
    _download(context, 'student report', () async => data ?? await svc.studentReport(schoolId, studentId), buildStudentReportPdf, 'student-report-${_file(name)}.pdf');

Future<void> downloadClassReport(BuildContext context, SchoolService svc, {required String classId, required String className}) =>
    _download(context, 'class report', () => svc.classReport(classId), buildClassReportPdf, 'class-report-${_file(className)}.pdf');

Future<void> downloadSchoolReport(BuildContext context, SchoolService svc, {String schoolId = 'me', String schoolName = 'school'}) =>
    _download(context, 'school report', () => svc.schoolReport(schoolId), buildSchoolReportPdf, 'school-report-${_file(schoolName)}.pdf');
