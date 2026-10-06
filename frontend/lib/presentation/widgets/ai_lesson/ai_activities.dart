import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ai_study_guide.dart';

/// Interactive practice activities generated with each AI lesson:
/// match (drag meanings onto terms), order (drag steps into sequence),
/// categorize (drag items into groups) and fill_blanks (drag words into
/// sentences). Every drag also works as tap-to-select then tap-to-place, which
/// is easier on phones.
class AiActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final AiGuidePalette palette;
  const AiActivityCard({super.key, required this.activity, required this.palette});

  @override
  Widget build(BuildContext context) {
    final type = activity['type']?.toString() ?? '';
    final (icon, label, hint) = switch (type) {
      'match' => (Icons.link, 'Match', 'Drag each answer onto the term it belongs to.'),
      'order' => (Icons.format_list_numbered, 'Order', 'Drag the cards (or use the arrows) into the right order.'),
      'categorize' => (Icons.category_outlined, 'Sort', 'Drag every card into the right group.'),
      'fill_blanks' => (Icons.text_fields, 'Fill the gaps', 'Drag the words into the gaps.'),
      _ => (Icons.extension_outlined, 'Activity', ''),
    };
    final body = switch (type) {
      'match' => _MatchActivity(activity: activity, palette: palette),
      'order' => _OrderActivity(activity: activity, palette: palette),
      'categorize' => _CategorizeActivity(activity: activity, palette: palette),
      'fill_blanks' => _FillBlanksActivity(activity: activity, palette: palette),
      _ => const SizedBox.shrink(),
    };
    const violet = Color(0xFF7C3AED);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: violet.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: violet.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 14, color: violet),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: violet)),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(activity['title']?.toString() ?? '',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.text)),
            ),
          ]),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(hint, style: TextStyle(fontSize: 12.5, color: palette.muted)),
          ],
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }
}

List<String> _strings(dynamic v) => v is List ? v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList() : <String>[];

List<T> _shuffled<T>(List<T> list, String seed) {
  final copy = [...list];
  copy.shuffle(math.Random(seed.hashCode));
  return copy;
}

// ─── Shared drag-and-drop engine ─────────────────────────────────────────────

class _Chip {
  final int id;
  final String text;
  const _Chip(this.id, this.text);
}

class _Target {
  final String id;
  final String label;
  final int capacity;
  final List<String> accepts; // texts that are correct here
  const _Target(this.id, this.label, this.capacity, this.accepts);
}

