import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/teacher_access_service.dart';
import '../../../providers/teacher_access_provider.dart';
import '../../../widgets/video_player/custom_video_player.dart';
import '../../../widgets/smart_back_button.dart';

/// A course's teacher's guide: chapters → lessons.
class TeacherGuideScreen extends ConsumerStatefulWidget {
  final String courseId;
  const TeacherGuideScreen({super.key, required this.courseId});

  @override
  ConsumerState<TeacherGuideScreen> createState() => _TeacherGuideScreenState();
}

class _TeacherGuideScreenState extends ConsumerState<TeacherGuideScreen> {
  late Future<TeacherGuide> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(teacherAccessServiceProvider).guide(widget.courseId);
  }

  void _reload() => setState(() => _future = ref.read(teacherAccessServiceProvider).guide(widget.courseId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const Text("Teacher's guide"), leading: const SmartBackButton(fallback: '/teacher/dashboard')),
      body: FutureBuilder<TeacherGuide>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(snap.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reload, child: const Text('Try again')),
              ]),
            );
          }
          final g = snap.data!;
          if (!g.ready || g.chapters.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text("This course's teacher's guide is being prepared. You will be notified when it is ready.", textAlign: TextAlign.center),
              ),
            );
          }
          final lessons = g.chapters.fold<int>(0, (n, c) => n + c.lessons.length);
          final videos = g.chapters.fold<int>(0, (n, c) => n + c.lessons.where((l) => l.hasVideo).length);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(g.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      for (final l in g.classLevels) Chip(label: Text(l), visualDensity: VisualDensity.compact),
                      Chip(avatar: const Icon(Icons.list_alt, size: 16), label: Text('$lessons lessons'), visualDensity: VisualDensity.compact),
                      if (videos > 0) Chip(avatar: const Icon(Icons.play_circle_outline, size: 16), label: Text('$videos videos'), visualDensity: VisualDensity.compact),
                    ]),
                    if (g.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(g.description, style: TextStyle(color: Theme.of(context).hintColor)),
                    ],
                    const SizedBox(height: 16),
                    for (final ch in g.chapters)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          initiallyExpanded: ch == g.chapters.first,
                          title: Text(ch.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${ch.lessons.length} lessons'),
                          children: [
                            for (var i = 0; i < ch.lessons.length; i++)
                              ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
                                  child: Text('${i + 1}', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
                                ),
                                title: Text(ch.lessons[i].title),
                                subtitle: ch.lessons[i].summary.isEmpty
                                    ? null
                                    : Text(ch.lessons[i].summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  if (ch.lessons[i].hasVideo) const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 20),
                                  if (ch.lessons[i].minutes != null) ...[
                                    const SizedBox(width: 6),
                                    Text('${ch.lessons[i].minutes} min', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                                  ],
                                  const Icon(Icons.chevron_right),
                                ]),
                                onTap: () => context.push('/teacher/guides/${g.courseId}/lessons/${ch.lessons[i].id}'),
                              ),
                          ],
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One lesson: how-to-teach video, timed lesson flow, methods, assessment, full guide.
class TeacherGuideLessonScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String itemId;
  const TeacherGuideLessonScreen({super.key, required this.courseId, required this.itemId});

  @override
  ConsumerState<TeacherGuideLessonScreen> createState() => _TeacherGuideLessonScreenState();
}

