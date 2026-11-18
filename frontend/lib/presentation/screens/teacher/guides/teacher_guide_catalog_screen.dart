import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/teacher_access_service.dart';
import '../../../../widgets/network_image_widget.dart';
import '../../../providers/teacher_access_provider.dart';
import '../onboarding/teacher_journey_widgets.dart';

final _money = NumberFormat.decimalPattern();

/// The courses (with their teacher's guide) a teacher can request.
/// [journey] = the mandatory "choose your first course" step; otherwise the
/// teacher is browsing more guides from the dashboard.
class TeacherGuideCatalogScreen extends ConsumerStatefulWidget {
  final bool journey;
  const TeacherGuideCatalogScreen({super.key, this.journey = false});

  @override
  ConsumerState<TeacherGuideCatalogScreen> createState() => _TeacherGuideCatalogScreenState();
}

class _TeacherGuideCatalogScreenState extends ConsumerState<TeacherGuideCatalogScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<TeacherGuideSummary>? _guides;
  String? _error;
  bool _loading = true;
  bool _showAll = false;

  TeacherAccessService get _svc => ref.read(teacherAccessServiceProvider);

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
      final g = await _svc.guides(search: _search.text);
      if (!mounted) return;
      setState(() {
        _guides = g;
        _loading = false;
      });
      // In the journey, an approved course means the teacher may continue.
      if (widget.journey && g.any((x) => x.hasAccess)) ref.invalidate(teacherAccessProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _request(TeacherGuideSummary g) async {
    final result = await showDialog<GuideRequestResult>(
      context: context,
      builder: (_) => _RequestDialog(guide: g, service: _svc),
    );
    if (result == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Request sent'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(result.instructions),
          if (result.amount > 0) ...[
            const SizedBox(height: 12),
            _CopyRow(label: 'Reference', value: result.transactionId),
            const SizedBox(height: 6),
            Text('Amount: RWF ${_money.format(result.amount)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 12),
          Text('Admin contact: ${result.adminContact}', style: TextStyle(fontSize: 12, color: Theme.of(c).hintColor)),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
    _load();
  }

  Future<void> _cancel(GuideRequest r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancel this request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep it')),
          TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Cancel request')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.cancelRequest(r.id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final guides = _guides ?? const [];
    final recommended = guides.where((g) => g.recommended).toList();
    final others = guides.where((g) => !g.recommended).toList();
    final owned = guides.where((g) => g.hasAccess).length;
    final waiting = guides.where((g) => g.request?.waiting == true).length;
    final showRecommended = recommended.isNotEmpty && !_showAll && _search.text.trim().isEmpty;
    final list = showRecommended ? recommended : guides;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(widget.journey ? 'Choose your course' : "Teacher's guides"),
        automaticallyImplyLeading: !widget.journey,
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh)),
          if (widget.journey) const TeacherLogoutButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          if (widget.journey) const SliverToBoxAdapter(child: TeacherJourneyProgress(current: 2)),
          SliverToBoxAdapter(
            child: _Constrained(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (widget.journey) ...[
                  const Text('Pick the course(s) you teach', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    "Each course comes with a teacher's guide: every lesson explained step by step, with modern teaching ideas and short videos. "
                    'Your teacher tools unlock as soon as an admin approves your first course.',
                    style: TextStyle(color: Theme.of(context).hintColor, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                ],
                if (waiting > 0)
                  _Banner(
                    color: const Color(0xFFF59E0B),
                    icon: Icons.hourglass_top_rounded,
                    text: '$waiting request${waiting > 1 ? 's are' : ' is'} waiting for admin approval. Pull down to refresh.',
                  ),
                if (widget.journey && owned > 0)
                  _Banner(
                    color: Colors.green,
                    icon: Icons.check_circle,
                    text: 'Your course is approved!',
                    action: TextButton(onPressed: () => context.go('/teacher/dashboard'), child: const Text('Open dashboard')),
                  ),
                TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by course, subject or class (e.g. S2, Biology)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                if (recommended.isNotEmpty && _search.text.trim().isEmpty)
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text('For my classes (${recommended.length})'), icon: const Icon(Icons.star_outline)),
                      ButtonSegment(value: true, label: Text('All (${guides.length})'), icon: const Icon(Icons.apps)),
                    ],
                    selected: {_showAll},
                    onSelectionChanged: (s) => setState(() => _showAll = s.first),
                  ),
                if (recommended.isEmpty && guides.isNotEmpty && _search.text.trim().isEmpty)
                  Text(
                    'No guide matches your classes yet — you can choose any course below.',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
          if (_loading && _guides == null)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Try again')),
                ]),
              ),
            )
          else if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _search.text.isNotEmpty ? 'No course matches "${_search.text}".' : "No teacher's guides are available yet. Please check back soon.",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverLayoutBuilder(builder: (context, c) {
                final cols = c.crossAxisExtent > 1100 ? 3 : c.crossAxisExtent > 700 ? 2 : 1;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 268),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _GuideCard(
                      guide: list[i],
                      onRequest: () => _request(list[i]),
                      onCancel: list[i].request == null ? null : () => _cancel(list[i].request!),
                      onOpen: () => context.push('/teacher/guides/${list[i].courseId}'),
                    ),
                    childCount: list.length,
                  ),
                );
              }),
            ),
          if (showRecommended && others.isNotEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showAll = true),
                    icon: const Icon(Icons.expand_more),
                    label: Text('See ${others.length} more course${others.length > 1 ? 's' : ''} beyond your classes'),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Constrained extends StatelessWidget {
  final Widget child;
  const _Constrained({required this.child});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: child);
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final Widget? action;
  const _Banner({required this.color, required this.icon, required this.text, this.action});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.35))),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
        if (action != null) action!,
      ]),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final TeacherGuideSummary guide;
  final VoidCallback onRequest;
  final VoidCallback? onCancel;
  final VoidCallback onOpen;
  const _GuideCard({required this.guide, required this.onRequest, required this.onCancel, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final g = guide;
    final r = g.request;
    final hint = Theme.of(context).hintColor;

    Widget action;
    if (g.hasAccess) {
      action = FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
        onPressed: g.ready ? onOpen : null,
        icon: const Icon(Icons.menu_book, size: 18),
        label: Text(g.ready ? 'Open guide' : 'Guide coming soon'),
      );
    } else if (r != null && r.waiting) {
      action = Row(children: [
        const Expanded(child: _StatusPill(color: Color(0xFFF59E0B), text: 'Waiting for approval')),
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
      ]);
    } else {
      action = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        if (r != null && r.refused)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('Last request refused${r.adminNotes.isNotEmpty ? ': ${r.adminNotes}' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        FilledButton.icon(
          onPressed: onRequest,
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: Text(g.isFree ? 'Get this course (free)' : 'Get this course · RWF ${_money.format(g.price)}'),
        ),
      ]);
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: g.recommended ? BorderSide(color: AppTheme.primaryGreen.withOpacity(0.5)) : BorderSide.none),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: (g.thumbnail ?? '').isNotEmpty
                    ? NetworkImageWidget(imageUrl: g.thumbnail!, fit: BoxFit.cover)
                    : Container(color: AppTheme.primaryGreen.withOpacity(0.12), child: Icon(Icons.menu_book, color: AppTheme.primaryGreen)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text([if (g.subject.isNotEmpty) g.subject, if (g.category != null) g.category!].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: hint, fontSize: 12)),
              ]),
            ),
            if (g.recommended) Tooltip(message: 'Matches your classes', child: Icon(Icons.star, color: AppTheme.primaryGreen, size: 20)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final l in g.classLevels.take(6)) _Chip(l),
            if (!g.ready) const _Chip('Coming soon', color: Colors.orange),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: Text(g.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: hint, height: 1.3)),
          ),
          if (g.ready)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${g.chapters} chapters · ${g.lessons} lesson guides${g.videos > 0 ? ' · ${g.videos} videos' : ''}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          action,
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color? color;
  const _Chip(this.text, {this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF3B82F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String text;
  const _StatusPill({required this.color, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.hourglass_top_rounded, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13))),
      ]),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;
  const _CopyRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
      Expanded(child: SelectableText(value, style: const TextStyle(fontFamily: 'monospace'))),
      IconButton(
        tooltip: 'Copy',
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
        },
      ),
    ]);
  }
}