/// Holds chip placements and checking for match / categorize / fill_blanks.
mixin _PlacementState<W extends StatefulWidget> on State<W> {
  late List<_Chip> chips;
  late List<_Target> targets;
  final Map<int, String> placed = {}; // chip id → target id
  int? selectedChip;
  bool checked = false;

  AiGuidePalette get palette;

  List<_Chip> chipsIn(String targetId) => chips.where((c) => placed[c.id] == targetId).toList();
  List<_Chip> get bank => chips.where((c) => !placed.containsKey(c.id)).toList();
  _Target target(String id) => targets.firstWhere((t) => t.id == id);

  void place(int chipId, String? targetId) {
    setState(() {
      checked = false;
      selectedChip = null;
      if (targetId == null) {
        placed.remove(chipId);
        return;
      }
      final t = target(targetId);
      final inside = chipsIn(targetId);
      if (inside.length >= t.capacity && placed[chipId] != targetId) {
        // Full single slot: swap the old chip back to the bank
        if (t.capacity != 1) return;
        placed.remove(inside.first.id);
      }
      placed[chipId] = targetId;
    });
  }

  bool isRight(_Chip c) {
    final t = placed[c.id];
    if (t == null) return false;
    final accepts = target(t).accepts.map((s) => s.toLowerCase()).toList();
    return accepts.contains(c.text.toLowerCase());
  }

  int get score => chips.where(isRight).length;

  void reset() => setState(() {
        placed.clear();
        selectedChip = null;
        checked = false;
      });

  Widget chipView(_Chip c, {bool inTarget = false}) {
    final selected = selectedChip == c.id;
    Color border = selected ? const Color(0xFF7C3AED) : palette.border;
    Color fill = palette.surface;
    if (checked && inTarget) {
      final ok = isRight(c);
      border = ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
      fill = (ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626)).withValues(alpha: palette.isDark ? 0.2 : 0.08);
    }
    final face = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: selected || (checked && inTarget) ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.drag_indicator, size: 16, color: palette.muted),
        const SizedBox(width: 4),
        Flexible(child: Text(c.text, style: TextStyle(fontSize: 13.5, color: palette.text, fontWeight: FontWeight.w500))),
        if (checked && inTarget) ...[
          const SizedBox(width: 6),
          Icon(isRight(c) ? Icons.check_circle : Icons.cancel, size: 16, color: isRight(c) ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
        ],
      ]),
    );
    return Draggable<int>(
      data: c.id,
      feedback: Material(color: Colors.transparent, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 320), child: Opacity(opacity: 0.9, child: face))),
      childWhenDragging: Opacity(opacity: 0.3, child: face),
      child: GestureDetector(
        onTap: () => setState(() {
          if (inTarget) {
            placed.remove(c.id);
            checked = false;
            selectedChip = null;
          } else {
            selectedChip = selectedChip == c.id ? null : c.id;
          }
        }),
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: face),
      ),
    );
  }

  /// A drop zone. [child] renders its contents.
  Widget dropZone(String targetId, Widget Function(bool hovering) child) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => place(d.data, targetId),
      builder: (context, candidates, _) => GestureDetector(
        onTap: selectedChip != null ? () => place(selectedChip!, targetId) : null,
        child: child(candidates.isNotEmpty || selectedChip != null),
      ),
    );
  }

  Widget bankView({String emptyText = 'All placed — press Check'}) {
    return DragTarget<int>(
      onAcceptWithDetails: (d) => place(d.data, null),
      builder: (context, candidates, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? const Color(0xFF7C3AED).withValues(alpha: 0.06) : palette.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: bank.isEmpty
            ? Text(emptyText, style: TextStyle(fontSize: 12.5, color: palette.muted, fontStyle: FontStyle.italic))
            : Wrap(spacing: 8, runSpacing: 8, children: bank.map((c) => chipView(c)).toList()),
      ),
    );
  }

  Widget footer({String Function(int score, int total)? message}) {
    final total = chips.length;
    final allPlaced = bank.isEmpty;
    final s = score;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(children: [
        if (checked)
          Expanded(
            child: Row(children: [
              Icon(s == total ? Icons.emoji_events : Icons.info_outline, color: s == total ? const Color(0xFFF59E0B) : palette.muted, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  message?.call(s, total) ?? (s == total ? 'Excellent — all $total correct!' : '$s of $total correct. Fix the red ones and check again.'),
                  style: TextStyle(fontWeight: FontWeight.w700, color: s == total ? const Color(0xFF16A34A) : palette.text),
                ),
              ),
            ]),
          )
        else
          Expanded(
            child: Text(
              allPlaced ? 'Ready to check' : '${total - bank.length} of $total placed',
              style: TextStyle(fontSize: 12.5, color: palette.muted),
            ),
          ),
        TextButton(onPressed: placed.isEmpty ? null : reset, child: const Text('Reset')),
        const SizedBox(width: 6),
        ElevatedButton(
          onPressed: allPlaced ? () => setState(() => checked = true) : null,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
          child: const Text('Check'),
        ),
      ]),
    );
  }
}

// ─── Match ───────────────────────────────────────────────────────────────────

class _MatchActivity extends StatefulWidget {
  final Map<String, dynamic> activity;
  final AiGuidePalette palette;
  const _MatchActivity({required this.activity, required this.palette});
  @override
  State<_MatchActivity> createState() => _MatchActivityState();
}

class _MatchActivityState extends State<_MatchActivity> with _PlacementState {
  @override
  AiGuidePalette get palette => widget.palette;

  @override
  void initState() {
    super.initState();
    final pairs = (widget.activity['pairs'] as List? ?? []).whereType<Map>().toList();
    targets = [for (var i = 0; i < pairs.length; i++) _Target('t$i', '${pairs[i]['left']}', 1, ['${pairs[i]['right']}'])];
    chips = _shuffled([for (var i = 0; i < pairs.length; i++) _Chip(i, '${pairs[i]['right']}')], '${widget.activity['title']}');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final t in targets)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 520;
            final label = Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: p.accentSoft.withValues(alpha: p.isDark ? 0.5 : 1), borderRadius: BorderRadius.circular(10)),
              child: Text(t.label, style: TextStyle(fontWeight: FontWeight.w700, color: p.text, fontSize: 13.5)),
            );
            final slot = dropZone(t.id, (hover) {
              final inside = chipsIn(t.id);
              return Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: hover ? const Color(0xFF7C3AED).withValues(alpha: 0.06) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: hover ? const Color(0xFF7C3AED) : p.border, style: BorderStyle.solid),
                ),
                alignment: Alignment.centerLeft,
                child: inside.isEmpty
                    ? Padding(padding: const EdgeInsets.all(8), child: Text('Drop the answer here', style: TextStyle(color: p.muted, fontSize: 12.5)))
                    : chipView(inside.first, inTarget: true),
              );
            });
            return narrow
                ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [label, const SizedBox(height: 6), slot])
                : Row(children: [
                    Expanded(flex: 2, child: label),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 18, color: p.muted)),
                    Expanded(flex: 3, child: slot),
                  ]);
          }),
        ),
      const SizedBox(height: 6),
      bankView(),
      footer(),
    ]);
  }
}

