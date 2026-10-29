import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/lesson_video.dart';
import 'package:excellencecoachinghub/models/course_build.dart';
import 'package:excellencecoachinghub/presentation/widgets/ai_lesson/lesson_video_status.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/video_checkpoints.dart';

Widget _wrap(Widget child, {Size size = const Size(400, 225)}) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: size.width, height: size.height, child: child))),
    );

void main() {
  group('LessonVideo parsing', () {
    test('older lessons without video metadata still parse', () {
      final lesson = Lesson.fromJson({'_id': 'l1', 'sectionId': 's', 'courseId': 'c', 'title': 'Old lesson', 'order': 0, 'duration': 5});
      expect(lesson.aiVideo, isNull);
      expect(lesson.aiExperimentVideo, isNull);
      expect(lesson.isVideoProcessing, isFalse);
      expect(lesson.hasExperimentVideo, isFalse);
    });

    test('processing video without a playable file', () {
      final lesson = Lesson.fromJson({
        '_id': 'l2', 'sectionId': 's', 'courseId': 'c', 'title': 'New lesson', 'order': 0, 'duration': 5,
        'aiVideo': {'status': 'generating_visuals', 'variant': 'explainer', 'contentVersion': 2},
      });
      expect(lesson.isVideoProcessing, isTrue);
      expect(lesson.aiVideo!.statusLabel, 'Drawing diagrams and formulas');
      expect(lesson.aiVideo!.progress, greaterThan(0.4));
      expect(lesson.aiVideo!.contentVersion, 2);
    });

    test('experiment video is only watchable after review approval', () {
      final pending = LessonVideo.fromJson({'status': 'completed', 'variant': 'experiment', 's3Key': null, 'reviewStatus': 'pending'})!;
      expect(pending.isWatchable, isFalse);
      expect(pending.needsReview, isTrue);
      final approved = LessonVideo.fromJson({'status': 'completed', 'variant': 'experiment', 's3Key': 'ai-videos/x.mp4', 'reviewStatus': 'approved'})!;
      expect(approved.isWatchable, isTrue);
      expect(LessonVideo.fromJson('not a map'), isNull);
    });

    test('video job view parses checks, cost, storyboard and errors', () {
      final j = VideoJobView.fromJson({
        '_id': 'j1', 'variant': 'explainer', 'state': 'failed', 'status': 'failed', 'attempts': 3, 'maxAttempts': 3,
        'error': {'message': 'TTS failed (500)', 'stage': 'generating_audio'},
        'review': {'required': true, 'status': 'pending', 'reasons': ['Hazards mentioned']},
        'checks': [{'name': 'duration', 'passed': true, 'detail': '120s'}],
        'cost': {'actualUsd': 0.12, 'estimatedUsd': 0.2},
        'storyboard': {'scenes': [{'n': 1, 'type': 'title', 'heading': 'Intro', 'narration': 'Hello'}]},
      })!;
      expect(j.isRunning, isFalse);
      expect(j.errorStage, 'generating_audio');
      expect(j.checks.single.passed, isTrue);
      expect(j.actualUsd, 0.12);
      expect(j.scenes.single.heading, 'Intro');
      expect(j.reviewReasons, ['Hazards mentioned']);
    });

    test('build options round-trip the video settings', () {
      final o = BuildOptions.fromJson({'generateVideos': false, 'videoBudgetUsd': 12.5});
      expect(o.generateVideos, isFalse);
      expect(o.videoBudgetUsd, 12.5);
      expect(o.toJson()['generateVideos'], isFalse);
      expect(BuildOptions.fromJson(null).generateVideos, isTrue);
    });
  });

  group('LessonVideoStatusView', () {
    testWidgets('processing: explains the wait and offers notes and quiz', (tester) async {
      var notes = 0;
      var quiz = 0;
      await tester.pumpWidget(_wrap(LessonVideoStatusView(
        video: const LessonVideo(status: 'generating_audio'),
        title: 'Titration',
        onOpenNotes: () => notes++,
        onOpenQuiz: () => quiz++,
      )));
      expect(find.text('Your lesson video is being prepared'), findsOneWidget);
      expect(find.textContaining('Recording the narration'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Study the notes'));
      await tester.tap(find.text('Take the quiz'));
      expect(notes, 1);
      expect(quiz, 1);
    });

    testWidgets('failed: the rest of the lesson stays available', (tester) async {
      await tester.pumpWidget(_wrap(LessonVideoStatusView(
        video: const LessonVideo(status: 'failed', error: 'boom'),
        title: 'Titration',
        onOpenNotes: () {},
      )));
      expect(find.text('Video not available right now'), findsOneWidget);
      expect(find.text('The notes and quiz for this lesson are ready.'), findsOneWidget);
      expect(find.text('Study the notes'), findsOneWidget);
      expect(find.text('boom'), findsNothing, reason: 'technical errors are not shown to students');
    });

    testWidgets('waiting for review is explained', (tester) async {
      await tester.pumpWidget(_wrap(const LessonVideoStatusView(
        video: LessonVideo(status: 'completed', reviewStatus: 'pending'),
        title: 'Titration',
      )));
      expect(find.text('Video coming soon'), findsOneWidget);
    });

    testWidgets('fits a small phone player without overflow', (tester) async {
      await tester.pumpWidget(_wrap(
        LessonVideoStatusView(video: const LessonVideo(status: 'queued'), title: 'T', onOpenNotes: () {}, onOpenQuiz: () {}),
        size: const Size(320, 180),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('LessonVideoInfoCard', () {
    testWidgets('shows disclosure, stale notice and an expandable transcript', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonVideoInfoCard(
              video: const LessonVideo(
                status: 'completed',
                s3Key: 'ai-videos/a.mp4',
                stale: true,
                disclosure: 'Simulated demonstration — illustrative only, not recorded experimental data.',
                transcript: 'First we fill the burette.',
              ),
            ),
          ),
        ),
      ));
      expect(find.textContaining('Simulated demonstration'), findsOneWidget);
      expect(find.textContaining('earlier version of the lesson'), findsOneWidget);
      expect(find.text('Transcript'), findsOneWidget);
      expect(find.text('First we fill the burette.'), findsNothing);
      await tester.tap(find.text('Transcript'));
      await tester.pumpAndSettle();
      expect(find.text('First we fill the burette.'), findsOneWidget);
    });

    testWidgets('renders nothing for videos students cannot watch', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: LessonVideoInfoCard(video: LessonVideo(status: 'completed', reviewStatus: 'pending', transcript: 'x'))),
      ));
      expect(find.byKey(const ValueKey('lesson-video-info')), findsNothing);
    });
  });

  group('Interactive checks and credits', () {
    const check = {
      'id': 'check-4', 'at': 41.2, 'resumeAt': 44.9, 'question': 'Density of 25 plants in 5 m²?',
      'choices': ['5 per m²', '25 per m²', '125 per m²'], 'answerIndex': 0, 'explanation': '25 ÷ 5 = 5',
    };
    LessonVideo video() => LessonVideo.fromJson({
          'status': 'completed', 's3Key': 'ai-videos/x.mp4', 'transcript': 'Hello',
          'interactions': [
            check,
            {'at': 10, 'question': 'Broken', 'choices': ['only one'], 'answerIndex': 0},
            {'at': 5, 'question': 'Earlier?', 'choices': ['a', 'b'], 'answerIndex': 1},
          ],
          'credits': [
            {'provider': 'wikimedia', 'providerLabel': 'Wikimedia Commons', 'title': 'Quadrat on grass', 'author': 'M. de Casamajor', 'license': 'CC BY 4.0', 'sourceUrl': 'https://commons.wikimedia.org/wiki/File:Q.jpg'},
            {'nothing': true},
          ],
        })!;

    test('parses valid questions sorted by time and drops malformed ones', () {
      final v = video();
      expect(v.interactions.map((i) => i.question), ['Earlier?', 'Density of 25 plants in 5 m²?']);
      final q = v.interactions.last;
      expect(q.at, const Duration(milliseconds: 41200));
      expect(q.resumeAt, const Duration(milliseconds: 44900));
      expect(q.answerIndex, 0);
      expect(v.credits.single.line, 'M. de Casamajor · Wikimedia Commons · CC BY 4.0');
      // Older videos have neither.
      final old = LessonVideo.fromJson({'status': 'completed', 's3Key': 'k'})!;
      expect(old.interactions, isEmpty);
      expect(old.credits, isEmpty);
    });

    test('tracker fires once when playback crosses a question, not when seeking past it', () {
      final t = CheckpointTracker(video().interactions);
      expect(t.onPosition(const Duration(seconds: 4)), isNull); // first update only sets the baseline
      expect(t.onPosition(const Duration(milliseconds: 4600)), isNull);
      expect(t.onPosition(const Duration(milliseconds: 5100))?.question, 'Earlier?');
      expect(t.onPosition(const Duration(milliseconds: 5300)), isNull, reason: 'asked once');
      // A seek over the second question does not fire it…
      expect(t.onPosition(const Duration(seconds: 50)), isNull);
      // …and rewinding then playing through it does.
      expect(t.onPosition(const Duration(seconds: 40)), isNull);
      expect(t.onPosition(const Duration(milliseconds: 40800)), isNull);
      expect(t.onPosition(const Duration(milliseconds: 41300))?.id, 'check-4');
    });

    testWidgets('overlay: answer, see feedback and explanation, continue', (tester) async {
      var continued = 0;
      final q = video().interactions.last;
      await tester.pumpWidget(_wrap(VideoCheckOverlay(interaction: q, onContinue: () => continued++), size: const Size(640, 360)));
      expect(find.text('Density of 25 plants in 5 m²?'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('video-check-choice-1')));
      await tester.pump();
      expect(find.textContaining('Not quite — the answer is A. 25 ÷ 5 = 5'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('video-check-choice-0'))); // already answered: no change
      await tester.pump();
      expect(find.textContaining('Not quite'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      expect(continued, 1);
    });

    testWidgets('overlay fits a small phone player and can be skipped', (tester) async {
      var continued = 0;
      await tester.pumpWidget(_wrap(VideoCheckOverlay(interaction: video().interactions.last, onContinue: () => continued++), size: const Size(320, 180)));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Skip'));
      expect(continued, 1);
      await tester.tap(find.byKey(const ValueKey('video-check-choice-0')));
      await tester.pump();
      expect(find.textContaining('Correct!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('info card announces the questions and lists credits', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: LessonVideoInfoCard(video: video())))));
      expect(find.textContaining('pauses 2 times'), findsOneWidget);
      expect(find.text('Photo and video credits'), findsOneWidget);
      await tester.tap(find.text('Photo and video credits'));
      await tester.pumpAndSettle();
      expect(find.text('Quadrat on grass'), findsOneWidget);
      expect(find.textContaining('CC BY 4.0'), findsOneWidget);
    });
  });
}
