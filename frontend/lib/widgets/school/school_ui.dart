import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import 'school_i18n.dart';

export 'school_i18n.dart';

/// Shared building blocks for the school screens (super admin, head teacher,
/// teachers, students, parents) so they look and behave the same.

enum Tone { neutral, good, warn, bad, info }

Color toneColor(BuildContext context, Tone t) {
  switch (t) {
    case Tone.good:
      return AppTheme.successColor;
    case Tone.warn:
      return AppTheme.warningColor;
    case Tone.bad:
      return AppTheme.errorColor;
    case Tone.info:
      return AppTheme.infoColor;
    case Tone.neutral:
      return AppTheme.getSecondaryTextColor(context);
  }
}

final _date = DateFormat('d MMM yyyy');
final _dateShort = DateFormat('EEE d MMM');
final _dateTime = DateFormat('d MMM, HH:mm');

DateTime? parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v).toLocal();
  return DateTime.tryParse(v.toString())?.toLocal();
}

String fmtDate(dynamic v) {
  final d = parseDate(v);
  return d == null ? '—' : _date.format(d);
}

String fmtDay(dynamic v) {
  final d = parseDate(v);
  return d == null ? '—' : _dateShort.format(d);
}

String fmtDateTime(dynamic v) {
  final d = parseDate(v);
  return d == null ? '—' : _dateTime.format(d);
}

String fmtMoney(num? v, [String currency = 'RWF']) =>
    '$currency ${NumberFormat.decimalPattern().format(v ?? 0)}';

/// "in 3 days", "2 days ago", "today".
String relativeDay(dynamic v) {
  final d = parseDate(v);
  if (d == null) return '—';
  final today = DateTime.now();
  final diff = DateTime(d.year, d.month, d.day).difference(DateTime(today.year, today.month, today.day)).inDays;
  if (diff == 0) return 'today';
  if (diff == 1) return 'tomorrow';
  if (diff == -1) return 'yesterday';
  return diff > 0 ? 'in $diff days' : '${-diff} days ago';
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(SnackBar(
    content: Text(trSchool(context, message)),
    behavior: SnackBarBehavior.floating,
    backgroundColor: error ? AppTheme.errorColor : null,
  ));
}

Future<bool> confirm(BuildContext context, {required String title, required String message, String confirmLabel = 'Confirm', bool destructive = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(trSchool(ctx, title)),
      content: Text(trSchool(ctx, message)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const T('Cancel')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppTheme.errorColor) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(trSchool(ctx, confirmLabel)),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Shows sign-in details ONCE (generated password / student code + PIN) with copy buttons.
Future<void> showCredentialsDialog(
  BuildContext context, {
  required String title,
  required List<MapEntry<String, String>> rows,
  String note = 'Write these down or copy them now. For security they will not be shown again — you can create new ones later.',
  List<Widget> extra = const [],
}) {
  final all = rows.map((r) => '${r.key}: ${r.value}').join('\n');
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(trSchool(ctx, title)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.getBorderColor(ctx)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(trSchool(ctx, r.key), style: TextStyle(fontSize: 12, color: AppTheme.getSecondaryTextColor(ctx))),
                          const SizedBox(height: 2),
                          SelectableText(r.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                        ]),
                      ),
                      IconButton(
                        tooltip: 'Copy',
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: r.value));
                          showSnack(ctx, '${r.key} copied');
                        },
                      ),
                    ]),
                  ),
                ),
              ...extra,
              const SizedBox(height: 4),
              Text(trSchool(ctx, note), style: TextStyle(fontSize: 12, color: AppTheme.getSecondaryTextColor(ctx))),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy_all_rounded, size: 18),
          label: const T('Copy all'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: all));
            showSnack(ctx, 'Copied');
          },
        ),
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const T('Done')),
      ],
    ),
  );
}

/// White card with a thin border and an optional header row.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.subtitle, this.trailing, required this.child, this.padding = const EdgeInsets.all(16)});

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Own semantics node, so a tappable row inside a card does not absorb
    // the whole page into one "button" for screen readers.
    return Semantics(container: true, explicitChildNodes: true, child: Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.6)),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(children: [
              Expanded(
                child: Semantics(container: true, header: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(trSchool(context, title!), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context))),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(trSchool(context, subtitle!), style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context))),
                  ],
                ])),
              ),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 12),
          ],
          Semantics(container: true, child: child),
        ],
      ),
    ));
  }
}

