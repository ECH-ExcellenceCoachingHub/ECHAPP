import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Colours used by the study guide so it fits the host screen (light/dark).
class AiGuidePalette {
  final Color text;
  final Color muted;
  final Color surface;
  final Color bg;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final bool isDark;

  const AiGuidePalette({
    required this.text,
    required this.muted,
    required this.surface,
    required this.bg,
    required this.border,
    this.accent = const Color(0xFF16A34A),
    this.accentSoft = const Color(0xFFDCFCE7),
    this.isDark = false,
  });

  factory AiGuidePalette.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const AiGuidePalette(
            text: Color(0xFFF1F5F9),
            muted: Color(0xFF94A3B8),
            surface: Color(0xFF1E293B),
            bg: Color(0xFF0F172A),
            border: Color(0xFF334155),
            accent: Color(0xFF22C55E),
            accentSoft: Color(0xFF14532D),
            isDark: true,
          )
        : const AiGuidePalette(
            text: Color(0xFF111827),
            muted: Color(0xFF6B7280),
            surface: Colors.white,
            bg: Color(0xFFF8FAF9),
            border: Color(0xFFE5E7EB),
          );
  }
}

// Series colours for charts / diagrams — readable in both themes.
const _seriesColors = [
  Color(0xFF16A34A),
  Color(0xFF2563EB),
  Color(0xFFEA580C),
  Color(0xFF9333EA),
  Color(0xFF0891B2),
  Color(0xFFDB2777),
];

List<Map<String, dynamic>> _maps(dynamic v) =>
    (v is List) ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
List<String> _strings(dynamic v) => (v is List) ? v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList() : <String>[];
String _s(dynamic v) => v?.toString() ?? '';

/// Renders the structured AI lesson content: summary, objectives, notes,
/// visuals, key points, terms, formulas, examples, exam tips, flashcards and
/// book sources.
class AiStudyGuideView extends StatefulWidget {
  final Map<String, dynamic> content;
  final AiGuidePalette? palette;
  final String pageLabel;

  /// Called with a prompt when the learner taps "Ask AI" on a term/example.
  final void Function(String prompt)? onAskAi;

  const AiStudyGuideView({
    super.key,
    required this.content,
    this.palette,
    this.pageLabel = 'p.',
    this.onAskAi,
  });

  @override
  State<AiStudyGuideView> createState() => _AiStudyGuideViewState();
}

class _AiStudyGuideViewState extends State<AiStudyGuideView> {
  final _keys = <String, GlobalKey>{};

  GlobalKey _key(String id) => _keys.putIfAbsent(id, () => GlobalKey());

