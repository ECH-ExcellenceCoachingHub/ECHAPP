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
              final exp = parseDate(d['expiresAt']);
              final total = ((d['codeMinutes'] as num?) ?? 60) * 60;
              final left = exp == null ? 0 : exp.difference(DateTime.now()).inSeconds.clamp(0, total);
              return SchoolPage(onRefresh: _load, maxWidth: 900, children: [
                if (d['mode'] == 'anywhere')
                  const InfoBanner(
                    tone: Tone.warn,
                    icon: Icons.info_outline,
                    text: 'Your school currently lets students sign in from anywhere, so this code is not needed. The school admin can change this in Student sign-in.',
                  ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: big ? 36 : 26),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: AppTheme.primaryDark.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: Column(children: [
                    HeroChip(d['scope'] == 'class' ? '${d['className']}' : '${d['schoolName']}', icon: d['scope'] == 'class' ? Icons.meeting_room_outlined : Icons.apartment_rounded),
                    const SizedBox(height: 14),
                    Text(
                      trSchool(context, d['pinless'] == true ? 'Type this code, then tap your name' : 'Student code + PIN + this code'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: big ? 20 : 15),
                    ),
                    const SizedBox(height: 14),
                    FittedBox(
                      child: SelectableText(
                        shown,
                        style: TextStyle(fontSize: big ? 128 : 76, fontWeight: FontWeight.w800, letterSpacing: 8, fontFamily: 'monospace', color: Colors.white, height: 1.1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: total == 0 ? 0 : left / total,
                          strokeWidth: 3,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(trSchool(context, _left()), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ]),
                  ]),
                ),
                T('The code changes every ${d['codeMinutes']} minutes. Do not share it outside the classroom.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
                SectionCard(
                  icon: Icons.how_to_reg_outlined,
                  tone: Tone.good,
                  title: 'Signed in with this code today (${signIns.length})',
                  subtitle: 'Check that everyone here is really in the room.',
                  child: signIns.isEmpty
                      ? T('Nobody yet.', style: TextStyle(color: muted))
                      : Column(children: [
                          for (var i = 0; i < signIns.length; i++) ...[
                            if (i > 0) const RowDivider(),
                            EntityTile(
                              dense: true,
                              leading: InitialsAvatar('${signIns[i]['fullName']}', radius: 17, tone: Tone.good),
                              title: '${signIns[i]['fullName']}',
                              trailing: Text(fmtDateTime(signIns[i]['at']).split(', ').last, style: TextStyle(color: muted, fontSize: 12.5)),
                            ),
                          ],
                        ]),
                ),
              ]);
            }),
    );
  }
}
