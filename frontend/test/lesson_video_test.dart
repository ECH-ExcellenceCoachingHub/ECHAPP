import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/lesson_video.dart';
import 'package:excellencecoachinghub/models/course_build.dart';
import 'package:excellencecoachinghub/presentation/widgets/ai_lesson/lesson_video_status.dart';

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
}