/// Number + label tile used on dashboards.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.tone = Tone.info, this.caption, this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final Tone tone;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = toneColor(context, tone);
    return Material(
      color: AppTheme.getCardColor(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.6)),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: c, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context))),
                Text(trSchool(context, label), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: AppTheme.getSecondaryTextColor(context))),
                if (caption != null)
                  Text(trSchool(context, caption!), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: c)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Responsive grid of [StatTile]s.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 900 ? 4 : c.maxWidth > 560 ? 3 : 2;
      const gap = 12.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [for (final ch in children) SizedBox(width: w, child: ch)]);
    });
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, this.tone = Tone.neutral, this.icon});
  final String text;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: c), const SizedBox(width: 4)],
        Text(trSchool(context, text), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c)),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 44, color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(trSchool(context, title), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context))),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(trSchool(context, message!), textAlign: TextAlign.center, style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ]),
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load',
        message: message,
        action: OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const T('Try again')),
      );
}

/// Loads a future and shows loading / error / content; call [reload] via the key.
class AsyncBody<T> extends StatefulWidget {
  const AsyncBody({super.key, required this.load, required this.builder});
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  @override
  State<AsyncBody<T>> createState() => AsyncBodyState<T>();
}

class AsyncBodyState<T> extends State<AsyncBody<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final d = await widget.load();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    if (_error != null && _data == null) return ErrorRetry(message: _error.toString(), onRetry: reload);
    return widget.builder(context, _data as T, reload);
  }
}

/// Small labelled progress bar (syllabus coverage, hand-in rate…).
class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.percent, this.label, this.tone});
  final int? percent;
  final String? label;
  final Tone? tone;

  @override
  Widget build(BuildContext context) {
    final p = (percent ?? 0).clamp(0, 100);
    final t = tone ?? (percent == null ? Tone.neutral : p >= 60 ? Tone.good : p >= 30 ? Tone.warn : Tone.bad);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      if (label != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Expanded(child: Text(trSchool(context, label!), style: TextStyle(fontSize: 12.5, color: AppTheme.getSecondaryTextColor(context)))),
            Text(percent == null ? '—' : '$p%', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context))),
          ]),
        ),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: percent == null ? 0 : p / 100,
          minHeight: 6,
          backgroundColor: AppTheme.getBorderColor(context).withValues(alpha: 0.4),
          color: toneColor(context, t),
        ),
      ),
    ]);
  }
}

/// Page frame used by school screens: max width, padding, pull to refresh.
class SchoolPage extends StatelessWidget {
  const SchoolPage({super.key, required this.children, this.onRefresh, this.maxWidth = 1100});
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width < 600 ? 12.0 : 20.0;
    final list = ListView(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                children[i],
              ],
            ]),
          ),
        ),
      ],
    );
    return onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

/// Province → districts of Rwanda (for address pickers).
const rwandaDistricts = <String, List<String>>{
  'Kigali City': ['Gasabo', 'Kicukiro', 'Nyarugenge'],
  'Eastern': ['Bugesera', 'Gatsibo', 'Kayonza', 'Kirehe', 'Ngoma', 'Nyagatare', 'Rwamagana'],
  'Northern': ['Burera', 'Gakenke', 'Gicumbi', 'Musanze', 'Rulindo'],
  'Southern': ['Gisagara', 'Huye', 'Kamonyi', 'Muhanga', 'Nyamagabe', 'Nyanza', 'Nyaruguru', 'Ruhango'],
  'Western': ['Karongi', 'Ngororero', 'Nyabihu', 'Nyamasheke', 'Rubavu', 'Rusizi', 'Rutsiro'],
};

/// Levels taught in Rwandan schools.
const schoolLevels = ['N1', 'N2', 'N3', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'L3', 'L4', 'L5'];

/// Common A-level combinations.
const commonCombinations = ['MPC', 'MCB', 'PCB', 'MEG', 'MPG', 'HEG', 'HGL', 'HEL', 'LKF', 'MCE', 'BCG', 'PCM', 'ACC', 'SWD', 'NIT'];

