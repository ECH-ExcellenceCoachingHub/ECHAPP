import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../utils/media_proxy.dart';
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

/// "1 student", "3 students".
String plural(num? n, String one, [String? many]) => '${n ?? 0} ${(n ?? 0) == 1 ? one : (many ?? '${one}s')}';

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

/// Soft card used by every school page: optional icon badge, title, subtitle
/// and a trailing action. On phones the trailing action moves under the title
/// so titles are never squeezed.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.subtitle, this.trailing, this.icon, this.tone = Tone.info, required this.child, this.padding = const EdgeInsets.all(16)});

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final Tone tone;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = toneColor(context, tone);
    Widget header(bool narrow) {
      final titleBlock = Semantics(
        container: true,
        header: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(trSchool(context, title!), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context), height: 1.25)),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(trSchool(context, subtitle!), style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context), height: 1.35)),
          ],
        ]),
      );
      final row = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: c, size: 20),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(child: titleBlock),
        if (trailing != null && !narrow) ...[const SizedBox(width: 8), trailing!],
      ]);
      if (trailing == null || !narrow) return row;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [row, const SizedBox(height: 8), trailing!]);
    }

    // Own semantics node, so a tappable row inside a card does not absorb
    // the whole page into one "button" for screen readers.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        decoration: cardDecoration(context),
        padding: padding,
        child: LayoutBuilder(builder: (context, box) {
          // Icon-only actions (menus) stay on the title row even on phones.
          final narrow = box.maxWidth < 420 && trailing is! PopupMenuButton && trailing is! IconButton;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[header(narrow), const SizedBox(height: 14)],
              Semantics(container: true, child: child),
            ],
          );
        }),
      ),
    );
  }
}

/// The card look shared by school widgets: soft border + light shadow.
BoxDecoration cardDecoration(BuildContext context, {Color? borderColor, double radius = 16}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: AppTheme.getCardColor(context),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? AppTheme.getBorderColor(context).withValues(alpha: dark ? 0.5 : 0.45)),
    boxShadow: dark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 10, offset: const Offset(0, 2))],
  );
}

/// Coloured page header: title, subtitle, a leading avatar/icon, info chips
/// and actions. Used at the top of the main school pages.
class PageHero extends StatelessWidget {
  const PageHero({super.key, required this.title, this.subtitle, this.leading, this.chips = const [], this.actions = const [], this.colors});
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> chips;
  final List<Widget> actions;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final cols = colors ?? const [AppTheme.primary, AppTheme.primaryDark];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: cols, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: cols.last.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(
                  header: true,
                  child: Text(trSchool(context, title), style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700, height: 1.2)),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(trSchool(context, subtitle!), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5, height: 1.3)),
                ],
              ]),
            ),
          ]),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ]),
      ),
    );
  }
}

/// Translucent chip for [PageHero] ("S3 A", "Term paid"…).
class HeroChip extends StatelessWidget {
  const HeroChip(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 15, color: Colors.white), const SizedBox(width: 5)],
          Text(trSchool(context, text), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ]),
      );
}

/// White button for [PageHero].
class HeroButton extends StatelessWidget {
  const HeroButton({super.key, required this.label, required this.icon, required this.onPressed, this.filled = true});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) => filled
      ? FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryDark, minimumSize: const Size(0, 42)),
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
          label: Text(trSchool(context, label)),
        )
      : OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withValues(alpha: 0.6)), minimumSize: const Size(0, 42)),
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
          label: Text(trSchool(context, label)),
        );
}

/// Brand-coloured style for SegmentedButton (the theme default is blue).
ButtonStyle schoolSegmentStyle(BuildContext context) => ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppTheme.primary.withValues(alpha: 0.16) : null),
      foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppTheme.primaryDark : AppTheme.getTextColor(context)),
      side: WidgetStatePropertyAll(BorderSide(color: AppTheme.getBorderColor(context))),
      textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
    );

