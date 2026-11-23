import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/school/school_ui.dart';
import '../../providers/auth_provider.dart';
import 'sections/access_section.dart';
import 'sections/billing_section.dart';
import 'sections/classes_section.dart';
import 'sections/parents_section.dart';
import 'sections/profile_section.dart';
import 'sections/progress_section.dart';
import 'sections/results_section.dart';
import 'sections/signins_section.dart';
import 'sections/staff_section.dart';
import 'sections/students_section.dart';

/// What every section needs: which school, who is looking, the API.
class SchoolCtx {
  SchoolCtx({required this.schoolId, required this.superAdmin, required this.svc, required this.school, required this.reloadSchool, required this.go});
  final String schoolId;
  final bool superAdmin;
  final SchoolService svc;
  final Map<String, dynamic> school;
  final Future<void> Function() reloadSchool;
  /// Switch to another section (e.g. from an overview card).
  final void Function(String section) go;
}

class _Section {
  const _Section(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

const _sections = [
  _Section('overview', 'Overview', Icons.space_dashboard_outlined),
  _Section('classes', 'Classes', Icons.meeting_room_outlined),
  _Section('staff', 'Teachers & staff', Icons.co_present_outlined),
  _Section('students', 'Students', Icons.groups_outlined),
  _Section('parents', 'Parents', Icons.family_restroom_outlined),
  _Section('progress', 'Lesson progress', Icons.fact_check_outlined),
  _Section('results', 'Results', Icons.insights_outlined),
  _Section('access', 'Student sign-in', Icons.lock_clock_outlined),
  _Section('signins', 'Sign-in activity', Icons.shield_outlined),
  _Section('billing', 'Terms & billing', Icons.receipt_long_outlined),
  _Section('profile', 'School profile', Icons.apartment_outlined),
];

/// Head teacher / director of studies dashboard. The super admin opens the
/// same screen for any school (with billing controls) via [schoolId].
class SchoolAdminDashboardScreen extends ConsumerStatefulWidget {
  const SchoolAdminDashboardScreen({super.key, this.schoolId = 'me', this.initialSection = 'overview'});
  final String schoolId;
  final String initialSection;

  @override
  ConsumerState<SchoolAdminDashboardScreen> createState() => _SchoolAdminDashboardScreenState();
}

class _SchoolAdminDashboardScreenState extends ConsumerState<SchoolAdminDashboardScreen> {
  final _svc = SchoolService();
  final _scaffold = GlobalKey<ScaffoldState>();
  late String _section = widget.initialSection;
  Map<String, dynamic>? _school;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchool();
  }

  Future<void> _loadSchool() async {
    try {
      final s = await _svc.getSchool(widget.schoolId);
      if (mounted) setState(() { _school = s; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _go(String key) {
    setState(() => _section = key);
    if (_scaffold.currentState?.isDrawerOpen ?? false) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final superAdmin = user?.role == 'admin';
    final wide = MediaQuery.of(context).size.width >= 980;

    if (_school == null) {
      return Scaffold(
        appBar: AppBar(title: const T('School')),
        body: _error == null ? const Center(child: CircularProgressIndicator()) : ErrorRetry(message: _error!, onRetry: _loadSchool),
      );
    }

    final ctx = SchoolCtx(schoolId: _school!['id'] as String, superAdmin: superAdmin, svc: _svc, school: _school!, reloadSchool: _loadSchool, go: _go);
    final current = _sections.firstWhere((s) => s.key == _section, orElse: () => _sections.first);
    final nav = _NavList(school: _school!, current: _section, onSelect: _go, superAdmin: superAdmin, onSignOut: superAdmin ? null : () async {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/auth-selection');
    });

    final body = KeyedSubtree(key: ValueKey(_section), child: _body(ctx));

    return Scaffold(
      key: _scaffold,
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        automaticallyImplyLeading: !wide,
        leading: superAdmin && wide ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.canPop() ? context.pop() : context.go('/admin/schools')) : null,
        title: Text(wide ? '${_school!['name']}' : trSchool(context, current.label)),
        actions: [
          if (superAdmin && !wide) IconButton(tooltip: 'All schools', icon: const Icon(Icons.apartment), onPressed: () => context.go('/admin/schools')),
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: () { _loadSchool(); setState(() {}); }),
        ],
      ),
      drawer: wide ? null : Drawer(child: SafeArea(child: nav)),
      body: wide
          ? Row(children: [
              SizedBox(width: 250, child: Material(color: AppTheme.getCardColor(context), child: nav)),
              VerticalDivider(width: 1, color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
              Expanded(child: body),
            ])
          : body,
    );
  }

  Widget _body(SchoolCtx c) {
    switch (_section) {
      case 'classes':
        return ClassesSection(c: c);
      case 'staff':
        return StaffSection(c: c);
      case 'students':
        return StudentsSection(c: c);
      case 'parents':
        return ParentsSection(c: c);
      case 'progress':
        return ProgressSection(c: c);
      case 'results':
        return ResultsSection(c: c);
      case 'access':
        return AccessSection(c: c);
      case 'signins':
        return SignInsSection(c: c);
      case 'billing':
        return BillingSection(c: c);
      case 'profile':
        return ProfileSection(c: c);
      default:
        return _Overview(c: c);
    }
  }
}

class _NavList extends StatelessWidget {
  const _NavList({required this.school, required this.current, required this.onSelect, required this.superAdmin, this.onSignOut});
  final Map<String, dynamic> school;
  final String current;
  final ValueChanged<String> onSelect;
  final bool superAdmin;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    return ListView(padding: const EdgeInsets.symmetric(vertical: 12), children: [
      Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.apartment_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${school['name']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Colors.white)),
              const SizedBox(height: 2),
              Text(trSchool(context, 'Code ${school['code'] ?? '—'}${superAdmin ? ' · ECH admin view' : ''}'), style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
            ]),
          ),
        ]),
      ),
      for (final s in _sections)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: ListTile(
            dense: true,
            selected: s.key == current,
            selectedTileColor: AppTheme.primary.withValues(alpha: 0.10),
            selectedColor: AppTheme.primaryDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: Icon(s.icon, size: 21),
            title: Text(trSchool(context, s.label), style: const TextStyle(fontSize: 14)),
            onTap: () => onSelect(s.key),
          ),
        ),
      if (onSignOut != null) ...[
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.logout, size: 21),
            title: const T('Sign out'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onTap: onSignOut,
          ),
        ),
      ],
    ]);
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.c});
  final SchoolCtx c;

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Map<String, dynamic>>(
      load: () => c.svc.overview(c.schoolId),
      builder: (context, d, reload) {
        final school = Map<String, dynamic>.from(d['school'] as Map);
        final sub = Map<String, dynamic>.from(school['subscription'] as Map? ?? {});
        final week = Map<String, dynamic>.from(d['week'] as Map? ?? {});
        final att = Map<String, dynamic>.from(d['attention'] as Map? ?? {});
        final quiet = SchoolService.list(att['teachersWithoutMarksThisWeek']);
        final flagged = SchoolService.list(d['flaggedLatest']);
        final status = sub['status'] as String?;
        final limit = (sub['studentLimit'] as num?)?.toInt() ?? 0;
        final students = (school['studentCount'] as num?)?.toInt() ?? 0;

        final alerts = <Widget>[
          if (status == 'grace')
            _Alert(tone: Tone.warn, icon: Icons.schedule, text: 'Grace period: ${sub['daysLeft']} days left. Pay for the new term to keep course access.', onTap: () => c.go('billing')),
          if (status == 'expired')
            const _Alert(tone: Tone.bad, icon: Icons.block, text: 'Subscription expired: students have no course access. Contact ECH to pay for this term.'),
          if (status == 'trial')
            _Alert(tone: Tone.info, icon: Icons.info_outline, text: 'Trial: up to $limit students. Pay for a term to unlock the ECH courses for your classes.', onTap: () => c.go('billing')),
          if ((att['flaggedLessons'] ?? 0) > 0)
            _Alert(tone: Tone.bad, icon: Icons.flag_outlined, text: '${att['flaggedLessons']} lesson mark(s) look untaught and need your review.', onTap: () => c.go('progress')),
          if ((att['suspiciousSignIns'] ?? 0) > 0)
            _Alert(tone: Tone.warn, icon: Icons.shield_outlined, text: '${att['suspiciousSignIns']} student account(s) were used on several devices this week — possible shared PINs.', onTap: () => c.go('signins')),
          if ((att['studentsWithoutClass'] ?? 0) > 0)
            _Alert(tone: Tone.warn, icon: Icons.person_off_outlined, text: '${att['studentsWithoutClass']} student(s) have no class.', onTap: () => c.go('students')),
          if ((att['subjectsWithoutTeacher'] ?? 0) > 0)
            _Alert(tone: Tone.warn, icon: Icons.assignment_ind_outlined, text: '${att['subjectsWithoutTeacher']} class subject(s) have no teacher.', onTap: () => c.go('classes')),
        ];

        final setup = Map<String, dynamic>.from(d['setup'] as Map? ?? {});
        final setupSteps = SchoolService.list(setup['steps']);
        final setupDone = (setup['done'] as num?)?.toInt() ?? 0;

        final narrow = MediaQuery.sizeOf(context).width < 980;
        return SchoolPage(onRefresh: reload, children: [
          PageHero(
            leading: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
            ),
            title: '${c.school['name'] ?? school['name'] ?? ''}',
            subtitle: [
              if (c.school['code'] != null) 'Code ${c.school['code']}',
              if ((c.school['headTeacherName'] ?? '').toString().isNotEmpty) '${c.school['headTeacherName']}',
            ].join(' · '),
            chips: [
              if (_statusLabel(status).isNotEmpty) HeroChip(_statusLabel(status), icon: status == 'active' ? Icons.verified_outlined : Icons.schedule),
              HeroChip('$students of $limit students', icon: Icons.groups_outlined),
              if (sub['daysLeft'] != null && status != 'active') HeroChip('${sub['daysLeft']} days left', icon: Icons.hourglass_bottom),
            ],
          ),
          if (setupSteps.isNotEmpty && setupDone < setupSteps.length)
            SectionCard(
              icon: Icons.rocket_launch_outlined,
              tone: Tone.good,
              title: 'Get your school ready',
              subtitle: '$setupDone of ${setupSteps.length} steps done',
              child: Column(children: [
                ProgressLine(percent: (setupDone * 100 / setupSteps.length).round(), tone: Tone.good),
                const SizedBox(height: 8),
                for (var i = 0; i < setupSteps.length; i++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: setupSteps[i]['done'] == true
                        ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                        : CircleAvatar(radius: 12, backgroundColor: AppTheme.getBorderColor(context).withValues(alpha: 0.5), child: T('${i + 1}', style: const TextStyle(fontSize: 12))),
                    title: Text(
                      '${setupSteps[i]['label']}',
                      style: TextStyle(
                        decoration: setupSteps[i]['done'] == true ? TextDecoration.lineThrough : null,
                        color: setupSteps[i]['done'] == true ? AppTheme.getSecondaryTextColor(context) : AppTheme.getTextColor(context),
                      ),
                    ),
                    trailing: setupSteps[i]['done'] == true ? null : TextButton(onPressed: () => c.go('${setupSteps[i]['section']}'), child: const T('Start')),
                  ),
              ]),
            ),
          StatGrid(children: [
            StatTile(label: 'Students', value: '$students / $limit', icon: Icons.groups_outlined, tone: students >= limit && limit > 0 ? Tone.warn : Tone.info, caption: _statusLabel(status), onTap: () => c.go('students')),
            StatTile(label: 'Teachers', value: '${school['teacherCount'] ?? 0}', icon: Icons.co_present_outlined, tone: Tone.good, onTap: () => c.go('staff')),
            StatTile(label: 'Classes', value: '${school['classCount'] ?? 0}', icon: Icons.meeting_room_outlined, tone: Tone.info, onTap: () => c.go('classes')),
            StatTile(label: 'Flagged lessons', value: '${att['flaggedLessons'] ?? 0}', icon: Icons.flag_outlined, tone: (att['flaggedLessons'] ?? 0) > 0 ? Tone.bad : Tone.good, onTap: () => c.go('progress')),
          ]),
          if (alerts.isNotEmpty) SectionCard(icon: Icons.priority_high_rounded, tone: Tone.bad, title: 'Needs attention', child: Column(children: alerts)),
          SectionCard(
            icon: Icons.date_range_outlined,
            title: 'This week',
            subtitle: week['handInRate'] == null ? null : 'Hand-in rate: ${week['handInRate']}%',
            child: MiniStats(items: [
              MiniStat('${week['lessonsMarked'] ?? 0}', 'Lessons taught', tone: Tone.good),
              MiniStat('${week['homeworkGiven'] ?? 0}', 'Homework given', tone: Tone.info),
              MiniStat('${week['handIns'] ?? 0}', 'Hand-ins', tone: Tone.info),
            ]),
          ),
          if (narrow)
            SectionCard(
              icon: Icons.apps_rounded,
              title: 'Go to',
              child: LayoutBuilder(builder: (context, box) {
                final cols = box.maxWidth >= 520 ? 4 : 3;
                final w = (box.maxWidth - (cols - 1) * 10) / cols;
                return Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final sec in _sections.where((x) => x.key != 'overview'))
                    SizedBox(width: w, child: _QuickLink(icon: sec.icon, label: sec.label, onTap: () => c.go(sec.key))),
                ]);
              }),
            ),
          if (quiet.isNotEmpty)
            SectionCard(
              icon: Icons.person_search_outlined,
              tone: Tone.warn,
              title: 'Teachers with no lesson marked this week',
              subtitle: 'They may be teaching without recording it — or not teaching.',
              child: Column(children: [
                for (final t in quiet)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: T('${t['fullName']}'),
                    subtitle: T('Last active: ${t['lastActive'] == null ? 'never' : fmtDateTime(t['lastActive'])}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/school-admin/teachers/${t['id']}?school=${c.schoolId}'),
                  ),
              ]),
            ),
          if (flagged.isNotEmpty)
            SectionCard(
              icon: Icons.flag_outlined,
              tone: Tone.bad,
              title: 'Latest flagged lessons',
              trailing: TextButton(onPressed: () => c.go('progress'), child: const T('Review all')),
              child: Column(children: [
                for (final f in flagged)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag, color: AppTheme.errorColor),
                    title: T('${f['subject']} · ${f['className']} — ${f['topic']}'),
                    subtitle: T('${f['teacher'] ?? ''} · ${fmtDay(f['taughtOn'])}\n${SchoolService.list(f['flags']).map((x) => x['message']).join(' ')}'),
                    isThreeLine: true,
                  ),
              ]),
            ),
        ]);
      },
    );
  }

  static String _statusLabel(String? s) => switch (s) {
        'active' => 'Term paid',
        'grace' => 'Grace period',
        'trial' => 'Trial',
        'expired' => 'Expired',
        _ => '',
      };
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        child: Material(
          color: AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: AppTheme.primaryDark, size: 24),
                const SizedBox(height: 6),
                Text(trSchool(context, label), maxLines: 2, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context), height: 1.2)),
              ]),
            ),
          ),
        ),
      );
}

class _Alert extends StatelessWidget {
  const _Alert({required this.tone, required this.icon, required this.text, this.onTap});
  final Tone tone;
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final col = toneColor(context, tone);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: col.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(icon, color: col, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(trSchool(context, text), style: TextStyle(color: AppTheme.getTextColor(context)))),
              if (onTap != null) Icon(Icons.chevron_right, color: col),
            ]),
          ),
        ),
      ),
    );
  }
}
