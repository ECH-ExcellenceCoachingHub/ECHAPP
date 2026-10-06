import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:excellencecoachinghub/presentation/widgets/ai_lesson/ai_activities.dart';
import 'package:excellencecoachinghub/presentation/widgets/ai_lesson/ai_study_guide.dart';

const _palette = AiGuidePalette(
  text: Colors.black,
  muted: Colors.grey,
  surface: Colors.white,
  bg: Color(0xFFF8FAF9),
  border: Color(0xFFE5E7EB),
);

Future<void> _pump(WidgetTester tester, Map<String, dynamic> activity, {double width = 900}) async {
  tester.view.physicalSize = Size(width, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: AiActivityCard(activity: activity, palette: _palette))),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('match: tap an answer, tap its slot, check', (tester) async {
    await _pump(tester, {
      'type': 'match',
      'title': 'Match directions',
      'pairs': [
        {'left': 'North', 'right': 'Towards the top of a map'},
        {'left': 'South', 'right': 'Towards the bottom of a map'},
        {'left': 'East', 'right': 'Where the sun rises'},
      ],
    });
    final answers = ['Towards the top of a map', 'Towards the bottom of a map', 'Where the sun rises'];
    for (final a in answers) {
      await tester.tap(find.text(a));
      await tester.pump();
      await tester.tap(find.text('Drop the answer here').first);
      await tester.pumpAndSettle();
    }
    // Slots are filled in order, so every answer landed on its own term
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Excellent — all 3 correct!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('match: wrong placement is reported', (tester) async {
    await _pump(tester, {
      'type': 'match',
      'title': 'Match',
      'pairs': [
        {'left': 'A', 'right': 'alpha'},
        {'left': 'B', 'right': 'bravo'},
        {'left': 'C', 'right': 'charlie'},
      ],
    }, width: 380);
    for (final a in ['bravo', 'alpha', 'charlie']) {
      await tester.tap(find.text(a));
      await tester.pump();
      await tester.tap(find.text('Drop the answer here').first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 of 3 correct'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('categorize: drag items into groups', (tester) async {
    await _pump(tester, {
      'type': 'categorize',
      'title': 'Sort',
      'categories': [
        {'name': 'Clean habits', 'items': ['Wash hands']},
        {'name': 'Risky habits', 'items': ['Open defecation']},
      ],
    });
    await tester.drag(find.text('Wash hands'), tester.getCenter(find.text('Clean habits')) - tester.getCenter(find.text('Wash hands')));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Open defecation'), tester.getCenter(find.text('Risky habits')) - tester.getCenter(find.text('Open defecation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Excellent — all 2 correct!'), findsOneWidget);
  });

  testWidgets('fill blanks: place words, distractors stay', (tester) async {
    await _pump(tester, {
      'type': 'fill_blanks',
      'title': 'Complete',
      'text': 'The sun rises in the [[east]] and sets in the [[west]].',
      'distractors': ['north'],
    });
    expect(find.text('0 of 2 gaps filled'), findsOneWidget);
    final gaps = find.byWidgetPredicate((w) => w is SizedBox && w.width == 86 && w.height == 34);
    await tester.tap(find.text('east'));
    await tester.pump();
    await tester.tap(gaps.first, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('west'));
    await tester.pump();
    await tester.tap(gaps.first, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Excellent — every gap is right!'), findsOneWidget);
    expect(find.text('north'), findsOneWidget); // distractor left in the bank
  });

  testWidgets('order: check, then show answer gives perfect order', (tester) async {
    await _pump(tester, {
      'type': 'order',
      'title': 'Steps',
      'items': ['Wet hands', 'Apply soap', 'Scrub 20 seconds', 'Rinse'],
    });
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Perfect order!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('study guide places a picture under its heading and shows practice', (tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AiStudyGuideView(content: {
            'summary': 'Maps help us find places.',
            'notes': '## Compass directions\nNorth, south, east and west.\n\n## Map elements\nTitle, key, scale.',
            'keyPoints': ['Maps have a key'],
            'images': [
              {'url': 'https://example.com/compass.png', 'caption': 'A compass rose', 'author': 'Someone', 'license': 'CC BY 4.0', 'afterHeading': 'Compass directions'},
            ],
            'activities': [
              {'type': 'order', 'title': 'Order the directions clockwise', 'items': ['North', 'East', 'South', 'West']},
            ],
          }),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('A compass rose'), findsOneWidget);
    expect(find.text('Practice what you learned'), findsOneWidget);
    // Picture sits between the two sections of the notes
    final pic = tester.getTopLeft(find.text('A compass rose')).dy;
    expect(pic, greaterThan(tester.getTopLeft(find.text('North, south, east and west.')).dy));
    expect(pic, lessThan(tester.getTopLeft(find.text('Title, key, scale.')).dy));
  });
}