/// Filter chip in the brand colour (the theme default is blue).
class PillChoice extends StatelessWidget {
  const PillChoice({super.key, required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: 18, color: selected ? AppTheme.primaryDark : AppTheme.getSecondaryTextColor(context)),
        label: Text(trSchool(context, label)),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppTheme.primary.withValues(alpha: 0.16),
        side: BorderSide(color: selected ? AppTheme.primary : AppTheme.getBorderColor(context)),
        labelStyle: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppTheme.primaryDark : AppTheme.getTextColor(context)),
        onSelected: (_) => onTap(),
      );
}

/// One action for [ActionBar].
class BarAction {
  const BarAction(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

/// Page actions: on wide screens a row of buttons; on phones the main action
/// fills the width and the others go into a "More" menu, so nothing wraps
/// into a wall of buttons or overflows.
class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.primary, this.more = const [], this.leading});
  final BarAction? primary;
  final List<BarAction> more;
  /// Optional text on the left on wide screens ("12 classes · 340 students").
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final narrow = box.maxWidth < 560;
      final main = primary == null
          ? null
          : FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: primary!.onPressed,
              icon: Icon(primary!.icon),
              label: Text(trSchool(context, primary!.label), overflow: TextOverflow.ellipsis),
            );
      if (!narrow) {
        final buttons = Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
          for (final a in more)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                side: BorderSide(color: AppTheme.getBorderColor(context)),
                textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              onPressed: a.onPressed,
              icon: Icon(a.icon),
              label: Text(trSchool(context, a.label)),
            ),
          if (main != null) main,
        ]);
        if (leading == null) return Align(alignment: Alignment.centerRight, child: buttons);
        return Row(children: [Expanded(child: leading!), const SizedBox(width: 12), Flexible(flex: 2, child: buttons)]);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (leading != null) ...[leading!, const SizedBox(height: 10)],
        Row(children: [
          if (main != null) Expanded(child: main),
          if (more.isNotEmpty) ...[
            if (main != null) const SizedBox(width: 8),
            PopupMenuButton<int>(
              tooltip: trSchool(context, 'More'),
              onSelected: (i) => more[i].onPressed?.call(),
              itemBuilder: (_) => [
                for (var i = 0; i < more.length; i++)
                  PopupMenuItem(
                    value: i,
                    enabled: more[i].onPressed != null,
                    child: Row(children: [Icon(more[i].icon, size: 20), const SizedBox(width: 12), Flexible(child: Text(trSchool(context, more[i].label)))]),
                  ),
              ],
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(border: Border.all(color: AppTheme.getBorderColor(context)), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (main == null) ...[Text(trSchool(context, 'Actions')), const SizedBox(width: 6)],
                  const Icon(Icons.more_horiz),
                ]),
              ),
            ),
          ],
        ]),
      ]);
    });
  }
}

/// A tappable row inside a card: avatar/icon, title, subtitle, pills under the
/// subtitle (never beside the title, so phones keep the title readable) and
/// an optional trailing widget (menu, chevron, button).
class EntityTile extends StatelessWidget {
  const EntityTile({super.key, required this.title, this.subtitle, this.leading, this.pills = const [], this.trailing, this.onTap, this.dense = false});
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> pills;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    return Semantics(
      container: true,
      button: onTap != null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dense ? 8 : 11, horizontal: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trSchool(context, title), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.getTextColor(context))),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(trSchool(context, subtitle!), style: TextStyle(fontSize: 13, color: muted, height: 1.35)),
                ],
                if (pills.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: pills),
                ],
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!] else if (onTap != null) Icon(Icons.chevron_right, color: muted),
          ]),
        ),
      ),
    );
  }
}

String _initials(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
}

/// Round initials avatar in the brand colour.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.radius = 20, this.tone});
  final String? name;
  final double radius;
  final Tone? tone;

  @override
  Widget build(BuildContext context) {
    final c = tone == null ? AppTheme.primary : toneColor(context, tone!);
    return CircleAvatar(
      radius: radius,
      backgroundColor: c.withValues(alpha: 0.13),
      child: Text(_initials(name), style: TextStyle(fontWeight: FontWeight.w700, color: c, fontSize: radius * 0.68)),
    );
  }
}