  void _jump(String id) {
    final ctx = _keys[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic, alignment: 0.05);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette ?? AiGuidePalette.of(context);
    final c = widget.content;
    final objectives = _strings(c['learningObjectives']);
    final notes = _s(c['notes']);
    final visuals = _maps(c['visuals']);
    final keyPoints = _strings(c['keyPoints']);
    final terms = _maps(c['keyTerms']);
    final formulas = _maps(c['formulas']);
    final examples = _maps(c['examples']);
    final tips = _strings(c['examTips']);
    final mistakes = _strings(c['commonMistakes']);
    final cards = _maps(c['flashcards']);
    final sources = _maps(c['sources']);

    final nav = <(String, String, IconData)>[
      if (notes.isNotEmpty) ('notes', 'Notes', Icons.article_outlined),
      if (visuals.isNotEmpty) ('visuals', 'Visuals', Icons.insights_outlined),
      if (keyPoints.isNotEmpty) ('points', 'Key points', Icons.push_pin_outlined),
      if (terms.isNotEmpty) ('terms', 'Key terms', Icons.menu_book_outlined),
      if (formulas.isNotEmpty) ('formulas', 'Formulas', Icons.functions),
      if (examples.isNotEmpty) ('examples', 'Examples', Icons.lightbulb_outline),
      if (tips.isNotEmpty || mistakes.isNotEmpty) ('tips', 'Exam tips', Icons.tips_and_updates_outlined),
      if (cards.isNotEmpty) ('cards', 'Flashcards', Icons.style_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryHero(content: c, palette: p, sources: sources, pageLabel: widget.pageLabel),
        if (nav.length > 2) ...[
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: nav
                  .map((n) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(n.$3, size: 16, color: p.accent),
                          label: Text(n.$2, style: TextStyle(fontSize: 12.5, color: p.text, fontWeight: FontWeight.w600)),
                          backgroundColor: p.surface,
                          side: BorderSide(color: p.border),
                          onPressed: () => _jump(n.$1),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        if (objectives.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            palette: p,
            icon: Icons.flag_outlined,
            title: 'What you will learn',
            child: Column(
              children: objectives
                  .map((o) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle, size: 18, color: p.accent),
                            const SizedBox(width: 10),
                            Expanded(child: Text(o, style: TextStyle(fontSize: 14, height: 1.5, color: p.text))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            key: _key('notes'),
            palette: p,
            icon: Icons.article_outlined,
            title: 'Lesson notes',
            child: AiMarkdown(data: notes, palette: p),
          ),
        ],
        if (visuals.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(key: _key('visuals')),
          ...visuals.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AiVisualCard(visual: v, palette: p),
              )),
        ],
        if (keyPoints.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            key: _key('points'),
            palette: p,
            icon: Icons.push_pin_outlined,
            title: 'Key points to remember',
            child: Column(
              children: keyPoints.asMap().entries.map((e) => _NumberedRow(index: e.key + 1, text: e.value, palette: p)).toList(),
            ),
          ),
        ],
        if (terms.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            key: _key('terms'),
            palette: p,
            icon: Icons.menu_book_outlined,
            title: 'Key terms',
            child: _KeyTerms(terms: terms, palette: p, pageLabel: widget.pageLabel, onAskAi: widget.onAskAi),
          ),
        ],
        if (formulas.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(key: _key('formulas')),
          ...formulas.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FormulaCard(formula: f, palette: p, pageLabel: widget.pageLabel),
              )),
        ],
        if (examples.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            key: _key('examples'),
            palette: p,
            icon: Icons.lightbulb_outline,
            title: 'Worked examples',
            child: Column(
              children: examples
                  .asMap()
                  .entries
                  .map((e) => _ExampleTile(example: e.value, index: e.key + 1, palette: p, pageLabel: widget.pageLabel, onAskAi: widget.onAskAi))
                  .toList(),
            ),
          ),
        ],
        if (tips.isNotEmpty || mistakes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(key: _key('tips')),
          if (tips.isNotEmpty)
            _Callout(palette: p, color: const Color(0xFF2563EB), icon: Icons.tips_and_updates_outlined, title: 'Exam tips', items: tips),
          if (tips.isNotEmpty && mistakes.isNotEmpty) const SizedBox(height: 12),
          if (mistakes.isNotEmpty)
            _Callout(palette: p, color: const Color(0xFFDC2626), icon: Icons.report_gmailerrorred_outlined, title: 'Common mistakes', items: mistakes),
        ],
        if (cards.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            key: _key('cards'),
            palette: p,
            icon: Icons.style_outlined,
            title: 'Flashcards',
            trailing: Text('${cards.length} cards', style: TextStyle(fontSize: 12, color: p.muted)),
            child: _Flashcards(cards: cards, palette: p),
          ),
        ],
      ],
    );
  }
}

