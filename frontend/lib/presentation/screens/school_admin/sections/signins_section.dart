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
    return AsyncBody<Map<String, dynamic>>(
      key: _key,
      load: () => widget.c.svc.signIns(widget.c.schoolId, suspiciousOnly: _suspicious),
      builder: (context, d, reload) {
        final rows = SchoolService.list(d['signIns']);
        return SchoolPage(onRefresh: reload, children: [
          SectionCard(
            title: 'How student accounts are protected',
            child: Text(
              '• One device at a time: signing in on a new device signs the old one out, so a shared PIN quickly annoys both pupils.\n'
              '• The student is notified when their account is used on another device.\n'
              '• 5 wrong PINs lock the account for 15 minutes.\n'
              '• Accounts used on 3 or more devices in 24 hours are flagged here. Give that student a new PIN.',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context), height: 1.5),
            ),
          ),
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: true, label: T('Flagged')), ButtonSegment(value: false, label: T('All sign-ins'))],
            selected: {_suspicious},
            onSelectionChanged: (v) { setState(() => _suspicious = v.first); _key.currentState?.reload(); },
          ),
          if (rows.isEmpty)
            EmptyState(icon: Icons.verified_user_outlined, title: _suspicious ? 'Nothing suspicious' : 'No sign-ins yet')
          else
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: [
                for (final r in rows)
                  ListTile(
                    leading: Icon(
                      r['success'] == true ? (r['suspicious'] == true ? Icons.warning_amber_rounded : Icons.login) : Icons.block,
                      color: r['success'] == true ? (r['suspicious'] == true ? AppTheme.warningColor : AppTheme.successColor) : AppTheme.errorColor,
                    ),
                    title: Text(r['user'] != null ? '${r['user']['fullName']} ${r['user']['studentCode'] != null ? '(${r['user']['studentCode']})' : ''}' : '${r['identifier'] ?? 'Unknown'}'),
                    subtitle: Text([
                      fmtDateTime(r['at']),
                      if (r['success'] != true) _reason(r['reason']),
                      if (r['suspiciousReason'] != null) '${r['suspiciousReason']}',
                      if (r['ip'] != null) 'IP ${r['ip']}',
                      if (r['deviceId'] != null) 'device ${r['deviceId']}',
                    ].join(' · ')),
                  ),
              ]),
            ),
        ]);
      },
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