/// One number for [MiniStats].
class MiniStat {
  const MiniStat(this.value, this.label, {this.tone = Tone.neutral, this.onTap});
  final String value;
  final String label;
  final Tone tone;
  final VoidCallback? onTap;
}

/// A row of small numbers in one card ("3 To do · 1 Overdue · …"). Fits four
/// numbers on a 360 px phone, unlike big tiles.
class MiniStats extends StatelessWidget {
  const MiniStats({super.key, required this.items});
  final List<MiniStat> items;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    return Container(
      decoration: cardDecoration(context),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: IntrinsicHeight(
        child: Row(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) VerticalDivider(width: 1, thickness: 1, color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
            Expanded(
              child: Semantics(
                container: true,
                button: items[i].onTap != null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: items[i].onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(items[i].value,
                          maxLines: 1,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: items[i].tone == Tone.neutral ? AppTheme.getTextColor(context) : toneColor(context, items[i].tone))),
                      const SizedBox(height: 2),
                      Text(trSchool(context, items[i].label), maxLines: 2, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: muted, height: 1.2)),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Thin divider used between rows inside a card.
class RowDivider extends StatelessWidget {
  const RowDivider({super.key});
  @override
  Widget build(BuildContext context) => Divider(height: 1, color: AppTheme.getBorderColor(context).withValues(alpha: 0.4));
}

/// Number + label tile used on dashboards. Narrow tiles (phones) stack the
/// icon above the number so long labels still fit.
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
    final badge = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
      child: Icon(icon, color: c, size: 21),
    );
    final texts = <Widget>[
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppTheme.getTextColor(context), height: 1.15)),
      const SizedBox(height: 2),
      Text(trSchool(context, label), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: AppTheme.getSecondaryTextColor(context), height: 1.25)),
      if (caption != null && caption!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(trSchool(context, caption!), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c)),
        ),
    ];
    return Semantics(
      container: true,
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: cardDecoration(context),
            padding: const EdgeInsets.all(14),
            child: (_StatWidth.of(context) ?? MediaQuery.sizeOf(context).width / 2) < 175
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [badge, const SizedBox(height: 10), ...texts])
                : Row(children: [
                    badge,
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: texts)),
                    if (onTap != null) Icon(Icons.chevron_right, size: 18, color: AppTheme.getSecondaryTextColor(context)),
                  ]),
          ),
        ),
      ),
    );
  }
}

/// Responsive grid of [StatTile]s (2 columns on phones, up to 4 on wide).
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children, this.maxColumns = 4});
  final List<Widget> children;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth > 900 ? 4 : c.maxWidth > 560 ? 3 : 2).clamp(1, maxColumns);
      const gap = 12.0;
      final tileWidth = (c.maxWidth - gap * (cols - 1)) / cols;
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += cols) {
        final slice = children.sublist(i, (i + cols).clamp(0, children.length));
        rows.add(IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var j = 0; j < cols; j++) ...[
              if (j > 0) const SizedBox(width: gap),
              Expanded(child: j < slice.length ? slice[j] : const SizedBox.shrink()),
            ],
          ]),
        ));
      }
      return _StatWidth(
        width: tileWidth,
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: gap), rows[i]],
        ]),
      );
    });
  }
}

/// Tile width from [StatGrid], so tiles pick a layout without measuring themselves.
class _StatWidth extends InheritedWidget {
  const _StatWidth({required this.width, required super.child});
  final double width;
  static double? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_StatWidth>()?.width;
  @override
  bool updateShouldNotify(_StatWidth old) => old.width != width;
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
        // Flexible: long pills (flag messages) wrap instead of overflowing on phones.
        Flexible(child: Text(trSchool(context, text), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c, height: 1.3))),
      ]),
    );
  }
}

/// Course picture with a soft placeholder.
class CourseThumb extends StatelessWidget {
  const CourseThumb({super.key, this.url, this.size = 56, this.width, this.radius = 10});
  final String? url;
  final double size;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppTheme.primary.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child: Icon(Icons.menu_book_rounded, color: AppTheme.primary.withValues(alpha: 0.7), size: size * 0.42),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width ?? size,
        height: size,
        child: (url == null || url!.isEmpty)
            ? placeholder
            : Image.network(mediaProxyUrl(url), fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
      ),
    );
  }
}