// ─── Building blocks ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final AiGuidePalette palette;
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Card({super.key, required this.palette, required this.icon, required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: palette.accent),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.text))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  final Map<String, dynamic> content;
  final AiGuidePalette palette;
  final List<Map<String, dynamic>> sources;
  final String pageLabel;

  const _SummaryHero({required this.content, required this.palette, required this.sources, required this.pageLabel});

  @override
  Widget build(BuildContext context) {
    final summary = _s(content['summary']);
    final minutes = content['estimatedMinutes'];
    final pages = sources.map((s) => s['page']).whereType<num>().map((n) => n.toInt()).toSet().toList()..sort();
    final isRevision = content['kind'] == 'revision';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.isDark
              ? [const Color(0xFF14532D), const Color(0xFF1E293B)]
              : [const Color(0xFFDCFCE7), const Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.isDark ? palette.border : const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(icon: Icons.auto_awesome, label: isRevision ? 'Revision sheet' : 'Study guide', palette: palette),
              if (minutes is num) _Pill(icon: Icons.schedule, label: '${minutes.toInt()} min read', palette: palette),
              if (pages.isNotEmpty)
                _Pill(
                  icon: Icons.menu_book_outlined,
                  label: 'Book ${pageLabel == 'p.' ? 'pages' : 'parts'} ${_pageRange(pages)}',
                  palette: palette,
                ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(summary, style: TextStyle(fontSize: 15.5, height: 1.6, color: palette.text, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }

  static String _pageRange(List<int> pages) {
    if (pages.length <= 3) return pages.join(', ');
    return '${pages.first}–${pages.last}';
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final AiGuidePalette palette;
  const _Pill({required this.icon, required this.label, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: palette.isDark ? 0.6 : 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.accent),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.text)),
        ],
      ),
    );
  }
}

class _NumberedRow extends StatelessWidget {
  final int index;
  final String text;
  final AiGuidePalette palette;
  const _NumberedRow({required this.index, required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
            child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(text, style: TextStyle(fontSize: 14, height: 1.55, color: palette.text)),
          )),
        ],
      ),
    );
  }
}

/// Markdown with the guide's typography.
class AiMarkdown extends StatelessWidget {
  final String data;
  final AiGuidePalette palette;
  const AiMarkdown({super.key, required this.data, required this.palette});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        h1: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: palette.text, height: 1.35),
        h2: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: palette.text, height: 1.4),
        h3: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: palette.accent, height: 1.4),
        p: TextStyle(fontSize: 14.5, color: palette.text, height: 1.75),
        listBullet: TextStyle(fontSize: 14.5, color: palette.accent, fontWeight: FontWeight.w700),
        strong: TextStyle(fontWeight: FontWeight.w700, color: palette.text),
        code: TextStyle(fontSize: 13, fontFamily: 'monospace', color: const Color(0xFFEA580C), backgroundColor: palette.bg),
        codeblockDecoration: BoxDecoration(color: palette.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: palette.border)),
        blockquoteDecoration: BoxDecoration(
          color: palette.accentSoft.withValues(alpha: palette.isDark ? 0.4 : 1),
          border: Border(left: BorderSide(color: palette.accent, width: 4)),
          borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
        ),
        tableHead: TextStyle(fontWeight: FontWeight.w700, color: palette.text, fontSize: 13.5),
        tableBody: TextStyle(color: palette.text, fontSize: 13.5),
        tableBorder: TableBorder.all(color: palette.border),
        tableCellsPadding: const EdgeInsets.all(8),
        h2Padding: const EdgeInsets.only(top: 12),
        h3Padding: const EdgeInsets.only(top: 8),
      ),
    );
  }
}

