import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/teacher_access_service.dart';

/// Self-registered teachers waiting for approval, with everything they told us.
class AdminTeacherApprovalsScreen extends StatefulWidget {
  const AdminTeacherApprovalsScreen({super.key});

  @override
  State<AdminTeacherApprovalsScreen> createState() => _AdminTeacherApprovalsScreenState();
}

class _AdminTeacherApprovalsScreenState extends State<AdminTeacherApprovalsScreen> {
  final _svc = TeacherAccessService();
  final _search = TextEditingController();
  Timer? _debounce;
  String _status = 'pending';
  List<TeacherApplication> _apps = [];
  Map<String, int> _counts = {};
  bool _loading = true;
  String? _error;

  static const _tabs = [
    ('pending', 'Waiting', Icons.hourglass_top_rounded),
    ('approved', 'Approved', Icons.verified_rounded),
    ('rejected', 'Rejected', Icons.block),
    ('profile_incomplete', 'Profile not finished', Icons.edit_note),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (apps, counts) = await _svc.applications(status: _status, search: _search.text);
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _counts = counts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _review(TeacherApplication a, bool approve) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(approve ? 'Approve ${a.fullName}?' : 'Reject ${a.fullName}?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(approve
              ? 'They will be able to choose courses and request teacher\'s guides. Their tools unlock when a course request is approved.'
              : 'Tell the teacher what to fix. They can update their profile and submit again.'),
          const SizedBox(height: 12),
          TextField(
            controller: reason,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: approve ? 'Note (optional)' : 'Reason (required)',
              border: const OutlineInputBorder(),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: approve ? Colors.green : Colors.red),
            onPressed: () {
              if (!approve && reason.text.trim().isEmpty) return;
              Navigator.pop(c, true);
            },
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.reviewApplication(a.id, approve: approve, reason: reason.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? '${a.fullName} approved' : '${a.fullName} rejected')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            const Expanded(child: Text('Teacher approvals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh)),
          ]),
          Text('Teachers who registered themselves. Approve them, then approve their course requests in Payments.',
              style: TextStyle(color: Theme.of(context).hintColor)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final t in _tabs)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(t.$3, size: 18),
                    label: Text('${t.$2} (${_counts[t.$1] ?? 0})'),
                    selected: _status == t.$1,
                    onSelected: (_) {
                      setState(() => _status = t.$1);
                      _load();
                    },
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), _load);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search name, email, phone, school or district',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Center(child: Column(children: [Text(_error!), TextButton(onPressed: _load, child: const Text('Retry'))]))
          else if (_apps.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(child: Text(_status == 'pending' ? 'No teacher is waiting for approval 🎉' : 'Nothing here.')),
            )
          else
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth > 1100 ? 3 : c.maxWidth > 700 ? 2 : 1;
              final w = (c.maxWidth - (cols - 1) * 12) / cols;
              return Wrap(spacing: 12, runSpacing: 12, children: [
                for (final a in _apps) SizedBox(width: w, child: _ApplicationCard(app: a, onApprove: () => _review(a, true), onReject: () => _review(a, false))),
              ]);
            }),
        ]),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final TeacherApplication app;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _ApplicationCard({required this.app, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final p = app.profile;
    final hint = Theme.of(context).hintColor;
    final df = DateFormat('d MMM y');
    Widget row(IconData icon, String label, String value) => value.trim().isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 16, color: hint),
              const SizedBox(width: 8),
              SizedBox(width: 92, child: Text(label, style: TextStyle(color: hint, fontSize: 13))),
              Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ]),
          );

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
              child: Text(app.fullName.isEmpty ? '?' : app.fullName[0].toUpperCase(), style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text([app.email, app.phone].where((e) => e.isNotEmpty).join(' · '), style: TextStyle(color: hint, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
          const Divider(height: 20),
          row(Icons.apartment_outlined, 'School', [p.school, if (p.schoolType.isNotEmpty) '(${p.schoolType})'].join(' ')),
          row(Icons.location_on_outlined, 'Location', [p.district, p.province].where((e) => e.isNotEmpty).join(', ')),
          row(Icons.class_outlined, 'Classes', p.levels.join(', ')),
          row(Icons.menu_book_outlined, 'Subjects', p.subjects.join(', ')),
          row(Icons.timeline_outlined, 'Experience', p.yearsExperience == null ? '' : '${p.yearsExperience} years'),
          row(Icons.workspace_premium_outlined, 'Qualification', p.qualification),
          row(Icons.phone_outlined, 'Contact phone', p.phone),
          if (p.bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(p.bio, style: TextStyle(fontSize: 13, color: hint, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 8),
          Text(
            [
              if (p.submittedAt != null) 'Submitted ${df.format(p.submittedAt!.toLocal())}',
              if (app.courseCount > 0) '${app.courseCount} course(s)',
              if (app.pendingRequests > 0) '${app.pendingRequests} course request(s) waiting',
              if (app.reviewedAt != null) 'Reviewed ${df.format(app.reviewedAt!.toLocal())}${app.reviewedBy != null ? ' by ${app.reviewedBy}' : ''}',
            ].join(' · '),
            style: TextStyle(fontSize: 12, color: hint),
          ),
          if (app.reviewReason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Note: ${app.reviewReason}', style: const TextStyle(fontSize: 12)),
          ],
          if (app.status != 'profile_incomplete') ...[
            const SizedBox(height: 12),
            Row(children: [
              if (app.status != 'approved')
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              if (app.status != 'approved' && app.status != 'rejected') const SizedBox(width: 8),
              if (app.status != 'rejected')
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(app.status == 'approved' ? 'Revoke' : 'Reject'),
                  ),
                ),
            ]),
          ],
        ]),
      ),
    );
  }
}