class _TeacherGuideLessonScreenState extends ConsumerState<TeacherGuideLessonScreen> {
  late Future<GuideLesson> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(teacherAccessServiceProvider).guideLesson(widget.courseId, widget.itemId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GuideLesson>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(leading: SmartBackButton(fallback: '/teacher/guides/${widget.courseId}')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(leading: SmartBackButton(fallback: '/teacher/guides/${widget.courseId}')),
            body: Center(child: Text(snap.error.toString())),
          );
        }
        final l = snap.data!;
        final g = l.guide;
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            appBar: AppBar(
              leading: SmartBackButton(fallback: '/teacher/guides/${widget.courseId}'),
              title: Text(l.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.timeline), text: 'Lesson plan'),
                  Tab(icon: Icon(Icons.lightbulb_outline), text: 'Teaching ideas'),
                  Tab(icon: Icon(Icons.fact_check_outlined), text: 'Assess'),
                  Tab(icon: Icon(Icons.article_outlined), text: 'Full guide'),
                ],
              ),
            ),
            body: TabBarView(children: [
              _Page(children: [
                if (l.videoUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CustomVideoPlayer(videoUrl: l.videoUrl, title: l.title, description: 'How to teach this lesson'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (l.videoStatus != null && l.videoStatus != 'failed')
                  const _Note(icon: Icons.movie_creation_outlined, text: 'The teaching video for this lesson is being prepared.'),
                if ((l.content['summary'] ?? '').toString().isNotEmpty) _Para(l.content['summary'].toString()),
                _Bullets('Learning objectives', _strs(l.content['learningObjectives']), icon: Icons.flag_outlined),
                _Bullets('Learners should already know', _strs(g['priorKnowledge']), icon: Icons.history_edu),
                _Bullets('Materials', _strs(g['materials']), icon: Icons.inventory_2_outlined),
                _Bullets('Before the lesson', _strs(g['preparation']), icon: Icons.checklist),
                _Flow(stages: _maps(g['lessonFlow']), total: (g['durationMinutes'] as num?)?.toInt()),
              ]),
              _Page(children: [
                for (final m in _maps(g['modernMethods']))
                  _InfoCard(icon: Icons.groups_2_outlined, color: const Color(0xFF7C3AED), title: m['method']?.toString() ?? '', body: m['how']?.toString() ?? ''),
                _Heading('Common misconceptions'),
                for (final m in _maps(g['misconceptions']))
                  _InfoCard(icon: Icons.error_outline, color: Colors.orange, title: m['misconception']?.toString() ?? '', body: 'Fix: ${m['fix'] ?? ''}'),
                _Bullets('Help learners who struggle', _strs((g['differentiation'] as Map?)?['support']), icon: Icons.support_outlined),
                _Bullets('Challenge fast learners', _strs((g['differentiation'] as Map?)?['extension']), icon: Icons.rocket_launch_outlined),
                _Bullets('Competences & cross-cutting issues', _strs(g['competences']), icon: Icons.hub_outlined),
              ]),
              _Page(children: [
                _Heading('Questions to check understanding'),
                for (final (i, q) in _maps(g['assessment']).indexed) _QuestionCard(n: i + 1, question: q['question']?.toString() ?? '', answer: q['expectedAnswer']?.toString() ?? ''),
                if ((g['homework'] ?? '').toString().isNotEmpty) ...[
                  _Heading('Homework'),
                  _Para(g['homework'].toString()),
                ],
              ]),
              _Page(children: [
                MarkdownBody(data: (l.content['notes'] ?? '').toString(), selectable: true),
                if ((g['teacherBackground'] ?? '').toString().isNotEmpty) ...[
                  _Heading('Background for the teacher'),
                  _Para(g['teacherBackground'].toString()),
                ],
              ]),
            ]),
          ),
        );
      },
    );
  }
}

List<String> _strs(dynamic v) => ((v as List?) ?? const []).map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
List<Map<String, dynamic>> _maps(dynamic v) => ((v as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

class _Page extends StatelessWidget {
  final List<Widget> children;
  const _Page({required this.children});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    ]);
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)));
}

class _Para extends StatelessWidget {
  final String text;
  const _Para(this.text);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(height: 1.45)));
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Note({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(icon), const SizedBox(width: 10), Expanded(child: Text(text))]),
    );
  }
}

class _Bullets extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  const _Bullets(this.title, this.items, {required this.icon});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Row(children: [Icon(icon, size: 18, color: AppTheme.primaryGreen), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w800))]),
      ),
      for (final i in items)
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('•  '), Expanded(child: Text(i, style: const TextStyle(height: 1.35)))]),
        ),
    ]);
  }
}

/// Timed lesson stages as a vertical timeline.
class _Flow extends StatelessWidget {
  final List<Map<String, dynamic>> stages;
  final int? total;
  const _Flow({required this.stages, this.total});
  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();
    final green = AppTheme.primaryGreen;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Heading('Step-by-step lesson${total != null ? ' · $total min' : ''}'),
      for (var i = 0; i < stages.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Column(children: [
              CircleAvatar(radius: 14, backgroundColor: green, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
              if (i < stages.length - 1) Expanded(child: VerticalDivider(color: green.withOpacity(0.4), thickness: 2)),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(stages[i]['stage']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                    if (stages[i]['minutes'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: green.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text('${stages[i]['minutes']} min', style: TextStyle(color: green, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  if ((stages[i]['teacher'] ?? '').toString().isNotEmpty) _Role('Teacher', stages[i]['teacher'].toString(), Icons.co_present_outlined),
                  if ((stages[i]['learners'] ?? '').toString().isNotEmpty) _Role('Learners', stages[i]['learners'].toString(), Icons.groups_outlined),
                  if ((stages[i]['tip'] ?? '').toString().isNotEmpty) _Role('Tip', stages[i]['tip'].toString(), Icons.tips_and_updates_outlined),
                ]),
              ),
            ),
          ]),
        ),
    ]);
  }
}

class _Role extends StatelessWidget {
  final String who;
  final String text;
  final IconData icon;
  const _Role(this.who, this.text, this.icon);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: Theme.of(context).hintColor),
        const SizedBox(width: 6),
        Expanded(child: Text.rich(TextSpan(children: [TextSpan(text: '$who: ', style: const TextStyle(fontWeight: FontWeight.w700)), TextSpan(text: text)]), style: const TextStyle(height: 1.35))),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _InfoCard({required this.icon, required this.color, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.3))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(height: 1.35)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final int n;
  final String question;
  final String answer;
  const _QuestionCard({required this.n, required this.question, required this.answer});
  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _show = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${widget.n}. ${widget.question}', style: const TextStyle(fontWeight: FontWeight.w700)),
          if (widget.answer.isNotEmpty)
            _show
                ? Padding(padding: const EdgeInsets.only(top: 6), child: Text('Expected answer: ${widget.answer}', style: TextStyle(color: AppTheme.primaryGreen)))
                : TextButton(onPressed: () => setState(() => _show = true), child: const Text('Show expected answer')),
        ]),
      ),
    );
  }
}