class _KeyTerms extends StatelessWidget {
  final List<Map<String, dynamic>> terms;
  final AiGuidePalette palette;
  final String pageLabel;
  final void Function(String prompt)? onAskAi;
  const _KeyTerms({required this.terms, required this.palette, required this.pageLabel, this.onAskAi});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final twoCols = c.maxWidth >= 560;
      final width = twoCols ? (c.maxWidth - 12) / 2 : c.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: terms.map((t) {
          final page = t['page'];
          return SizedBox(
            width: width,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: palette.accent, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(_s(t['term']), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: palette.text))),
                      if (page is num) Text('$pageLabel ${page.toInt()}', style: TextStyle(fontSize: 11, color: palette.muted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_s(t['definition']), style: TextStyle(fontSize: 13.5, height: 1.5, color: palette.text)),
                  if (onAskAi != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: palette.accent),
                        onPressed: () => onAskAi!('Explain "${_s(t['term'])}" in simple words with an everyday example.'),
                        icon: const Icon(Icons.auto_awesome, size: 14),
                        label: const Text('Explain more', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _FormulaCard extends StatelessWidget {
  final Map<String, dynamic> formula;
  final AiGuidePalette palette;
  final String pageLabel;
  const _FormulaCard({required this.formula, required this.palette, required this.pageLabel});

  @override
  Widget build(BuildContext context) {
    final vars = _maps(formula['variables']);
    final page = formula['page'];
    const purple = Color(0xFF7C3AED);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.functions, color: purple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_s(formula['name']).isEmpty ? 'Formula' : _s(formula['name']),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.text)),
              ),
              if (page is num) Text('$pageLabel ${page.toInt()}', style: TextStyle(fontSize: 11, color: palette.muted)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: purple.withValues(alpha: palette.isDark ? 0.18 : 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                _s(formula['expression']),
                style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w600, color: palette.isDark ? const Color(0xFFC4B5FD) : purple),
              ),
            ),
          ),
          if (vars.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...vars.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(_s(v['symbol']), style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: palette.text)),
                      ),
                      Expanded(child: Text(_s(v['meaning']), style: TextStyle(fontSize: 13.5, color: palette.muted, height: 1.4))),
                    ],
                  ),
                )),
          ],
          if (_s(formula['explanation']).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_s(formula['explanation']), style: TextStyle(fontSize: 13.5, height: 1.55, color: palette.text)),
          ],
        ],
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  final Map<String, dynamic> example;
  final int index;
  final AiGuidePalette palette;
  final String pageLabel;
  final void Function(String prompt)? onAskAi;
  const _ExampleTile({required this.example, required this.index, required this.palette, required this.pageLabel, this.onAskAi});

  @override
  Widget build(BuildContext context) {
    final page = example['page'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: index == 1,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: palette.accent,
          collapsedIconColor: palette.muted,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFFEF3C7),
            child: Text('$index', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
          ),
          title: Text(_s(example['title']).isEmpty ? 'Example $index' : _s(example['title']),
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: palette.text)),
          subtitle: page is num ? Text('From $pageLabel ${page.toInt()}', style: TextStyle(fontSize: 11.5, color: palette.muted)) : null,
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AiMarkdown(data: _s(example['body']), palette: palette),
            if (onAskAi != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: palette.accent),
                  onPressed: () => onAskAi!('Walk me through this example step by step:\n\n${_s(example['title'])}\n${_s(example['body'])}'),
                  icon: const Icon(Icons.auto_awesome, size: 15),
                  label: const Text('Walk me through it'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  final AiGuidePalette palette;
  final Color color;
  final IconData icon;
  final String title;
  final List<String> items;
  const _Callout({required this.palette, required this.color, required this.icon, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.text)),
          ]),
          const SizedBox(height: 10),
          ...items.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 6, color: color)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t, style: TextStyle(fontSize: 13.5, height: 1.55, color: palette.text))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Flashcards extends StatefulWidget {
  final List<Map<String, dynamic>> cards;
  final AiGuidePalette palette;
  const _Flashcards({required this.cards, required this.palette});

  @override
  State<_Flashcards> createState() => _FlashcardsState();
}

class _FlashcardsState extends State<_Flashcards> {
  int _index = 0;
  bool _showBack = false;
  final Set<int> _known = {};

