import 'package:flutter_test/flutter_test.dart';
import 'package:excellencecoachinghub/models/lesson_video.dart';

void main() {
  test('build video jobs: stuck, waiting and failed videos', () {
    final j = BuildVideoJobs.fromJson({
      'workerActive': true,
      'stuckAfterMinutes': 15,
      'active': [
        {
          '_id': 'a1', 'itemId': 'i1', 'title': 'Photosynthesis', 'variant': 'experiment', 'state': 'running', 'status': 'generating_visuals',
          'attempts': 2, 'maxAttempts': 4, 'stageSince': '2026-10-30T08:00:00.000Z', 'worker': 'srv-abc:12:ff00aa',
          'stuck': 'No progress for 40 min (stage: generating_visuals)',
        },
        {'_id': 'a2', 'title': 'Respiration', 'state': 'queued', 'status': 'queued'},
      ],
      'failed': [
        {'_id': 'f1', 'title': 'Ecology', 'state': 'failed', 'status': 'failed', 'error': {'message': 'TTS quota exceeded', 'stage': 'generating_audio'}},
      ],
    });
    expect(j.stuck.single.title, 'Photosynthesis');
    expect(j.active.first.isRunning, isTrue);
    expect(j.active.first.stageSince!.isUtc, isFalse, reason: 'shown in local time');
    expect(j.active.last.stuck, isNull);
    expect(j.failed.single.errorMessage, 'TTS quota exceeded');
    expect(j.failed.single.errorStage, 'generating_audio');
  });

  test('empty or missing lists', () {
    final j = BuildVideoJobs.fromJson({});
    expect(j.active, isEmpty);
    expect(j.failed, isEmpty);
    expect(j.workerActive, isFalse);
  });
}