/// Free: one confirm. Paid: choose MTN MoMo / Airtel Money and a contact number.
class _RequestDialog extends StatefulWidget {
  final TeacherGuideSummary guide;
  final TeacherAccessService service;
  const _RequestDialog({required this.guide, required this.service});
  @override
  State<_RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<_RequestDialog> {
  String _method = 'mtn_momo';
  final _contact = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await widget.service.requestGuide(
        widget.guide.courseId,
        paymentMethod: widget.guide.isFree ? null : _method,
        contactInfo: _contact.text,
      );
      if (mounted) Navigator.pop(context, r);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guide;
    return AlertDialog(
      title: Text(g.title),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            g.isFree
                ? "This course's teacher's guide is free. An admin will approve your request."
                : "Price for teachers: RWF ${_money.format(g.price)}. Pay with mobile money; an admin approves your request once the payment is confirmed.",
          ),
          if (!g.isFree) ...[
            const SizedBox(height: 14),
            const Text('Payment method', style: TextStyle(fontWeight: FontWeight.w700)),
            RadioListTile<String>(contentPadding: EdgeInsets.zero, value: 'mtn_momo', groupValue: _method, onChanged: (v) => setState(() => _method = v!), title: const Text('MTN Mobile Money')),
            RadioListTile<String>(contentPadding: EdgeInsets.zero, value: 'airtel_money', groupValue: _method, onChanged: (v) => setState(() => _method = v!), title: const Text('Airtel Money')),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _contact,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number to contact you (optional)', border: OutlineInputBorder(), isDense: true),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send request'),
        ),
      ],
    );
  }
}