/// Course card for school students ("My courses"): picture on top, title, subject.
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, required this.onTap});
  final Map<String, dynamic> course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subject = '${course['subject'] ?? ''}';
    return Semantics(
      container: true,
      button: true,
      child: Material(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.6)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: LayoutBuilder(builder: (context, c) => CourseThumb(url: course['thumbnail'] as String?, size: c.maxHeight, width: c.maxWidth, radius: 0)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (subject.isNotEmpty)
                    Text(trSchool(context, subject).toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppTheme.primary)),
                  const SizedBox(height: 2),
                  Text('${course['title']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context), height: 1.25)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Soft coloured note at the top of a page ("You are helping your child…").
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.icon = Icons.info_outline, this.tone = Tone.info});
  final String text;
  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.22)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(trSchool(context, text), style: TextStyle(color: AppTheme.getTextColor(context), height: 1.35))),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 34, color: AppTheme.primary.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 14),
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
    final pad = MediaQuery.of(context).size.width < 600 ? 14.0 : 24.0;
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(pad, pad, pad, 40),
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

/// Rwanda's administrative units (province → district → sector → cell →
/// villages), loaded once from assets/rwanda_locations.json (~190 KB).
class RwandaLocations {
  RwandaLocations._(this._tree);
  final Map<String, dynamic> _tree;
  static Future<RwandaLocations>? _loading;

  static Future<RwandaLocations> load() => _loading ??= rootBundle.loadString('assets/rwanda_locations.json').then((raw) {
        final m = Map<String, dynamic>.from(json.decode(raw) as Map)..remove('_source');
        return RwandaLocations._(m);
      });

  static List<String> _keys(dynamic m) => m is Map ? (m.keys.map((e) => '$e').toList()..sort()) : const [];
  static dynamic _get(dynamic m, String? k) {
    if (m is! Map || k == null) return null;
    if (m.containsKey(k)) return m[k];
    final lk = k.toLowerCase();
    for (final e in m.entries) {
      if ('${e.key}'.toLowerCase() == lk) return e.value;
    }
    return null;
  }

  List<String> provinces() => rwandaDistricts.keys.toList();
  List<String> districts(String? p) => _keys(_get(_tree, p));
  List<String> sectors(String? p, String? d) => _keys(_get(_get(_tree, p), d));
  List<String> cells(String? p, String? d, String? s) => _keys(_get(_get(_get(_tree, p), d), s));
  List<String> villages(String? p, String? d, String? s, String? c) {
    final v = _get(_get(_get(_get(_tree, p), d), s), c);
    return v is List ? (v.map((e) => '$e').toList()..sort()) : const [];
  }
}

/// Address inputs: Province → District → Sector → Cell → Village. Each list
/// depends on the one above and can be searched by typing. A name missing
/// from the official list can still be typed.
class AddressFields extends StatefulWidget {
  const AddressFields({super.key, required this.value, required this.onChanged});
  final Map<String, String> value;
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<AddressFields> createState() => _AddressFieldsState();
}

class _AddressFieldsState extends State<AddressFields> {
  static const _order = ['province', 'district', 'sector', 'cell', 'village'];
  late final Map<String, String> _v = Map.of(widget.value);
  RwandaLocations? _loc;

  @override
  void initState() {
    super.initState();
    RwandaLocations.load().then((l) {
      if (mounted) setState(() => _loc = l);
    }).catchError((_) {});
  }

  /// Sets one level and clears the levels below it.
  void _set(String k, String? v) {
    setState(() {
      final old = _v[k];
      if (v == null || v.trim().isEmpty) {
        _v.remove(k);
      } else {
        _v[k] = v.trim();
      }
      if ((old ?? '').toLowerCase() != (_v[k] ?? '').toLowerCase()) {
        for (final below in _order.skip(_order.indexOf(k) + 1)) {
          _v.remove(below);
        }
      }
    });
    widget.onChanged(Map.of(_v));
  }