  void _go(int delta) {
    setState(() {
      _index = (_index + delta).clamp(0, widget.cards.length - 1);
      _showBack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final card = widget.cards[_index];
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showBack = !_showBack),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) {
              final rotate = Tween(begin: math.pi / 2, end: 0.0).animate(anim);
              return AnimatedBuilder(
                animation: rotate,
                child: child,
                builder: (context, child) => Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(rotate.value),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey('$_index-$_showBack'),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 170),
              padding: const EdgeInsets.all(22),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _showBack
                      ? [const Color(0xFF2563EB), const Color(0xFF4F46E5)]
                      : [const Color(0xFF16A34A), const Color(0xFF0D9488)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_showBack ? 'ANSWER' : 'QUESTION',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(
                    _s(_showBack ? card['back'] : card['front']),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.45, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(_showBack ? 'Tap to see the question' : 'Tap to reveal',
                      style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(onPressed: _index > 0 ? () => _go(-1) : null, icon: const Icon(Icons.chevron_left), color: p.text),
            Expanded(
              child: Column(
                children: [
                  Text('${_index + 1} / ${widget.cards.length}   ·   ${_known.length} known',
                      style: TextStyle(fontSize: 12.5, color: p.muted)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_index + 1) / widget.cards.length,
                      minHeight: 4,
                      backgroundColor: p.border,
                      color: p.accent,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'I know this',
              onPressed: () {
                setState(() => _known.add(_index));
                if (_index < widget.cards.length - 1) _go(1);
              },
              icon: Icon(_known.contains(_index) ? Icons.check_circle : Icons.check_circle_outline, color: p.accent),
            ),
            IconButton(onPressed: _index < widget.cards.length - 1 ? () => _go(1) : null, icon: const Icon(Icons.chevron_right), color: p.text),
          ],
        ),
      ],
    );
  }
}

// ─── Visuals ──────────────────────────────────────────────────────────────────

/// Renders one AI visual spec: flow, cycle, comparison, timeline, hierarchy or chart.
class AiVisualCard extends StatelessWidget {
  final Map<String, dynamic> visual;
  final AiGuidePalette palette;
  const AiVisualCard({super.key, required this.visual, required this.palette});

  @override
  Widget build(BuildContext context) {
    final type = _s(visual['type']);
    final (icon, label) = switch (type) {
      'flow' => (Icons.account_tree_outlined, 'Process'),
      'cycle' => (Icons.autorenew, 'Cycle'),
      'comparison' => (Icons.compare_arrows, 'Comparison'),
      'timeline' => (Icons.timeline, 'Timeline'),
      'hierarchy' => (Icons.hub_outlined, 'Concept map'),
      'chart' => (Icons.bar_chart, 'Chart'),
      _ => (Icons.insights_outlined, 'Visual'),
    };
    final body = switch (type) {
      'flow' => _FlowVisual(steps: _maps(visual['steps']), palette: palette),
      'cycle' => _CycleVisual(steps: _maps(visual['steps']), palette: palette),
      'comparison' => _ComparisonVisual(columns: _strings(visual['columns']), rows: (visual['rows'] as List? ?? []).whereType<List>().map((r) => r.map(_s).toList()).toList(), palette: palette),
      'timeline' => _TimelineVisual(events: _maps(visual['events']), palette: palette),
      'hierarchy' => _HierarchyVisual(root: _s(visual['root']), children: _maps(visual['children']), palette: palette),
      'chart' => _ChartVisual(visual: visual, palette: palette),
      _ => const SizedBox.shrink(),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 14, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(_s(visual['title']), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.text))),
            ],
          ),
          const SizedBox(height: 16),
          body,
          if (_s(visual['caption']).isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_s(visual['caption']), style: TextStyle(fontSize: 12, color: palette.muted, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _FlowVisual extends StatelessWidget {
  final List<Map<String, dynamic>> steps;
  final AiGuidePalette palette;
  const _FlowVisual({required this.steps, required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final horizontal = c.maxWidth >= 640 && steps.length <= 5;
      if (horizontal) {
        final children = <Widget>[];
        for (var i = 0; i < steps.length; i++) {
          children.add(Expanded(child: _stepBox(i, steps[i], center: true)));
          if (i < steps.length - 1) {
            children.add(Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward_rounded, color: palette.accent),
            ));
          }
        }
        return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
      }
      return Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _stepBox(i, steps[i]),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Icon(Icons.arrow_downward_rounded, color: palette.accent, size: 20),
              ),
          ],
        ],
      );
    });
  }

  Widget _stepBox(int i, Map<String, dynamic> step, {bool center = false}) {
    final color = _seriesColors[i % _seriesColors.length];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: center ? MainAxisSize.min : MainAxisSize.max,
            children: [
              CircleAvatar(radius: 11, backgroundColor: color, child: Text('${i + 1}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              Flexible(child: Text(_s(step['label']), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: palette.text))),
            ],
          ),
          if (_s(step['detail']).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_s(step['detail']), textAlign: center ? TextAlign.center : TextAlign.start, style: TextStyle(fontSize: 12.5, height: 1.45, color: palette.muted)),
          ],
        ],
      ),
    );
  }
}

