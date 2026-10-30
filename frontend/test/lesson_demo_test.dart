import 'package:flutter_test/flutter_test.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/lesson_demo.dart';

void main() {
  test('a lesson reads its guided demonstration (student format)', () {
    final lesson = Lesson.fromJson({
      '_id': 'l1',
      'title': 'Testing a leaf for starch',
      'demo': {
        'video': {'videoId': 'abcDEF12345', 'title': 'Starch test', 'channel': 'Science', 'durationSec': 137},
        'steps': [
          {'text': 'Boil the leaf', 'at': 12, 'explain': 'Boiling kills the cells.'},
          {
            'text': 'Add iodine',
            'at': 75,
            'check': {'question': 'Starch colour?', 'choices': ['Blue-black', 'Green'], 'answerIndex': 0, 'explanation': 'Iodine turns blue-black.'},
          },
        ],
      },
    });
    expect(lesson.hasDemo, isTrue);
    expect(lesson.demo!.video.youtubeUrl, 'https://www.youtube.com/watch?v=abcDEF12345');
    expect(lesson.demo!.steps.map((s) => s.at), [12, 75]);
    expect(lesson.demo!.steps[1].check!.choices.first, 'Blue-black');
  });

  test('no demonstration: missing, empty or broken', () {
    expect(Lesson.fromJson({'_id': 'l1', 'title': 'x'}).hasDemo, isFalse);
    expect(LessonDemo.fromJson({'video': {'videoId': 'a'}, 'steps': []}), isNull);
    expect(LessonDemo.fromJson({'steps': [{'text': 'x'}]}), isNull);
    expect(DemoCheck.fromJson({'question': 'q', 'choices': ['a', 'b'], 'answerIndex': 5}), isNull);
  });

  test('teacher draft: suggestions, chosen video and unplaced steps', () {
    final d = DemoDraft.fromJson({
      'configured': true,
      'defaultQuery': 'starch experiment practical demonstration',
      'live': false,
      'demo': {
        'query': 'iodine starch leaf',
        'suggestions': [
          {'videoId': 'v1', 'title': 'A', 'chapters': [{'at': 0, 'title': 'Intro'}, {'at': 30, 'title': 'Boil'}]},
        ],
        'selected': {'videoId': 'v1', 'title': 'A'},
        'steps': [{'text': 'Boil', 'at': null, 'source': null}],
      },
    });
    expect(d.suggestions.single.chapters.last.at, 30);
    expect(d.selected!.videoId, 'v1');
    expect(d.steps.single.at, isNull);
    expect(d.steps.single.toJson()['at'], isNull);
  });

  test('time helpers', () {
    expect(formatDemoTime(75), '1:15');
    expect(formatDemoTime(5), '0:05');
    expect(parseDemoTime('1:15'), 75);
    expect(parseDemoTime(' 90 '), 90);
    expect(parseDemoTime('1:02:03'), 3723);
    expect(parseDemoTime('abc'), isNull);
  });
}
