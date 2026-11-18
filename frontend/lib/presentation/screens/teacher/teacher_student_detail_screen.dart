import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/app_theme.dart';
import '../../../models/student_performance.dart';
import '../../../services/teacher_service.dart';
import '../../widgets/smart_back_button.dart';

/// One student's progress in a course the teacher teaches: lessons, sections, quizzes.
class TeacherStudentDetailScreen extends StatefulWidget {
  final String courseId;
  final String studentId;
  const TeacherStudentDetailScreen({super.key, required this.courseId, required this.studentId});

  @override
  State<TeacherStudentDetailScreen> createState() => _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState extends State<TeacherStudentDetailScreen> {
  final _service = TeacherService();
  late Future<DetailedStudentPerformance> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getStudentPerformance(widget.courseId, widget.studentId);
  }

  void _reload() => setState(() => _future = _service.getStudentPerformance(widget.courseId, widget.studentId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
          leading: SmartBackButton(fallback: '/teacher/courses/${widget.courseId}'),
          title: const Text('Student progress'),
          actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))]),
      body: FutureBuilder<DetailedStudentPerformance>(
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
          final d = snap.data!;
          final o = d.overallStats;
          final df = DateFormat('d MMM y');
          return ListView(padding: const EdgeInsets.all(16), children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                      child: Text(d.student.fullName.isEmpty ? '?' : d.student.fullName[0].toUpperCase(),
                          style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w800, fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.student.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        Text(
                          [d.student.email, if ((d.student.phone ?? '').isNotEmpty) d.student.phone!].where((e) => e.isNotEmpty).join(' · '),
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                        Text('Enrolled ${df.format(d.enrollment.enrollmentDate)} · ${d.enrollment.completionStatus}',
                            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    _Stat('Progress', '${o.overallProgress}%', Icons.trending_up, Colors.green),
                    _Stat('Lessons', '${o.completedLessons}/${o.totalLessons}', Icons.menu_book, Colors.blue),
                    _Stat('Quiz average', '${o.averageQuizScore.toStringAsFixed(0)}%', Icons.quiz, Colors.purple),
                    _Stat('Quizzes passed', '${o.passedQuizzes}/${o.quizAttempts}', Icons.verified, Colors.orange),
                  ]),
                  const SizedBox(height: 20),
                  const Text('Progress by section', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (d.sectionProgress.isEmpty) const Text('No sections yet.'),
                  for (final sp in d.sectionProgress)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(sp.sectionTitle, style: const TextStyle(fontWeight: FontWeight.w700))),
                            Text('${sp.completedLessons}/${sp.totalLessons}'),
                          ]),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: (sp.progress.clamp(0, 100)) / 100, minHeight: 6, color: AppTheme.primaryGreen),
                          ),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text('Quiz history', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (d.quizHistory.isEmpty) const Text('No quizzes taken yet.'),
                  for (final q in d.quizHistory)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(q.passed ? Icons.check_circle : Icons.cancel, color: q.passed ? Colors.green : Colors.redAccent),
                      title: Text(q.quizTitle ?? 'Quiz'),
                      subtitle: Text(df.format(q.submittedAt)),
                      trailing: Text('${q.score.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
      ]),
    );
  }
}
