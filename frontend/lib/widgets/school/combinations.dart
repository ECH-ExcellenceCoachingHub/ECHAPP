import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import 'school_ui.dart';

/// A-level streams / combinations and TVET trades, grouped so schools pick by
/// name instead of guessing codes. The code is what appears in class names
/// ("S4 MS-PURE A", "L4 SOD A") and is stored on the class.
class Combination {
  const Combination(this.code, this.name, [this.detail = '']);
  final String code;
  final String name;
  final String detail;
}

class CombinationGroup {
  const CombinationGroup(this.title, this.subtitle, this.icon, this.items, {this.tvet = false});
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Combination> items;
  final bool tvet;
}

const combinationGroups = <CombinationGroup>[
  // ── New REB streams (upper secondary) ──
  CombinationGroup('New REB streams', 'Upper secondary (S4–S6), new curriculum', Icons.auto_awesome_outlined, [
    Combination('MS-PURE', 'Mathematics & Sciences: Pure Sciences', 'Maths, Physics, Chemistry, Biology. Replaces MCB, PCB, PCM. Route to medicine, pharmacy, nursing, lab science.'),
    Combination('MS-APPLIED', 'Mathematics & Sciences: Applied Sciences', 'Maths, Economics, Physics, Geography, Chemistry. Replaces MEG, MCE, MPC, MPG. Route to engineering, economics, data, finance.'),
    Combination('ARTS-HUM', 'Arts & Humanities', 'History, Geography, Literature in English, Psychology. Replaces HGLE, HLP.'),
    Combination('LANGUAGES', 'Languages', 'Kinyarwanda, English, French, Kiswahili. Replaces LFK and language combinations.'),
  ]),
  // ── Previous combinations (still used by classes started before the change) ──
  CombinationGroup('Previous combinations: sciences', 'Old A-level curriculum', Icons.science_outlined, [
    Combination('MPC', 'Mathematics, Physics, Computer Science'),
    Combination('MCB', 'Mathematics, Chemistry, Biology'),
    Combination('PCB', 'Physics, Chemistry, Biology'),
    Combination('PCM', 'Physics, Chemistry, Mathematics'),
    Combination('MPG', 'Mathematics, Physics, Geography'),
    Combination('MEG', 'Mathematics, Economics, Geography'),
    Combination('MCE', 'Mathematics, Computer Science, Economics'),
    Combination('BCG', 'Biology, Chemistry, Geography'),
  ]),
  CombinationGroup('Previous combinations: humanities & languages', 'Old A-level curriculum', Icons.menu_book_outlined, [
    Combination('HEG', 'History, Economics, Geography'),
    Combination('HGL', 'History, Geography, Literature'),
    Combination('HEL', 'History, Economics, Literature'),
    Combination('HGLE', 'History, Geography, Literature, Economics'),
    Combination('HLP', 'History, Literature, Psychology'),
    Combination('LFK', 'Literature, French, Kinyarwanda'),
    Combination('LKF', 'Literature, Kinyarwanda, French'),
    Combination('LEK', 'Literature, English, Kiswahili'),
  ]),
  // ── TVET trades (RTB, Level 3–5) ──
  CombinationGroup('TVET: ICT & multimedia', 'Level 3–5 trades', Icons.computer_outlined, [
    Combination('SOD', 'Software Development'),
    Combination('SWD', 'Software Development (old code)'),
    Combination('CSA', 'Computer Systems & Architecture'),
    Combination('NIT', 'Networking & Internet Technology'),
    Combination('MMP', 'Multimedia Production'),
    Combination('GDP', 'Graphic Design & Printing'),
  ], tvet: true),
  CombinationGroup('TVET: electricity, electronics & energy', 'Level 3–5 trades', Icons.bolt_outlined, [
    Combination('ELT', 'Electrical Technology'),
    Combination('ETE', 'Electronics & Telecommunication'),
    Combination('REN', 'Renewable Energy (solar)'),
    Combination('ACR', 'Air Conditioning & Refrigeration'),
  ], tvet: true),
  CombinationGroup('TVET: construction & building', 'Level 3–5 trades', Icons.foundation_outlined, [
    Combination('BDC', 'Building Construction'),
    Combination('PWO', 'Public Works'),
    Combination('LSV', 'Land Surveying'),
    Combination('MAS', 'Masonry'),
    Combination('PLT', 'Plumbing Technology'),
    Combination('CAR', 'Carpentry'),
    Combination('WOT', 'Wood Technology'),
    Combination('IND', 'Interior Design'),
  ], tvet: true),
  CombinationGroup('TVET: mechanical, automotive & mining', 'Level 3–5 trades', Icons.precision_manufacturing_outlined, [
    Combination('AUT', 'Automobile Technology'),
    Combination('MAT', 'Manufacturing Technology'),
    Combination('WEL', 'Welding & Metal Fabrication'),
    Combination('MIN', 'Mining Technology'),
  ], tvet: true),
  CombinationGroup('TVET: hospitality & tourism', 'Level 3–5 trades', Icons.restaurant_outlined, [
    Combination('TOR', 'Tourism'),
    Combination('FBO', 'Food & Beverage Operations'),
    Combination('CUA', 'Culinary Arts'),
    Combination('FOH', 'Front Office & Housekeeping'),
  ], tvet: true),
  CombinationGroup('TVET: agriculture & food', 'Level 3–5 trades', Icons.agriculture_outlined, [
    Combination('CRP', 'Crop Production'),
    Combination('ANH', 'Animal Health'),
    Combination('FOP', 'Food Processing'),
    Combination('IRD', 'Irrigation & Drainage'),
    Combination('FOR', 'Forestry'),
  ], tvet: true),
  CombinationGroup('TVET: business, arts & services', 'Level 3–5 trades', Icons.storefront_outlined, [
    Combination('ACC', 'Accounting'),
    Combination('FAD', 'Fashion Design'),
    Combination('HAB', 'Hairdressing & Beauty'),
    Combination('FAR', 'Fine Arts & Crafts'),
  ], tvet: true),
];

