import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/school/school_reports_pdf.dart';
import '../../../widgets/school/school_ui.dart';

/// Everything about one student for the school admin and the class teacher:
/// profile, parents, subject averages, homework, eexams results, sign-ins.
/// "Download PDF" prints the same information.
class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key, required this.schoolId, required this.studentId, this.name, this.onEdit});
  final String schoolId;
  final String studentId;
  final String? name;
  /// Opens the edit form; returns true when something changed.
  final Future<bool> Function()? onEdit;

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _svc = SchoolService();
  Map<String, dynamic>? _d;
  String? _error;
  String _workFilter = 'all';
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _svc.studentReport(widget.schoolId, widget.studentId);
      if (mounted) setState(() { _d = d; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Tone _tone(num? p) => p == null ? Tone.neutral : p >= 70 ? Tone.good : p >= 50 ? Tone.warn : Tone.bad;
  String _pct(dynamic v) => v == null ? '—' : '${(v as num).round()}%';

  Future<void> _pdf() => downloadStudentReport(context, _svc, schoolId: widget.schoolId, studentId: widget.studentId, name: '${_d?['student']?['fullName'] ?? widget.name ?? 'student'}', data: _d);

  @override
  Widget build(BuildContext context) {
    final title = '${_d?['student']?['fullName'] ?? widget.name ?? 'Student'}';
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        appBar: AppBar(
          title: T(title),
          actions: [
            if (_d != null && widget.onEdit != null)
              IconButton(
                tooltip: trSchool(context, 'Edit details'),
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  if (await widget.onEdit!()) { _changed = true; _load(); }
                },
              ),
            if (_d != null)
              narrow
                  ? IconButton(tooltip: trSchool(context, 'Download PDF'), icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: _pdf)
                  : TextButton.icon(onPressed: _pdf, icon: const Icon(Icons.picture_as_pdf_outlined), label: const T('Download PDF')),
            const SizedBox(width: 6),
          ],
        ),
        body: _d == null
            ? (_error == null ? const Center(child: CircularProgressIndicator()) : ErrorRetry(message: _error!, onRetry: _load))
            : _body(),
      ),
    );
  }

  Widget _body() {
    final d = _d!;
    final st = Map<String, dynamic>.from(d['student'] as Map);
    final cls = d['classroom'] as Map?;
    final stats = Map<String, dynamic>.from(d['stats'] as Map? ?? {});
    final subjects = SchoolService.list(d['subjects']);
    final work = SchoolService.list(d['assessments']);
    final exams = SchoolService.list(d['exams']);
    final signIns = SchoolService.list(d['signIns']);
    final guardians = SchoolService.list(st['guardians']);
    final muted = AppTheme.getSecondaryTextColor(context);

    final shown = switch (_workFilter) {
      'missing' => work.where((a) => a['state'] == 'missing').toList(),
      'marked' => work.where((a) => a['state'] == 'graded').toList(),
      _ => work,
    };

    return SchoolPage(onRefresh: _load, maxWidth: 1000, children: [
      PageHero(
        leading: InitialsAvatar('${st['fullName']}', radius: 26),
        title: '${st['fullName']}',
        subtitle: [if (st['studentCode'] != null) '${st['studentCode']}', cls != null ? '${cls['name']}' : 'No class'].join(' · '),
        chips: [
          if (cls?['classTeacher'] != null) HeroChip('Class teacher: ${cls!['classTeacher']['fullName']}', icon: Icons.person_pin_outlined),
          HeroChip(st['lastActive'] == null ? 'Never signed in' : 'Last seen ${relativeDay(st['lastActive'])}', icon: Icons.schedule_outlined),
          if (st['isActive'] == false) const HeroChip('Removed from school', icon: Icons.block),
        ],
      ),
      MiniStats(items: [
        MiniStat(_pct(stats['average']), 'Average', tone: _tone(stats['average'] as num?)),
        MiniStat(_pct(stats['handInRate']), 'Hand-in rate', tone: _tone(stats['handInRate'] as num?)),
        MiniStat('${stats['missing'] ?? 0}', 'Not handed in', tone: (stats['missing'] ?? 0) > 0 ? Tone.bad : Tone.good, onTap: () => setState(() => _workFilter = 'missing')),
        MiniStat(_pct(stats['examAverage']), 'eexams', tone: Tone.info),
      ]),
      LayoutBuilder(builder: (context, box) {
        final profile = SectionCard(
          icon: Icons.badge_outlined,
          title: 'Profile',
          child: Column(children: [
            _fact('Student code', '${st['studentCode'] ?? '—'}'),
            _fact('Class', '${cls?['name'] ?? 'No class'}${cls?['academicYear'] != null ? ' (${cls!['academicYear']})' : ''}'),
            _fact('Gender', st['gender'] == 'female' ? 'Female' : st['gender'] == 'male' ? 'Male' : st['gender'] == 'other' ? 'Other' : '—'),
            _fact('Date of birth', st['dateOfBirth'] == null ? '—' : fmtDate(st['dateOfBirth'])),
            if ('${st['phone'] ?? ''}'.isNotEmpty) _fact('Phone', '${st['phone']}'),
            _fact('Home address', _address(st['address'])),
            _fact('Registered', fmtDate(st['createdAt'])),
          ]),
        );
        final parents = SectionCard(
          icon: Icons.family_restroom_outlined,
          title: 'Parents and guardians',
          child: guardians.isEmpty
              ? T('No parent or guardian recorded. Use "Edit details" to add one.', style: TextStyle(color: muted))
              : Column(children: [
                  for (var i = 0; i < guardians.length; i++) ...[
                    if (i > 0) const RowDivider(),
                    EntityTile(
                      dense: true,
                      leading: InitialsAvatar('${guardians[i]['name'] ?? guardians[i]['phone'] ?? '?'}', radius: 17),
                      title: '${guardians[i]['name'] ?? 'Parent'}${guardians[i]['relationship'] != null && '${guardians[i]['relationship']}'.isNotEmpty ? ' (${guardians[i]['relationship']})' : ''}',
                      subtitle: '${guardians[i]['phone'] ?? 'No phone'}',
                      pills: [StatusPill(guardians[i]['hasAccount'] == true ? 'Has ECH parent account' : 'No parent account', tone: guardians[i]['hasAccount'] == true ? Tone.good : Tone.neutral)],
                    ),
                  ],
                ]),
        );
        if (box.maxWidth < 720) return Column(children: [profile, const SizedBox(height: 14), parents]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: profile), const SizedBox(width: 14), Expanded(child: parents)]);
      }),
      if (cls != null)
        SectionCard(
          icon: Icons.bar_chart_rounded,
          title: 'Subjects',
          subtitle: 'Average of marked homework, quizzes and class tests',
          child: subjects.isEmpty
              ? T('The class has no subjects yet.', style: TextStyle(color: muted))
              : Column(children: [
                  for (final s in subjects)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ProgressLine(percent: (s['average'] as num?)?.round(), label: '${s['subject']}', tone: _tone(s['average'] as num?)),
                        const SizedBox(height: 3),
                        Text(
                          [if (s['teacher'] != null) '${s['teacher']['fullName']}', '${s['lessonsTaught'] ?? 0} lessons taught', if (s['average'] == null) 'no marks yet'].join(' · '),
                          style: TextStyle(fontSize: 11.5, color: muted),
                        ),
                      ]),
                    ),
                ]),
        ),
      SectionCard(
        icon: Icons.assignment_outlined,
        title: 'Homework, quizzes and tests',
        subtitle: '${stats['handedIn'] ?? 0} of ${stats['expected'] ?? 0} handed in${(stats['late'] ?? 0) > 0 ? ' · ${stats['late']} late' : ''}${(stats['waitingForMark'] ?? 0) > 0 ? ' · ${stats['waitingForMark']} waiting for a mark' : ''}',
        padding: const EdgeInsets.fromLTRB(14, 16, 10, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            PillChoice(label: 'All (${work.length})', selected: _workFilter == 'all', onTap: () => setState(() => _workFilter = 'all')),
            PillChoice(label: 'Not handed in (${stats['missing'] ?? 0})', selected: _workFilter == 'missing', onTap: () => setState(() => _workFilter = 'missing')),
            PillChoice(label: 'Marked', selected: _workFilter == 'marked', onTap: () => setState(() => _workFilter = 'marked')),
          ]),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: T('Nothing here.', style: TextStyle(color: muted)))
          else
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const RowDivider(),
              _workTile(shown[i]),
            ],
        ]),
      ),
      SectionCard(
        icon: Icons.quiz_outlined,
        title: 'eexams results',
        child: exams.isEmpty
            ? T('No eexams results yet.', style: TextStyle(color: muted))
            : Column(children: [
                for (var i = 0; i < exams.length; i++) ...[
                  if (i > 0) const RowDivider(),
                  EntityTile(
                    dense: true,
                    title: '${exams[i]['title']}',
                    subtitle: fmtDate(exams[i]['completedAt']),
                    trailing: _pctText(exams[i]['percentage'] as num?),
                  ),
                ],
              ]),
      ),
      SectionCard(
        icon: Icons.login_outlined,
        title: 'Recent sign-ins',
        child: signIns.isEmpty
            ? T('No sign-ins yet.', style: TextStyle(color: muted))
            : Column(children: [
                for (final l in signIns)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Icon(l['success'] == true ? Icons.check_circle_outline : Icons.error_outline, size: 18, color: toneColor(context, l['success'] == true ? Tone.good : Tone.bad)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(fmtDateTime(l['at']))),
                      if (l['suspicious'] == true) const StatusPill('Unusual', tone: Tone.warn),
                      if (l['success'] != true && l['reason'] != null) Flexible(child: Text('${l['reason']}', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted))),
                    ]),
                  ),
              ]),
      ),
    ]);
  }

  Widget _workTile(Map<String, dynamic> a) {
    final state = '${a['state']}';
    final (label, tone) = switch (state) {
      'graded' => ('Marked', Tone.good),
      'submitted' => ('Handed in, not marked', Tone.info),
      'missing' => ('Not handed in', Tone.bad),
      'pending' => ('Not due yet', Tone.neutral),
      _ => ('No hand-in needed', Tone.neutral),
    };
    return EntityTile(
      dense: true,
      title: '${a['title']}',
      subtitle: '${a['subject'] ?? ''} · ${a['type'] ?? 'homework'} · due ${fmtDate(a['dueAt'])}',
      pills: [
        StatusPill(label, tone: tone),
        if (a['isLate'] == true) const StatusPill('Late', tone: Tone.warn),
        if (a['submittedVia'] == 'parent') const StatusPill('By parent', tone: Tone.neutral),
        if ('${a['feedback'] ?? ''}'.isNotEmpty) StatusPill('“${a['feedback']}”', tone: Tone.neutral),
      ],
      trailing: a['score'] != null
          ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              _pctText(a['percent'] as num?),
              Text('${a['score']}/${a['maxScore']}', style: TextStyle(fontSize: 11.5, color: AppTheme.getSecondaryTextColor(context))),
            ])
          : null,
    );
  }

  Widget _pctText(num? v) => Text(
        v == null ? '—' : '${v.round()}%',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: v == null ? null : toneColor(context, _tone(v))),
      );

  Widget _fact(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: T(label, style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context)))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppTheme.getTextColor(context)))),
        ]),
      );

  String _address(dynamic a) {
    if (a is! Map) return '—';
    final parts = ['village', 'cell', 'sector', 'district', 'province'].map((k) => '${a[k] ?? ''}'.trim()).where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? '—' : parts.join(', ');
  }
}
