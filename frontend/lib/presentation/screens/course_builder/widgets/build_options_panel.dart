import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/models/course_build.dart';

const builderGreen = Color(0xFF10B981);
const builderInk = Color(0xFF111827);
const builderMuted = Color(0xFF6B7280);
const builderBorder = Color(0xFFE5E7EB);

/// Mode picker + generation settings shared by the upload form and the
/// outline review step.
class BuildOptionsPanel extends StatefulWidget {
  final BuildOptions options;
  final VoidCallback onChanged;
  final bool showAutoGenerate;

  const BuildOptionsPanel({super.key, required this.options, required this.onChanged, this.showAutoGenerate = false});

  @override
  State<BuildOptionsPanel> createState() => _BuildOptionsPanelState();
}

class _BuildOptionsPanelState extends State<BuildOptionsPanel> {
  bool _advanced = false;
  late final TextEditingController _examStyle = TextEditingController(text: widget.options.examStyle);
  late final TextEditingController _instructions = TextEditingController(text: widget.options.instructions);

  BuildOptions get o => widget.options;

  void _set(VoidCallback fn) {
    setState(fn);
    widget.onChanged();
  }

  @override
  void dispose() {
    _examStyle.dispose();
    _instructions.dispose();
    super.dispose();
  }

  bool get _hasLessonQuiz => ['full', 'selected', 'quizzes_only'].contains(o.mode);
  bool get _hasChapterTests => ['full', 'selected', 'exam_prep'].contains(o.mode);
  bool get _hasMock => ['full', 'selected', 'exam_prep', 'mock_exam'].contains(o.mode);
  bool get _hasQuestions => _hasLessonQuiz || _hasChapterTests || _hasMock;
  bool get _hasContent => !['quizzes_only', 'mock_exam'].contains(o.mode);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('What should the AI create?'),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 900 ? 4 : c.maxWidth >= 560 ? 3 : 2;
          final w = (c.maxWidth - (cols - 1) * 10) / cols;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: BuildMode.all.map((m) {
              final selected = o.mode == m.id;
              return SizedBox(
                width: w,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _set(() {
                    o.mode = m.id;
                    if (m.id == 'mock_exam' && o.mockExamQuestions == 0) o.mockExamQuestions = 50;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(minHeight: 96),
                    decoration: BoxDecoration(
                      color: selected ? builderGreen.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? builderGreen : builderBorder, width: selected ? 2 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(m.emoji, style: const TextStyle(fontSize: 20)),
                          const Spacer(),
                          if (selected) const Icon(Icons.check_circle, color: builderGreen, size: 18),
                        ]),
                        const SizedBox(height: 6),
                        Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: builderInk)),
                        const SizedBox(height: 3),
                        Text(m.description, style: const TextStyle(fontSize: 11.5, color: builderMuted, height: 1.35)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
        const SizedBox(height: 18),
        if (_hasLessonQuiz)
          _CountSlider(
            label: 'Questions per lesson quiz',
            value: o.questionsPerLesson,
            max: 20,
            onChanged: (v) => _set(() => o.questionsPerLesson = v),
          ),
        if (_hasChapterTests)
          _CountSlider(
            label: 'Questions per chapter test',
            value: o.chapterTestQuestions,
            max: 50,
            onChanged: (v) => _set(() => o.chapterTestQuestions = v),
          ),
        if (_hasMock)
          _CountSlider(
            label: 'Mock exam questions',
            value: o.mockExamQuestions,
            max: 150,
            step: 5,
            hint: o.mockExamQuestions == 0 ? 'No mock exam' : null,
            onChanged: (v) => _set(() => o.mockExamQuestions = v),
          ),
        if (_hasQuestions) ...[
          const SizedBox(height: 6),
          _DifficultyMix(options: o, onChanged: () => _set(() {})),
          const SizedBox(height: 14),
          TextField(
            controller: _examStyle,
            decoration: _input('Exam style (optional)', hint: 'e.g. CPA, ACCA, University final, National exam'),
            onChanged: (v) => _set(() => o.examStyle = v),
          ),
        ],
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _advanced = !_advanced),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Icon(_advanced ? Icons.expand_less : Icons.expand_more, color: builderMuted),
              const SizedBox(width: 4),
              const Text('More settings', style: TextStyle(fontWeight: FontWeight.w600, color: builderMuted)),
            ]),
          ),
        ),
        if (_advanced) ...[
          if (_hasQuestions) ...[
            const _Label('Question types'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                ('mcq', 'Multiple choice'),
                ('true_false', 'True / False'),
                ('short_answer', 'Short answer'),
                ('calculation', 'Calculation'),
                ('scenario', 'Scenario / case'),
              ].map((t) {
                final on = o.questionTypes.contains(t.$1);
                return FilterChip(
                  label: Text(t.$2),
                  selected: on,
                  selectedColor: builderGreen.withValues(alpha: 0.15),
                  checkmarkColor: builderGreen,
                  onSelected: (v) => _set(() {
                    if (v) {
                      o.questionTypes = [...o.questionTypes, t.$1];
                    } else if (o.questionTypes.length > 1) {
                      o.questionTypes = o.questionTypes.where((x) => x != t.$1).toList();
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],
          if (_hasContent) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: builderGreen,
              title: const Text('Add visuals', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Diagrams, comparison tables, timelines and charts where the content allows'),
              value: o.includeVisuals,
              onChanged: (v) => _set(() => o.includeVisuals = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: builderGreen,
              title: const Text('Add flashcards', style: TextStyle(fontWeight: FontWeight.w600)),
              value: o.includeFlashcards,
              onChanged: (v) => _set(() => o.includeFlashcards = v),
            ),
          ],
          DropdownButtonFormField<String>(
            initialValue: const ['English', 'French', 'Kinyarwanda', 'Swahili'].contains(o.language) ? o.language : 'English',
            decoration: _input('Language of the generated content'),
            items: const ['English', 'French', 'Kinyarwanda', 'Swahili']
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) => _set(() => o.language = v ?? 'English'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _instructions,
            minLines: 2,
            maxLines: 4,
            decoration: _input('Instructions for the AI (optional)', hint: 'e.g. Use Rwandan examples. Focus on calculations. Keep notes concise.'),
            onChanged: (v) => _set(() => o.instructions = v),
          ),
          if (widget.showAutoGenerate)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: builderGreen,
              title: const Text('Start generating right after analysis', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Skip the outline check. You can still review everything before publishing.'),
              value: o.autoGenerate,
              onChanged: (v) => _set(() => o.autoGenerate = v),
            ),
        ],
      ],
    );
  }
}

InputDecoration _input(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: builderBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: builderBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: builderGreen, width: 2)),
    );

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: builderInk));
}