  List<String> _options(String k) {
    final l = _loc;
    if (k == 'province') return rwandaDistricts.keys.toList();
    if (k == 'district') {
      final fromData = l?.districts(_v['province']) ?? const <String>[];
      return fromData.isNotEmpty ? fromData : (rwandaDistricts[_v['province']] ?? const []);
    }
    if (l == null) return const [];
    return switch (k) {
      'sector' => l.sectors(_v['province'], _v['district']),
      'cell' => l.cells(_v['province'], _v['district'], _v['sector']),
      _ => l.villages(_v['province'], _v['district'], _v['sector'], _v['cell']),
    };
  }

  Widget _field(String k, String label, IconData icon) {
    final i = _order.indexOf(k);
    final parent = i == 0 ? null : _order[i - 1];
    final enabled = parent == null || (_v[parent] ?? '').isNotEmpty;
    final options = _options(k);
    // The key changes with the parent's value, so the field resets when a level above changes.
    final parentPath = _order.take(i).map((e) => _v[e] ?? '').join('|');
    return _PlaceField(
      key: ValueKey('$k:$parentPath:${options.length}'),
      label: label,
      icon: icon,
      options: options,
      value: _v[k],
      enabled: enabled,
      hint: enabled ? null : 'Choose the $parent first',
      onChanged: (v) => _set(k, v),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final two = c.maxWidth > 520;
      Widget pair(Widget a, Widget b) => two
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)])
          : Column(children: [a, const SizedBox(height: 12), b]);
      return Column(children: [
        pair(_field('province', 'Province', Icons.map_outlined), _field('district', 'District', Icons.location_city_outlined)),
        const SizedBox(height: 12),
        pair(_field('sector', 'Sector', Icons.holiday_village_outlined), _field('cell', 'Cell', Icons.grid_view_outlined)),
        const SizedBox(height: 12),
        _field('village', 'Village', Icons.home_outlined),
      ]);
    });
  }
}

/// A dropdown you can type into: filters the list, and keeps typed text that
/// is not in the list (unknown village names).
class _PlaceField extends StatefulWidget {
  const _PlaceField({super.key, required this.label, required this.icon, required this.options, required this.value, required this.enabled, required this.onChanged, this.hint});
  final String label;
  final IconData icon;
  final List<String> options;
  final String? value;
  final bool enabled;
  final String? hint;
  final ValueChanged<String?> onChanged;

  @override
  State<_PlaceField> createState() => _PlaceFieldState();
}

class _PlaceFieldState extends State<_PlaceField> {
  late final _ctrl = TextEditingController(text: _match(widget.value) ?? widget.value ?? '');
  final _focus = FocusNode();

  String? _match(String? v) {
    if (v == null) return null;
    for (final o in widget.options) {
      if (o.toLowerCase() == v.toLowerCase()) return o;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Typed text that is not in the list is saved when the field loses focus.
    _focus.addListener(() {
      if (_focus.hasFocus) return;
      final t = _ctrl.text.trim();
      if (t != (widget.value ?? '')) widget.onChanged(_match(t) ?? (t.isEmpty ? null : t));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = trSchool(context, widget.label);
    if (widget.options.isEmpty) {
      // No list (data not loaded yet, or an unknown place above): plain text.
      return TextField(
        controller: _ctrl,
        focusNode: _focus,
        enabled: widget.enabled,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(widget.icon), helperText: widget.hint == null ? null : trSchool(context, widget.hint!)),
      );
    }
    return DropdownMenu<String>(
      controller: _ctrl,
      focusNode: _focus,
      enabled: widget.enabled,
      initialSelection: _match(widget.value),
      enableFilter: true,
      requestFocusOnTap: true,
      expandedInsets: EdgeInsets.zero,
      menuHeight: 320,
      label: Text(label),
      leadingIcon: Icon(widget.icon),
      helperText: widget.hint == null ? null : trSchool(context, widget.hint!),
      dropdownMenuEntries: [for (final o in widget.options) DropdownMenuEntry(value: o, label: o)],
      onSelected: (v) => widget.onChanged(v),
    );
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