class _CycleVisual extends StatelessWidget {
  final List<Map<String, dynamic>> steps;
  final AiGuidePalette palette;
  const _CycleVisual({required this.steps, required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 460 || steps.length > 8) {
        return Column(
          children: [
            _FlowVisual(steps: steps, palette: palette),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.autorenew, size: 18, color: palette.accent),
              const SizedBox(width: 6),
              Text('Then the cycle repeats', style: TextStyle(fontSize: 12.5, color: palette.muted, fontWeight: FontWeight.w600)),
            ]),
          ],
        );
      }
      final size = math.min(c.maxWidth, 520.0);
      const box = 130.0;
      final radius = size / 2 - box / 2 - 6;
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _RingPainter(color: palette.accent.withValues(alpha: 0.35), radius: radius))),
              Center(child: Icon(Icons.autorenew, size: 40, color: palette.accent.withValues(alpha: 0.6))),
              for (var i = 0; i < steps.length; i++)
                Positioned(
                  left: size / 2 + radius * math.cos(-math.pi / 2 + 2 * math.pi * i / steps.length) - box / 2,
                  top: size / 2 + radius * math.sin(-math.pi / 2 + 2 * math.pi * i / steps.length) - 32,
                  width: box,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _seriesColors[i % _seriesColors.length], width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('${i + 1}. ${_s(steps[i]['label'])}',
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.text)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double radius;
  _RingPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, paint);
    // Arrow heads around the ring to show direction
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 4 + i * math.pi / 2;
      final p = center + Offset(radius * math.cos(a), radius * math.sin(a));
      final dir = Offset(-math.sin(a), math.cos(a));
      final normal = Offset(math.cos(a), math.sin(a));
      final path = Path()
        ..moveTo(p.dx + dir.dx * 8, p.dy + dir.dy * 8)
        ..lineTo(p.dx - dir.dx * 4 + normal.dx * 6, p.dy - dir.dy * 4 + normal.dy * 6)
        ..lineTo(p.dx - dir.dx * 4 - normal.dx * 6, p.dy - dir.dy * 4 - normal.dy * 6)
        ..close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 1));
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.color != color || old.radius != radius;
}

class _ComparisonVisual extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final AiGuidePalette palette;
  const _ComparisonVisual({required this.columns, required this.rows, required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final minWidth = columns.length * 140.0;
      final table = Table(
        border: TableBorder.symmetric(inside: BorderSide(color: palette.border)),
        columnWidths: {0: const FlexColumnWidth(0.9), for (var i = 1; i < columns.length; i++) i: const FlexColumnWidth(1.2)},
        children: [
          TableRow(
            decoration: BoxDecoration(color: palette.accent),
            children: columns
                .map((h) => Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ))
                .toList(),
          ),
          for (var r = 0; r < rows.length; r++)
            TableRow(
              decoration: BoxDecoration(color: r.isOdd ? palette.bg : palette.surface),
              children: [
                for (var i = 0; i < columns.length; i++)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      i < rows[r].length ? rows[r][i] : '',
                      style: TextStyle(fontSize: 13, height: 1.45, color: palette.text, fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400),
                    ),
                  ),
              ],
            ),
        ],
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: palette.border), borderRadius: BorderRadius.circular(10)),
          child: c.maxWidth >= minWidth
              ? table
              : SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: minWidth, child: table)),
        ),
      );
    });
  }
}

