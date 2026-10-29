import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/models/lesson_video.dart';

/// Shown in the 16:9 player area when the lesson has no playable video yet.
/// Students are never blocked: notes and quiz stay one tap away.
class LessonVideoStatusView extends StatelessWidget {
  final LessonVideo? video;
  final String title;
  final VoidCallback? onOpenNotes;
  final VoidCallback? onOpenQuiz;

  const LessonVideoStatusView({
    super.key,
    required this.video,
    required this.title,
    this.onOpenNotes,
    this.onOpenQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final v = video;
    final processing = v?.isProcessing ?? false;
    final failed = v?.isFailed ?? false;
    final waitingReview = v != null && v.status == 'completed' && v.needsReview;

    final IconData icon;
    final String headline;
    final String detail;
    if (processing) {
      icon = Icons.movie_creation_outlined;
      headline = 'Your lesson video is being prepared';
      detail = '${v!.statusLabel}… You can study the notes in the meantime.';
    } else if (waitingReview) {
      icon = Icons.fact_check_outlined;
      headline = 'Video coming soon';
      detail = 'A teacher is checking this video before it is published.';
    } else if (failed) {
      icon = Icons.ondemand_video_outlined;
      headline = 'Video not available right now';
      detail = 'The notes and quiz for this lesson are ready.';
    } else {
      icon = Icons.play_circle_outline;
      headline = title;
      detail = 'Video not available';
    }

    return Container(
      key: const ValueKey('lesson-video-status'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: LayoutBuilder(builder: (context, c) {
        final compact = c.maxHeight < 210;
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compact)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
                    child: Icon(icon, color: Colors.white70, size: 30),
                  ),
                if (!compact) const SizedBox(height: 10),
                Text(headline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                if (processing) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: v!.progress == 0 ? null : v.progress,
                        minHeight: 5,
                        backgroundColor: Colors.white12,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
                if ((processing || failed || waitingReview) && (onOpenNotes != null || onOpenQuiz != null)) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                    if (onOpenNotes != null)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A), visualDensity: VisualDensity.compact),
                        onPressed: onOpenNotes,
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: const Text('Study the notes'),
                      ),
                    if (onOpenQuiz != null)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38), visualDensity: VisualDensity.compact),
                        onPressed: onOpenQuiz,
                        icon: const Icon(Icons.quiz_outlined, size: 16),
                        label: const Text('Take the quiz'),
                      ),
                  ]),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Below the player: outdated notice, simulated-demo disclosure and the
/// narration transcript (captions text) for accessibility and revision.
class LessonVideoInfoCard extends StatelessWidget {
  final LessonVideo? video;
  final bool isDark;

  const LessonVideoInfoCard({super.key, required this.video, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final v = video;
    if (v == null || !v.isWatchable) return const SizedBox.shrink();
    final hasTranscript = (v.transcript ?? '').trim().isNotEmpty;
    final regenerating = v.isProcessing;
    final checks = v.interactions.length;
    if (!v.stale && v.disclosure == null && !hasTranscript && !regenerating && checks == 0 && v.credits.isEmpty) return const SizedBox.shrink();

    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final text = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF111827);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return Container(
      key: const ValueKey('lesson-video-info'),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (v.disclosure != null)
          _Notice(icon: Icons.science_outlined, color: const Color(0xFFB45309), background: const Color(0xFFFEF3C7), text: v.disclosure!),
        if (v.stale && !regenerating)
          const _Notice(
              icon: Icons.update,
              color: Color(0xFF1D4ED8),
              background: Color(0xFFEFF6FF),
              text: 'This video was made for an earlier version of the lesson. The notes are up to date.'),
        if (regenerating)
          _Notice(icon: Icons.autorenew, color: const Color(0xFF15803D), background: const Color(0xFFDCFCE7), text: 'An updated video is being prepared (${v.statusLabel.toLowerCase()}).'),
        if (checks > 0)
          _Notice(
              icon: Icons.quiz_outlined,
              color: const Color(0xFF15803D),
              background: const Color(0xFFDCFCE7),
              text: checks == 1
                  ? 'This video pauses once with a quick question — answer it to keep going.'
                  : 'This video pauses $checks times with quick questions — answer them to keep going.'),
        if (hasTranscript)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              leading: Icon(Icons.closed_caption_outlined, color: muted),
              title: Text('Transcript', style: TextStyle(fontWeight: FontWeight.w600, color: text, fontSize: 14)),
              subtitle: Text('Read along with the narration', style: TextStyle(color: muted, fontSize: 12)),
              children: [
                SelectableText(v.transcript!, style: TextStyle(color: text, fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        if (v.credits.isNotEmpty)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: const ValueKey('lesson-video-credits'),
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              leading: Icon(Icons.photo_library_outlined, color: muted),
              title: Text('Photo and video credits', style: TextStyle(fontWeight: FontWeight.w600, color: text, fontSize: 14)),
              subtitle: Text('${v.credits.length} licensed ${v.credits.length == 1 ? 'item' : 'items'} used in this video', style: TextStyle(color: muted, fontSize: 12)),
              children: [
                for (final c in v.credits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(c.kind == 'video' ? Icons.videocam_outlined : Icons.image_outlined, size: 16, color: muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (c.title.isNotEmpty) Text(c.title, style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w600)),
                          SelectableText(c.line + (c.sourceUrl != null ? '\n${c.sourceUrl}' : ''), style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
                        ]),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
      ]),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String text;
  const _Notice({required this.icon, required this.color, required this.background, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );
}
