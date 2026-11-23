import 'package:flutter/material.dart';

import '../../../../services/api/school_service.dart';
import '../../../../widgets/school/school_ui.dart';
import '../school_admin_dashboard_screen.dart';

/// Parents with an ECH account (created when a student is registered with a parent phone).
class ParentsSection extends StatefulWidget {
  const ParentsSection({super.key, required this.c});
  final SchoolCtx c;

  @override
  State<ParentsSection> createState() => _ParentsSectionState();
}

class _ParentsSectionState extends State<ParentsSection> {
  final _key = GlobalKey<AsyncBodyState<Map<String, dynamic>>>();
  String _search = '';

  Future<void> _newPin(Map<String, dynamic> p) async {
    if (!await confirm(context, title: 'New PIN for ${p['name']}?', message: 'The old PIN stops working.', confirmLabel: 'Create new PIN')) return;
    try {
      final r = await widget.c.svc.resetParentPin(widget.c.schoolId, '${p['id']}');
      final c = Map<String, dynamic>.from(r['credentials'] as Map);
      if (mounted) await showCredentialsDialog(context, title: 'Parent sign-in', rows: [MapEntry('Phone', '${c['phone']}'), MapEntry('PIN', '${c['pin']}')]);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Map<String, dynamic>>(
      key: _key,
      load: () => widget.c.svc.parents(widget.c.schoolId, _search),
      builder: (context, d, reload) {
        final parents = SchoolService.list(d['parents']);
        final total = (d['total'] as num?) ?? parents.length;
        return SchoolPage(onRefresh: reload, children: [
          const InfoBanner(
            icon: Icons.family_restroom_outlined,
            text: 'Parents sign in with "School code & PIN" → Parent, using their phone number. They follow homework, marks and lessons, and can help with homework at home.',
          ),
          TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: trSchool(context, 'Search parent name or phone'), isDense: true),
            textInputAction: TextInputAction.search,
            onSubmitted: (v) { _search = v.trim(); _key.currentState?.reload(); },
          ),
          if (parents.isEmpty)
            const EmptyState(icon: Icons.family_restroom_outlined, title: 'No parent accounts yet', message: 'Add a parent phone number when you register or edit a student.')
          else
            SectionCard(
              icon: Icons.family_restroom_outlined,
              title: plural(total, 'parent'),
              padding: const EdgeInsets.fromLTRB(14, 16, 8, 6),
              child: Column(children: [
                for (var i = 0; i < parents.length; i++) ...[
                  if (i > 0) const RowDivider(),
                  EntityTile(
                    leading: InitialsAvatar('${parents[i]['name']}'),
                    title: '${parents[i]['name']}',
                    subtitle: '${parents[i]['phone'] ?? ''}',
                    pills: [
                      for (final c in SchoolService.list(parents[i]['children']))
                        StatusPill('${c['fullName']} · ${c['className'] ?? trSchool(context, 'no class')}', tone: Tone.info, icon: Icons.child_care_outlined),
                    ],
                    trailing: IconButton(tooltip: trSchool(context, 'New PIN'), icon: const Icon(Icons.pin_outlined), onPressed: () => _newPin(parents[i])),
                  ),
                ],
              ]),
            ),
        ]);
      },
    );
  }
}
