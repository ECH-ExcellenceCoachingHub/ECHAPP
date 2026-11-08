import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';

/// Asks the learner to confirm, then unenrolls them from [courseId].
///
/// Returns `true` when the learner was unenrolled. Shows its own success and
/// error messages, so callers only need to navigate away on success.
///
/// Unenrolling keeps completed lessons, quiz results and certificates on the
/// server, does not refund or cancel payments, and the learner can enroll
/// again later.
Future<bool> confirmAndUnenroll(
  BuildContext context,
  WidgetRef ref, {
  required String courseId,
  String? courseTitle,
}) async {
  final confirmed = await showUnenrollConfirmation(context, courseTitle: courseTitle);
  if (!confirmed || !context.mounted) return false;

  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await ref.read(enrollmentNotifierProvider.notifier).unenrollFromCourse(courseId);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('You have been unenrolled. Your progress has been saved.'),
        backgroundColor: Color(0xFF047857),
      ),
    );
    return true;
  } catch (e) {
    final message = e.toString().replaceFirst(RegExp(r'^(ApiException|Exception):\s*'), '');
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Could not unenroll: $message'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }
}

/// The confirmation dialog on its own. Returns `true` if the learner confirms.
Future<bool> showUnenrollConfirmation(BuildContext context, {String? courseTitle}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _UnenrollDialog(courseTitle: courseTitle),
  );
  return result == true;
}

class _UnenrollDialog extends StatelessWidget {
  final String? courseTitle;

  const _UnenrollDialog({this.courseTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (courseTitle == null || courseTitle!.trim().isEmpty)
        ? 'Unenroll from this course?'
        : 'Unenroll from ${courseTitle!.trim()}?';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to unenroll from this course?'),
            const SizedBox(height: 16),
            _point(theme, Icons.lock_outline_rounded, Colors.red.shade400,
                'You will lose access to its learning materials.'),
            _point(theme, Icons.check_circle_outline_rounded, const Color(0xFF00A86B),
                'Your completed lessons and quiz results will be preserved.'),
            _point(theme, Icons.replay_rounded, theme.colorScheme.primary,
                'You may be able to enroll again later.'),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Unenroll from course', style: TextStyle(color: Colors.red)),
        ),
        // The safe choice is the prominent one
        ElevatedButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A86B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Keep learning'),
        ),
      ],
    );
  }

  Widget _point(ThemeData theme, IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
