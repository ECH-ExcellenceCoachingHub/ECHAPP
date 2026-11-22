import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/school/school_ui.dart';

/// Big sign-in code for the board/projector. A class code (classId) works only
/// for that class; without classId it is the school-wide code for the lab.
/// Refreshes itself and shows who has signed in with it today.
class ClassCodeScreen extends StatefulWidget {
  const ClassCodeScreen({super.key, this.classId, this.schoolId});
  final String? classId;
  final String? schoolId;

  @override
  State<ClassCodeScreen> createState() => _ClassCodeScreenState();
}

class _ClassCodeScreenState extends State<ClassCodeScreen> {
  final _svc = SchoolService();
  Map<String, dynamic>? _d;
  String? _error;
  Timer? _poll;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _load());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await _svc.accessCode(classId: widget.classId, schoolId: widget.schoolId);
      if (mounted) setState(() { _d = d; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  String _left() {
    final exp = parseDate(_d?['expiresAt']);
    if (exp == null) return '';
    final s = exp.difference(DateTime.now()).inSeconds;
    if (s <= 0) return 'changing…';
    final m = s ~/ 60;
    return m >= 1 ? '$m min left' : '$s s left';
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    final muted = AppTheme.getSecondaryTextColor(context);
    final title = d == null ? 'Sign-in code' : d['scope'] == 'class' ? 'Class code · ${d['className']}' : 'School code · ${d['schoolName']}';
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: Text(title)),
      body: d == null
          ? (_error == null ? const Center(child: CircularProgressIndicator()) : ErrorRetry(message: _error!, onRetry: _load))
          : LayoutBuilder(builder: (context, box) {
              final big = box.maxWidth > 700;
              final code = '${d['code']}';
              final shown = '${code.substring(0, 3)} ${code.substring(3)}';
              final signIns = SchoolService.list(d['signIns']);
              return SchoolPage(onRefresh: _load, maxWidth: 900, children: [
                if (d['mode'] == 'anywhere')
                  const SectionCard(
                    child: T('Your school currently lets students sign in from anywhere, so this code is not needed. The school admin can change this in Student sign-in.'),
                  ),
                SectionCard(
                  child: Column(children: [
                    Text(d['scope'] == 'class' ? 'Students of ${d['className']} sign in with' : 'Any student of the school signs in with', style: TextStyle(color: muted, fontSize: big ? 18 : 14)),
                    const SizedBox(height: 4),
                    Text(
                      d['pinless'] == true ? 'this code, then tap their name' : 'student code + PIN + this code',
                      style: TextStyle(color: muted, fontSize: big ? 18 : 14),
                    ),
                    const SizedBox(height: 18),
                    FittedBox(
                      child: SelectableText(
                        shown,
                        style: TextStyle(fontSize: big ? 120 : 72, fontWeight: FontWeight.w800, letterSpacing: 6, fontFamily: 'monospace', color: AppTheme.getTextColor(context)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StatusPill(_left(), tone: Tone.info, icon: Icons.timer_outlined),
                    const SizedBox(height: 12),
                    T('The code changes every ${d['codeMinutes']} minutes. Do not share it outside the classroom.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
                  ]),
                ),
                SectionCard(
                  title: 'Signed in with this code today (${signIns.length})',
                  subtitle: 'Check that everyone here is really in the room.',
                  child: signIns.isEmpty
                      ? T('Nobody yet.', style: TextStyle(color: muted))
                      : Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final p in signIns)
                            Chip(
                              avatar: const Icon(Icons.check_circle, size: 18, color: AppTheme.successColor),
                              label: T('${p['fullName']} · ${fmtDateTime(p['at']).split(', ').last}'),
                            ),
                        ]),
                ),
              ]);
            }),
    );
  }
}
