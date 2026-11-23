import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/school_service.dart';
import '../../../../widgets/school/school_ui.dart';
import '../school_admin_dashboard_screen.dart';

/// Sign-in history: spot student accounts shared between pupils (or schools).
class SignInsSection extends StatefulWidget {
  const SignInsSection({super.key, required this.c});
  final SchoolCtx c;

  @override
  State<SignInsSection> createState() => _SignInsSectionState();
}

class _SignInsSectionState extends State<SignInsSection> {
  final _key = GlobalKey<AsyncBodyState<Map<String, dynamic>>>();
  bool _suspicious = true;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    return AsyncBody<Map<String, dynamic>>(
      key: _key,
      load: () => widget.c.svc.signIns(widget.c.schoolId, suspiciousOnly: _suspicious),
      builder: (context, d, reload) {
        final rows = SchoolService.list(d['signIns']);
        Widget rule(IconData icon, String text) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, size: 19, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(child: T(text, style: TextStyle(color: muted, height: 1.4))),
              ]),
            );
        return SchoolPage(onRefresh: reload, children: [
          SectionCard(
            icon: Icons.shield_outlined,
            tone: Tone.good,
            title: 'How student accounts are protected',
            child: Column(children: [
              rule(Icons.devices_outlined, 'One device at a time: signing in on a new device signs the old one out, so a shared PIN quickly annoys both pupils.'),
              rule(Icons.notifications_active_outlined, 'The student is notified when their account is used on another device.'),
              rule(Icons.lock_clock_outlined, '5 wrong PINs lock the account for 15 minutes.'),
              rule(Icons.flag_outlined, 'Accounts used on 3 or more devices in 24 hours are flagged here. Give that student a new PIN.'),
            ]),
          ),
          SegmentedButton<bool>(
            style: schoolSegmentStyle(context),
            showSelectedIcon: false,
            segments: const [ButtonSegment(value: true, label: T('Flagged'), icon: Icon(Icons.flag_outlined)), ButtonSegment(value: false, label: T('All sign-ins'), icon: Icon(Icons.list_alt))],
            selected: {_suspicious},
            onSelectionChanged: (v) { setState(() => _suspicious = v.first); _key.currentState?.reload(); },
          ),
          if (rows.isEmpty)
            EmptyState(icon: Icons.verified_user_outlined, title: _suspicious ? 'Nothing suspicious' : 'No sign-ins yet')
          else
            SectionCard(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Column(children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const RowDivider(),
                  _row(rows[i]),
                ],
              ]),
            ),
        ]);
      },
    );
  }

  Widget _row(Map<String, dynamic> r) {
    final ok = r['success'] == true;
    final sus = r['suspicious'] == true;
    final tone = ok ? (sus ? Tone.warn : Tone.good) : Tone.bad;
    final c = toneColor(context, tone);
    return EntityTile(
      dense: true,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
        child: Icon(ok ? (sus ? Icons.warning_amber_rounded : Icons.login) : Icons.block, color: c, size: 20),
      ),
      title: r['user'] != null ? '${r['user']['fullName']}' : '${r['identifier'] ?? 'Unknown'}',
      subtitle: [
        fmtDateTime(r['at']),
        if (r['user']?['studentCode'] != null) '${r['user']['studentCode']}',
        if (r['ip'] != null) 'IP ${r['ip']}',
      ].join(' · '),
      pills: [
        if (!ok) StatusPill(_reason(r['reason']), tone: Tone.bad),
        if (r['suspiciousReason'] != null) StatusPill('${r['suspiciousReason']}', tone: Tone.warn),
      ],
    );
  }

  static String _reason(dynamic r) => switch (r) {
        'wrong_pin' => 'wrong PIN',
        'locked' => 'locked',
        'unknown_identifier' => 'unknown code',
        'inactive' => 'account removed',
        'school_inactive' => 'school inactive',
        _ => 'failed',
      };
}
