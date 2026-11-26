import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/school_service.dart';
import '../../../../widgets/school/school_reports_pdf.dart';
import '../../../../widgets/school/school_ui.dart';
import '../school_admin_dashboard_screen.dart';

/// Marks per class: averages per subject, per student, at-risk list, eexams exams.
class ResultsSection extends StatefulWidget {
  const ResultsSection({super.key, required this.c});
  final SchoolCtx c;

  @override
  State<ResultsSection> createState() => _ResultsSectionState();
}

class _ResultsSectionState extends State<ResultsSection> {
  List<Map<String, dynamic>>? _classes;
  String? _classId;
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.c.svc.classes(widget.c.schoolId).then((c) {
      if (!mounted) return;
      setState(() => _classes = c);
      if (c.isNotEmpty) _pick('${c.first['id']}');
    }).catchError((e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  Future<void> _pick(String id) async {
    setState(() { _classId = id; _loading = true; _error = null; });
    try {
      final d = await widget.c.svc.results(widget.c.schoolId, id);
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Tone _tone(num? p) => p == null ? Tone.neutral : p >= 70 ? Tone.good : p >= 50 ? Tone.warn : Tone.bad;

  @override
  Widget build(BuildContext context) {
    if (_classes == null) return _error != null ? ErrorRetry(message: _error!, onRetry: () => setState(() {})) : const Center(child: CircularProgressIndicator());
    if (_classes!.isEmpty) return const EmptyState(icon: Icons.insights_outlined, title: 'No classes yet');
    final subjects = ((_data?['subjects'] as List?) ?? const []).map((e) => '$e').toList();
    final avgs = Map<String, dynamic>.from(_data?['subjectAverages'] as Map? ?? {});
    final students = SchoolService.list(_data?['students']);
    final atRisk = SchoolService.list(_data?['atRisk']);
    final muted = AppTheme.getSecondaryTextColor(context);

    final classAvg = avgs.values.whereType<num>().isEmpty ? null : avgs.values.whereType<num>().reduce((a, b) => a + b) / avgs.values.whereType<num>().length;

    return SchoolPage(onRefresh: () => _pick(_classId!), children: [
      DropdownButtonFormField<String>(
        initialValue: _classId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Class', prefixIcon: Icon(Icons.meeting_room_outlined)),
        items: [for (final c in _classes!) DropdownMenuItem(value: '${c['id']}', child: T('${c['name']}'))],
        onChanged: (v) => v == null ? null : _pick(v),
      ),
      ActionBar(
        primary: BarAction('Class report (PDF)', Icons.picture_as_pdf_outlined, _classId == null
            ? null
            : () => downloadClassReport(context, widget.c.svc, classId: _classId!, className: '${_classes!.firstWhere((c) => '${c['id']}' == _classId, orElse: () => {'name': 'class'})['name']}')),
        more: [
          BarAction('School report (PDF)', Icons.download_outlined, () => downloadSchoolReport(context, widget.c.svc, schoolId: widget.c.schoolId, schoolName: '${widget.c.school['name'] ?? 'school'}')),
        ],
      ),
      if (_loading)
        const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
      else if (_error != null)
        ErrorRetry(message: _error!, onRetry: () => _pick(_classId!))
      else ...[
        MiniStats(items: [
          MiniStat(classAvg == null ? '—' : '${classAvg.round()}%', 'Class average', tone: _tone(classAvg)),
          MiniStat('${students.length}', 'Students'),
          MiniStat('${atRisk.length}', 'Below 50%', tone: atRisk.isEmpty ? Tone.good : Tone.bad),
        ]),
        if (subjects.isEmpty)
          const EmptyState(icon: Icons.assignment_outlined, title: 'No marked homework yet', message: 'Averages appear once teachers mark homework for this class.')
        else
          SectionCard(
            icon: Icons.bar_chart_rounded,
            title: 'Subject averages',
            subtitle: 'Homework and class exams',
            child: Column(children: [
              for (final s in subjects) Padding(padding: const EdgeInsets.only(bottom: 12), child: ProgressLine(percent: (avgs[s] as num?)?.round(), label: s)),
            ]),
          ),
        if (atRisk.isNotEmpty)
          SectionCard(
            icon: Icons.warning_amber_rounded,
            tone: Tone.bad,
            title: 'Students below 50%',
            subtitle: 'Talk to their parents and teachers early.',
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in atRisk) StatusPill('${s['fullName']} · ${s['homeworkAverage']}%', tone: Tone.bad),
            ]),
          ),
        if (students.isNotEmpty)
          SectionCard(
            icon: Icons.groups_outlined,
            title: 'Students',
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            child: LayoutBuilder(builder: (context, box) {
              // Phones: one row per student with marks as pills. Wide: a table.
              if (box.maxWidth < 600) {
                return Column(children: [
                  for (var i = 0; i < students.length; i++) ...[
                    if (i > 0) const RowDivider(),
                    EntityTile(
                      dense: true,
                      leading: InitialsAvatar('${students[i]['fullName']}', tone: _tone(students[i]['homeworkAverage'] as num?)),
                      title: '${students[i]['fullName']}',
                      trailing: _pct(students[i]['homeworkAverage'] as num?, bold: true),
                      pills: [
                        for (final s in subjects)
                          if ((students[i]['bySubject'] as Map?)?[s] != null)
                            StatusPill('$s ${((students[i]['bySubject'] as Map)[s] as num).round()}%', tone: _tone((students[i]['bySubject'] as Map)[s] as num)),
                        if (students[i]['examAverage'] != null) StatusPill('eexams ${(students[i]['examAverage'] as num).round()}%', tone: Tone.info),
                      ],
                    ),
                  ],
                ]);
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context)),
                  columnSpacing: 22,
                  columns: [
                    const DataColumn(label: T('Student')),
                    for (final s in subjects) DataColumn(label: Text(s), numeric: true),
                    const DataColumn(label: T('Average'), numeric: true),
                    const DataColumn(label: T('eexams'), numeric: true),
                  ],
                  rows: [
                    for (final st in students)
                      DataRow(cells: [
                        DataCell(T('${st['fullName']}')),
                        for (final s in subjects) DataCell(_pct((st['bySubject'] as Map?)?[s] as num?)),
                        DataCell(_pct(st['homeworkAverage'] as num?, bold: true)),
                        DataCell(_pct(st['examAverage'] as num?)),
                      ]),
                  ],
                ),
              );
            }),
          ),
        T('Homework marks come from ECH; exam results come from eexams.net for students who sat exams there.', style: TextStyle(fontSize: 12, color: muted)),
      ],
    ]);
  }

  Widget _pct(num? v, {bool bold = false}) => Text(
        v == null ? '—' : '${v.round()}%',
        style: TextStyle(color: v == null ? null : toneColor(context, _tone(v)), fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
      );
}