class _TimelineVisual extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final AiGuidePalette palette;
  const _TimelineVisual({required this.events, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(width: 2, height: 6, color: i == 0 ? Colors.transparent : palette.accent.withValues(alpha: 0.4)),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(color: palette.surface, shape: BoxShape.circle, border: Border.all(color: palette.accent, width: 3)),
                      ),
                      Expanded(child: Container(width: 2, color: i == events.length - 1 ? Colors.transparent : palette.accent.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_s(events[i]['label']), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: palette.accent)),
                        if (_s(events[i]['detail']).isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(_s(events[i]['detail']), style: TextStyle(fontSize: 13.5, height: 1.5, color: palette.text)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HierarchyVisual extends StatelessWidget {
  final String root;
  final List<Map<String, dynamic>> children;
  final AiGuidePalette palette;
  const _HierarchyVisual({required this.root, required this.children, required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 600 && children.length <= 5;
      final rootBox = Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(color: palette.accent, borderRadius: BorderRadius.circular(12)),
        child: Text(root, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
      );

      if (wide) {
        return Column(
          children: [
            rootBox,
            Container(width: 2, height: 14, color: palette.border),
            Container(height: 2, margin: EdgeInsets.symmetric(horizontal: c.maxWidth / (children.length * 2)), color: palette.border),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < children.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Container(width: 2, height: 14, color: palette.border),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _branch(i, children[i])),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rootBox,
          const SizedBox(height: 10),
          for (var i = 0; i < children.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 8),
              child: Container(
                decoration: BoxDecoration(border: Border(left: BorderSide(color: palette.border, width: 2))),
                padding: const EdgeInsets.only(left: 12),
                child: _branch(i, children[i]),
              ),
            ),
        ],
      );
    });
  }

  Widget _branch(int i, Map<String, dynamic> node) {
    final color = _seriesColors[(i + 1) % _seriesColors.length];
    final kids = _maps(node['children']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_s(node['label']), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: palette.text)),
          for (final k in kids) ...[
            const SizedBox(height: 5),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: color)),
              const SizedBox(width: 6),
              Expanded(child: Text(_s(k['label']), style: TextStyle(fontSize: 12.5, height: 1.4, color: palette.text))),
            ]),
            for (final g in _maps(k['children']))
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 3),
                child: Text('– ${_s(g['label'])}', style: TextStyle(fontSize: 12, color: palette.muted)),
              ),
          ],
        ],
      ),
    );
  }
}

class _ChartVisual extends StatelessWidget {
  final Map<String, dynamic> visual;
  final AiGuidePalette palette;
  const _ChartVisual({required this.visual, required this.palette});

  @override
  Widget build(BuildContext context) {
    final labels = _strings(visual['labels']);
    final series = _maps(visual['series'])
        .map((s) => (name: _s(s['name']), values: (s['values'] as List? ?? []).map((v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0).toList()))
        .where((s) => s.values.length == labels.length)
        .toList();
    if (labels.isEmpty || series.isEmpty) return const SizedBox.shrink();
    final type = _s(visual['chartType']);

    final legend = Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        if (type == 'pie')
          for (var i = 0; i < labels.length; i++) _legend(_seriesColors[i % _seriesColors.length], '${labels[i]} (${_fmt(series.first.values[i])})')
        else if (series.length > 1)
          for (var i = 0; i < series.length; i++) _legend(_seriesColors[i % _seriesColors.length], series[i].name),
      ],
    );

