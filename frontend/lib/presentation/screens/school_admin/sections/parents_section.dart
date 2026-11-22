import 'package:flutter/material.dart';

import '../../../../services/api/school_service.dart';
import '../../../../widgets/school/pickers.dart';
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

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Map<String, dynamic>>(
      key: _key,
      load: () => widget.c.svc.parents(widget.c.schoolId, _search),
      builder: (context, d, reload) {
        final parents = SchoolService.list(d['parents']);
        return SchoolPage(onRefresh: reload, children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search parent name or phone'),
            onSubmitted: (v) { _search = v.trim(); _key.currentState?.reload(); },
          ),
          const T('Parents sign in with "School code & PIN" → Parent, using their phone number. They see homework, marks and lesson progress of their children.'),
          if (parents.isEmpty)
            const EmptyState(icon: Icons.family_restroom_outlined, title: 'No parent accounts yet', message: 'Add a parent phone number when you register or edit a student.')
          else
            SectionCard(
              title: '${d['total'] ?? parents.length} parent${parents.length == 1 ? '' : 's'}',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(children: [
                for (final p in parents)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(initialsOf(p['name']))),
                    title: T('${p['name']}'),
                    subtitle: T('${p['phone'] ?? ''}\n${SchoolService.list(p['children']).map((c) => '${c['fullName']} (${c['className'] ?? 'no class'})').join(', ')}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'New PIN',
                      icon: const Icon(Icons.pin_outlined),
                      onPressed: () async {
                        if (!await confirm(context, title: 'New PIN for ${p['name']}?', message: 'The old PIN stops working.', confirmLabel: 'Create new PIN')) return;
                        try {
                          final r = await widget.c.svc.resetParentPin(widget.c.schoolId, '${p['id']}');
                          final c = Map<String, dynamic>.from(r['credentials'] as Map);
                          if (context.mounted) await showCredentialsDialog(context, title: 'Parent sign-in', rows: [MapEntry('Phone', '${c['phone']}'), MapEntry('PIN', '${c['pin']}')]);
                        } catch (e) {
                          if (context.mounted) showSnack(context, e.toString(), error: true);
                        }
                      },
                    ),
                  ),
              ]),
            ),
        ]);
      },
    );
  }
}