class _CountSlider extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final int step;
  final String? hint;
  final ValueChanged<int> onChanged;
  const _CountSlider({required this.label, required this.value, required this.max, this.step = 1, this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 4, child: Text(label, style: const TextStyle(fontSize: 13.5, color: builderInk, fontWeight: FontWeight.w500))),
        Expanded(
          flex: 6,
          child: Slider(
            value: value.clamp(0, max).toDouble(),
            min: 0,
            max: max.toDouble(),
            divisions: max ~/ step,
            activeColor: builderGreen,
            label: '$value',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 86,
          child: Text(hint ?? '$value', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700, color: builderInk)),
        ),
      ],
    );
  }
}

class _DifficultyMix extends StatelessWidget {
  final BuildOptions options;
  final VoidCallback onChanged;
  const _DifficultyMix({required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final total = (options.easy + options.medium + options.hard).clamp(1, 1000);
    int pct(int v) => (v * 100 / total).round();
    const colors = [Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFEF4444)];

    Widget slider(String label, int value, Color color, ValueChanged<int> set) => Row(children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: color,
              onChanged: (v) {
                set(v.round());
                onChanged();
              },
            ),
          ),
          SizedBox(width: 44, child: Text('${pct(value)}%', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: builderBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Difficulty mix', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(children: [
                if (options.easy > 0) Expanded(flex: options.easy, child: Container(color: colors[0])),
                if (options.medium > 0) Expanded(flex: options.medium, child: Container(color: colors[1])),
                if (options.hard > 0) Expanded(flex: options.hard, child: Container(color: colors[2])),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          slider('Easy', options.easy, colors[0], (v) => options.easy = v),
          slider('Medium', options.medium, colors[1], (v) => options.medium = v),
          slider('Hard', options.hard, colors[2], (v) => options.hard = v),
        ],
      ),
    );
  }
}

/// Small coloured status badge used across the builder screens.
class BuildStatusChip extends StatelessWidget {
  final String status;
  final bool dense;
  const BuildStatusChip(this.status, {super.key, this.dense = false});

  static (String, Color, IconData) describe(String status) => switch (status) {
        'pending' => ('Queued', const Color(0xFF6B7280), Icons.schedule),
        'generating' => ('Generating', const Color(0xFF2563EB), Icons.autorenew),
        'draft' => ('Draft', const Color(0xFF6B7280), Icons.edit_note),
        'needs_review' => ('Review', const Color(0xFFD97706), Icons.warning_amber_rounded),
        'approved' => ('Reviewed', const Color(0xFF16A34A), Icons.check_circle),
        'rejected' => ('Rejected', const Color(0xFFDC2626), Icons.block),
        'error' => ('Failed', const Color(0xFFDC2626), Icons.error_outline),
        'published' => ('Published', const Color(0xFF7C3AED), Icons.public),
        'uploaded' => ('Uploaded', const Color(0xFF6B7280), Icons.upload_file),
        'extracting' => ('Reading', const Color(0xFF2563EB), Icons.menu_book),
        'analyzing' => ('Analysing', const Color(0xFF2563EB), Icons.account_tree_outlined),
        'outline_ready' => ('Outline ready', const Color(0xFFD97706), Icons.fact_check_outlined),
        'ready' => ('Draft ready', const Color(0xFF16A34A), Icons.task_alt),
        'failed' => ('Failed', const Color(0xFFDC2626), Icons.error_outline),
        'cancelled' => ('Stopped', const Color(0xFF6B7280), Icons.stop_circle_outlined),
        _ => (status, const Color(0xFF6B7280), Icons.circle_outlined),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = describe(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 9, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: dense ? 12 : 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: dense ? 11 : 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