    if (type == 'pie') {
      return Column(children: [
        SizedBox(height: 200, child: CustomPaint(size: const Size(200, 200), painter: _PiePainter(values: series.first.values, surface: palette.surface))),
        const SizedBox(height: 12),
        legend,
      ]);
    }
    if (type == 'line') {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 220,
          child: CustomPaint(painter: _LinePainter(labels: labels, series: series.map((s) => s.values).toList(), palette: palette)),
        ),
        const SizedBox(height: 10),
        legend,
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _bars(labels, series),
      const SizedBox(height: 10),
      legend,
    ]);
  }

  Widget _bars(List<String> labels, List<({String name, List<double> values})> series) {
    final maxV = series.expand((s) => s.values).fold<double>(0, (m, v) => math.max(m, v.abs()));
    return Column(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 110, child: Text(labels[i], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: palette.text))),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      for (var s = 0; s < series.length; s++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: LayoutBuilder(builder: (context, c) {
                            final frac = maxV == 0 ? 0.0 : series[s].values[i].abs() / maxV;
                            return Row(children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: 16,
                                width: math.max(2, (c.maxWidth - 60) * frac),
                                decoration: BoxDecoration(color: _seriesColors[s % _seriesColors.length], borderRadius: BorderRadius.circular(4)),
                              ),
                              const SizedBox(width: 6),
                              Text(_fmt(series[s].values[i]), style: TextStyle(fontSize: 11.5, color: palette.muted, fontWeight: FontWeight.w600)),
                            ]);
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _legend(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: palette.text)),
      ]);

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

class _PiePainter extends CustomPainter {
  final List<double> values;
  final Color surface;
  _PiePainter({required this.values, required this.surface});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b.abs());
    if (total == 0) return;
    final r = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: r);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i].abs() / total;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = _seriesColors[i % _seriesColors.length]);
      canvas.drawArc(rect, start, sweep, true, Paint()
        ..color = surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
      start += sweep;
    }
    // Donut hole
    canvas.drawCircle(rect.center, r * 0.5, Paint()..color = surface);
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) => old.values != values;
}

class _LinePainter extends CustomPainter {
  final List<String> labels;
  final List<List<double>> series;
  final AiGuidePalette palette;
  _LinePainter({required this.labels, required this.series, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0, bottom = 28.0, top = 8.0, right = 8.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    final all = series.expand((s) => s);
    final maxV = all.fold<double>(double.negativeInfinity, math.max);
    final minV = math.min(0.0, all.fold<double>(double.infinity, math.min));
    final span = (maxV - minV) == 0 ? 1 : (maxV - minV);

    final grid = Paint()
      ..color = palette.border
      ..strokeWidth = 1;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var g = 0; g <= 4; g++) {
      final y = top + h - h * g / 4;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      tp.text = TextSpan(text: _ChartVisual._fmt(minV + span * g / 4), style: TextStyle(fontSize: 10, color: palette.muted));
      tp.layout();
      tp.paint(canvas, Offset(left - tp.width - 4, y - tp.height / 2));
    }
    final step = labels.length > 1 ? w / (labels.length - 1) : w;
    for (var i = 0; i < labels.length; i++) {
      if (labels.length > 8 && i.isOdd) continue;
      tp.text = TextSpan(text: labels[i], style: TextStyle(fontSize: 10, color: palette.muted));
      tp.layout(maxWidth: 70);
      tp.paint(canvas, Offset(left + step * i - tp.width / 2, top + h + 6));
    }
    for (var s = 0; s < series.length; s++) {
      final color = _seriesColors[s % _seriesColors.length];
      final path = Path();
      for (var i = 0; i < series[s].length; i++) {
        final x = left + step * i;
        final y = top + h - h * (series[s][i] - minV) / span;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
      }
      canvas.drawPath(path, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}