// ─── Categorize ──────────────────────────────────────────────────────────────

class _CategorizeActivity extends StatefulWidget {
  final Map<String, dynamic> activity;
  final AiGuidePalette palette;
  const _CategorizeActivity({required this.activity, required this.palette});
  @override
  State<_CategorizeActivity> createState() => _CategorizeActivityState();
}

class _CategorizeActivityState extends State<_CategorizeActivity> with _PlacementState {
  @override
  AiGuidePalette get palette => widget.palette;

  @override
  void initState() {
    super.initState();
    final cats = (widget.activity['categories'] as List? ?? []).whereType<Map>().toList();
    targets = [for (var i = 0; i < cats.length; i++) _Target('c$i', '${cats[i]['name']}', 99, _strings(cats[i]['items']))];
    var id = 0;
    chips = _shuffled([for (final t in targets) for (final it in t.accepts) _Chip(id++, it)], '${widget.activity['title']}');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    const colors = [Color(0xFF16A34A), Color(0xFF2563EB), Color(0xFFEA580C), Color(0xFFDB2777)];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      bankView(),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 700 ? math.min(targets.length, 4) : c.maxWidth >= 420 ? 2 : 1;
        final w = (c.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (var i = 0; i < targets.length; i++)
            SizedBox(
              width: w,
              child: dropZone(targets[i].id, (hover) {
                final color = colors[i % colors.length];
                return Container(
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: hover ? 0.14 : (p.isDark ? 0.12 : 0.05)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: hover ? 1 : 0.45), width: hover ? 2 : 1),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(targets[i].label, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: chipsIn(targets[i].id).map((ch) => chipView(ch, inTarget: true)).toList()),
                  ]),
                );
              }),
            ),
        ]);
      }),
      footer(),
    ]);
  }
}

// ─── Fill the blanks ─────────────────────────────────────────────────────────

class _FillBlanksActivity extends StatefulWidget {
  final Map<String, dynamic> activity;
  final AiGuidePalette palette;
  const _FillBlanksActivity({required this.activity, required this.palette});
  @override
  State<_FillBlanksActivity> createState() => _FillBlanksActivityState();
}

class _FillBlanksActivityState extends State<_FillBlanksActivity> with _PlacementState {
  late List<String> _segments; // text pieces; blanks are "\u0000<index>"

  @override
  AiGuidePalette get palette => widget.palette;