/// Common subjects.
const commonSubjects = [
  'Mathematics', 'English', 'Kinyarwanda', 'French', 'Kiswahili', 'Physics', 'Chemistry', 'Biology',
  'Geography', 'History', 'Entrepreneurship', 'Computer Science', 'ICT', 'Economics', 'Literature',
  'General Studies', 'Religion', 'Physical Education', 'Music', 'Fine Art', 'Social Studies', 'Science and Elementary Technology',
];

/// Address inputs (province/district dropdowns + sector, cell, village).
class AddressFields extends StatefulWidget {
  const AddressFields({super.key, required this.value, required this.onChanged});
  final Map<String, String> value;
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<AddressFields> createState() => _AddressFieldsState();
}

class _AddressFieldsState extends State<AddressFields> {
  late final Map<String, String> _v = Map.of(widget.value);
  late final _sector = TextEditingController(text: _v['sector'] ?? '');
  late final _cell = TextEditingController(text: _v['cell'] ?? '');
  late final _village = TextEditingController(text: _v['village'] ?? '');

  void _set(String k, String? v) {
    setState(() {
      if (v == null || v.trim().isEmpty) {
        _v.remove(k);
      } else {
        _v[k] = v.trim();
      }
    });
    widget.onChanged(Map.of(_v));
  }

  @override
  void dispose() {
    _sector.dispose();
    _cell.dispose();
    _village.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final province = rwandaDistricts.containsKey(_v['province']) ? _v['province'] : null;
    final districts = province == null ? <String>[] : rwandaDistricts[province]!;
    final district = districts.contains(_v['district']) ? _v['district'] : null;
    return LayoutBuilder(builder: (context, c) {
      final two = c.maxWidth > 520;
      Widget pair(Widget a, Widget b) => two
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)])
          : Column(children: [a, const SizedBox(height: 12), b]);
      return Column(children: [
        pair(
          DropdownButtonFormField<String>(
            initialValue: province,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Province', prefixIcon: Icon(Icons.map_outlined)),
            items: [for (final p in rwandaDistricts.keys) DropdownMenuItem(value: p, child: Text(p))],
            onChanged: (v) {
              _set('province', v);
              _set('district', null);
            },
          ),
          DropdownButtonFormField<String>(
            key: ValueKey(province),
            initialValue: district,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'District', prefixIcon: Icon(Icons.location_city_outlined)),
            items: [for (final d in districts) DropdownMenuItem(value: d, child: Text(d))],
            onChanged: province == null ? null : (v) => _set('district', v),
          ),
        ),
        const SizedBox(height: 12),
        pair(
          TextFormField(controller: _sector, decoration: const InputDecoration(labelText: 'Sector'), onChanged: (v) => _set('sector', v)),
          TextFormField(controller: _cell, decoration: const InputDecoration(labelText: 'Cell'), onChanged: (v) => _set('cell', v)),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _village, decoration: const InputDecoration(labelText: 'Village / street'), onChanged: (v) => _set('village', v)),
      ]);
    });
  }
}

String addressLine(dynamic a) {
  if (a is! Map) return '';
  return ['village', 'cell', 'sector', 'district', 'province'].map((k) => a[k]).where((v) => v != null && v.toString().isNotEmpty).join(', ');
}

/// Wraps choice chips for multi-select lists (subjects, levels…).
class ChipPicker extends StatelessWidget {
  const ChipPicker({super.key, required this.options, required this.selected, required this.onChanged, this.allowCustom = false, this.customLabel = 'Add other'});
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool allowCustom;
  final String customLabel;

  @override
  Widget build(BuildContext context) {
    final all = {...options, ...selected}.toList();
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final o in all)
        FilterChip(
          label: Text(o),
          selected: selected.contains(o),
          onSelected: (v) {
            final next = Set<String>.of(selected);
            v ? next.add(o) : next.remove(o);
            onChanged(next);
          },
        ),
      if (allowCustom)
        ActionChip(
          avatar: const Icon(Icons.add, size: 16),
          label: Text(customLabel),
          onPressed: () async {
            final c = TextEditingController();
            final v = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(customLabel),
                content: TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.words, onSubmitted: (s) => Navigator.pop(ctx, s)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Add')),
                ],
              ),
            );
            if (v != null && v.trim().isNotEmpty) onChanged({...selected, v.trim()});
          },
        ),
    ]);
  }
}