final Map<String, Combination> _byCode = {for (final g in combinationGroups) for (final c in g.items) c.code: c};

/// Full name of a code ("MS-PURE" → "Mathematics & Sciences: Pure Sciences"), or null.
String? combinationName(String? code) => code == null ? null : _byCode[code.toUpperCase()]?.name;

/// Every known code (old helper lists use this).
List<String> get allCombinationCodes => _byCode.keys.toList();

bool _isTvetLevel(String? level) => level != null && level.toUpperCase().startsWith('L');

/// Opens a searchable, grouped picker. Single choice returns one code ('' = none);
/// [multi] returns the chosen set. [level] puts TVET trades first for L3–L5.
Future<Set<String>?> showCombinationPicker(
  BuildContext context, {
  Set<String> selected = const {},
  bool multi = false,
  String? level,
  List<String> extra = const [],
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _PickerSheet(selected: selected, multi: multi, level: level, extra: extra),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.selected, required this.multi, this.level, this.extra = const []});
  final Set<String> selected;
  final bool multi;
  final String? level;
  final List<String> extra;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late final Set<String> _sel = {...widget.selected};
  String _q = '';

  void _tap(String code) {
    if (!widget.multi) {
      Navigator.pop(context, {code});
      return;
    }
    setState(() => _sel.contains(code) ? _sel.remove(code) : _sel.add(code));
  }

  Future<void> _custom() async {
    final t = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const T('Other combination or trade'),
        content: TextField(
          controller: t,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(hintText: trSchool(ctx, 'Short code, e.g. MEG')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const T('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, t.text), child: const T('Use')),
        ],
      ),
    );
    final code = v?.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '-') ?? '';
    if (code.isEmpty || !mounted) return;
    _tap(code);
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    final q = _q.trim().toLowerCase();
    bool match(Combination c) => q.isEmpty || '${c.code} ${c.name} ${c.detail}'.toLowerCase().contains(q);
    final tvetFirst = _isTvetLevel(widget.level);
    final groups = [...combinationGroups]..sort((a, b) => (a.tvet == tvetFirst ? 0 : 1).compareTo(b.tvet == tvetFirst ? 0 : 1));
    final customs = {...widget.extra, ...widget.selected}.where((c) => c.isNotEmpty && !_byCode.containsKey(c)).toList();

    Widget tile(Combination c) {
      final on = _sel.contains(c.code);
      return Semantics(
        container: true,
        button: true,
        selected: on,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _tap(c.code),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 74,
                padding: const EdgeInsets.symmetric(vertical: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(c.code, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: on ? Colors.white : AppTheme.primaryDark)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(trSchool(context, c.name), style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context))),
                  if (c.detail.isNotEmpty) Text(trSchool(context, c.detail), style: TextStyle(fontSize: 12.5, color: muted, height: 1.3)),
                ]),
              ),
              if (widget.multi)
                Icon(on ? Icons.check_box : Icons.check_box_outline_blank, color: on ? AppTheme.primary : muted)
              else if (on)
                const Icon(Icons.check_circle, color: AppTheme.primary),
            ]),
          ),
        ),
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            T(widget.multi ? 'Combinations and trades you offer' : 'Choose a combination or trade', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: trSchool(context, 'Search by name or code'), isDense: true),
              onChanged: (v) => setState(() => _q = v),
            ),
          ]),
        ),
        Expanded(
          child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), children: [
            if (!widget.multi && q.isEmpty)
              ListTile(leading: const Icon(Icons.block), title: const T('None (no combination)'), onTap: () => Navigator.pop(context, <String>{''})),
            for (final g in groups)
              if (g.items.any(match)) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 4),
                  child: Row(children: [
                    Icon(g.icon, size: 18, color: AppTheme.primaryDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(trSchool(context, g.title), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(trSchool(context, g.subtitle), style: TextStyle(fontSize: 12, color: muted)),
                      ]),
                    ),
                  ]),
                ),
                for (final c in g.items.where(match)) tile(c),
              ],
            if (customs.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.fromLTRB(6, 14, 6, 4), child: T('Added by your school', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
              for (final c in customs) tile(Combination(c, c)),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _custom, icon: const Icon(Icons.add), label: const T('Other (type a code)')),
          ]),
        ),
        if (widget.multi)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.pop(context, _sel),
                icon: const Icon(Icons.check),
                label: T('Use ${_sel.length} selected'),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Shows the chosen codes with their names, and a button that opens the picker.
class CombinationField extends StatelessWidget {
  const CombinationField({super.key, required this.selected, required this.onChanged, this.multi = true, this.level, this.extra = const []});
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool multi;
  final String? level;
  final List<String> extra;

  @override
  Widget build(BuildContext context) {
    final chosen = selected.where((c) => c.isNotEmpty).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (chosen.isNotEmpty)
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in chosen)
            InputChip(
              label: Text(combinationName(c) != null ? '$c · ${trSchool(context, combinationName(c)!)}' : c),
              onDeleted: () => onChanged({...selected}..remove(c)),
            ),
        ]),
      if (chosen.isNotEmpty) const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () async {
            final r = await showCombinationPicker(context, selected: selected, multi: multi, level: level, extra: extra);
            if (r != null) onChanged(r);
          },
          icon: Icon(chosen.isEmpty ? Icons.add : Icons.edit_outlined),
          label: T(chosen.isEmpty ? (multi ? 'Choose combinations and trades' : 'Choose combination or trade') : (multi ? 'Change' : 'Change')),
        ),
      ),
    ]);
  }
}