  @override
  void initState() {
    super.initState();
    final text = widget.activity['text']?.toString() ?? '';
    final re = RegExp(r'\[\[([^\]]+)\]\]');
    _segments = [];
    targets = [];
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) _segments.add(text.substring(last, m.start));
      final i = targets.length;
      targets.add(_Target('b$i', '', 1, [m.group(1)!.trim()]));
      _segments.add('\u0000$i');
      last = m.end;
    }
    if (last < text.length) _segments.add(text.substring(last));
    var id = 0;
    final words = [...targets.map((t) => t.accepts.first), ..._strings(widget.activity['distractors'])];
    chips = _shuffled([for (final w in words) _Chip(id++, w)], text);
  }

  // Distractors never need placing, so "all placed" means every blank is filled.
  @override
  List<_Chip> get bank => chips.where((c) => !placed.containsKey(c.id)).toList();

  @override
  int get score => targets.where((t) => chipsIn(t.id).any(isRight)).length;

  @override
  Widget footer({String Function(int score, int total)? message}) {
    final total = targets.length;
    final filled = targets.where((t) => chipsIn(t.id).isNotEmpty).length;
    final s = score;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(children: [
        Expanded(
          child: checked
              ? Text(s == total ? 'Excellent — every gap is right!' : '$s of $total gaps correct. Try again.',
                  style: TextStyle(fontWeight: FontWeight.w700, color: s == total ? const Color(0xFF16A34A) : palette.text))
              : Text('$filled of $total gaps filled', style: TextStyle(fontSize: 12.5, color: palette.muted)),
        ),
        TextButton(onPressed: placed.isEmpty ? null : reset, child: const Text('Reset')),
        const SizedBox(width: 6),
        ElevatedButton(
          onPressed: filled == total ? () => setState(() => checked = true) : null,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
          child: const Text('Check'),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final style = TextStyle(fontSize: 15, height: 2.1, color: p.text);
    final pieces = <Widget>[];
    for (final seg in _segments) {
      if (seg.startsWith('\u0000')) {
        final t = targets[int.parse(seg.substring(1))];
        pieces.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: dropZone(t.id, (hover) {
            final inside = chipsIn(t.id);
            return Container(
              constraints: const BoxConstraints(minWidth: 90, minHeight: 38),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: hover ? const Color(0xFF7C3AED).withValues(alpha: 0.08) : p.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border(bottom: BorderSide(color: hover ? const Color(0xFF7C3AED) : p.muted, width: 2)),
              ),
              child: inside.isEmpty ? const SizedBox(width: 86, height: 34) : chipView(inside.first, inTarget: true),
            );
          }),
        ));
      } else {
        for (final word in seg.split(RegExp(r'(?<=\s)'))) {
          if (word.isNotEmpty) pieces.add(Text(word, style: style));
        }
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: pieces),
      const SizedBox(height: 14),
      bankView(emptyText: 'All words used'),
      footer(),
    ]);
  }
}

// ─── Order ───────────────────────────────────────────────────────────────────

class _OrderActivity extends StatefulWidget {
  final Map<String, dynamic> activity;
  final AiGuidePalette palette;
  const _OrderActivity({required this.activity, required this.palette});
  @override
  State<_OrderActivity> createState() => _OrderActivityState();
}

class _OrderActivityState extends State<_OrderActivity> {
  late final List<String> _correct = _strings(widget.activity['items']);
  late List<String> _current;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _current = _shuffled(_correct, '${widget.activity['title']}');
    // Never start already solved
    if (_current.join('|') == _correct.join('|') && _current.length > 1) {
      _current = [..._current.reversed];
    }
  }

  void _move(int from, int to) => setState(() {
        _checked = false;
        final item = _current.removeAt(from);
        _current.insert(to, item);
      });

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final score = [for (var i = 0; i < _current.length; i++) _current[i] == _correct[i]].where((x) => x).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _current.length,
        onReorder: (from, to) => _move(from, to > from ? to - 1 : to),
        proxyDecorator: (child, _, __) => Material(color: Colors.transparent, elevation: 6, child: child),
        itemBuilder: (context, i) {
          final ok = _current[i] == _correct[i];
          final color = !_checked ? p.border : ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
          return Container(
            key: ValueKey(_current[i]),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _checked ? color.withValues(alpha: p.isDark ? 0.18 : 0.06) : p.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: _checked ? 2 : 1),
            ),
            child: Row(children: [
              ReorderableDragStartListener(
                index: i,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(padding: const EdgeInsets.all(10), child: Icon(Icons.drag_indicator, color: p.muted)),
                ),
              ),
              CircleAvatar(radius: 12, backgroundColor: const Color(0xFF7C3AED), child: Text('${i + 1}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700))),
              const SizedBox(width: 10),
              Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(_current[i], style: TextStyle(color: p.text, fontSize: 13.5)))),
              IconButton(visualDensity: VisualDensity.compact, tooltip: 'Move up', onPressed: i > 0 ? () => _move(i, i - 1) : null, icon: const Icon(Icons.keyboard_arrow_up)),
              IconButton(visualDensity: VisualDensity.compact, tooltip: 'Move down', onPressed: i < _current.length - 1 ? () => _move(i, i + 1) : null, icon: const Icon(Icons.keyboard_arrow_down)),
            ]),
          );
        },
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Expanded(
            child: _checked
                ? Text(score == _correct.length ? 'Perfect order!' : '$score of ${_correct.length} in the right place.',
                    style: TextStyle(fontWeight: FontWeight.w700, color: score == _correct.length ? const Color(0xFF16A34A) : p.text))
                : const SizedBox.shrink(),
          ),
          if (_checked && score != _correct.length)
            TextButton(onPressed: () => setState(() => _current = [..._correct]), child: const Text('Show answer')),
          ElevatedButton(
            onPressed: () => setState(() => _checked = true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
            child: const Text('Check'),
          ),
        ]),
      ),
    ]);
  }
}
