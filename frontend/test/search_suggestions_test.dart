import 'package:excellencecoachinghub/widgets/search/search_suggestions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const titles = ['Biology S3', 'Introduction to Biology', 'Chemistry S3', 'Business Communication', 'C++ for beginners'];

  group('searchRelevance / rankByQuery', () {
    test('a few letters are enough, words in any order', () {
      expect(searchRelevance('bio', 'Biology S3'), greaterThan(0));
      expect(searchRelevance('s3 bio', 'Biology S3'), greaterThan(0));
      expect(searchRelevance('logy', 'Biology S3'), greaterThan(0));
      expect(searchRelevance('bio s4', 'Biology S3'), 0);
      expect(searchRelevance('c++', 'C++ for beginners'), greaterThan(0));
    });

    test('titles starting with the word come first', () {
      final r = rankByQuery(titles, 'bi', (t) => t);
      expect(r.first, 'Biology S3');
      expect(r, containsAll(['Biology S3', 'Introduction to Biology']));
      expect(r, isNot(contains('Chemistry S3')));
    });

    test('extra text (subject, description) also matches', () {
      final r = rankByQuery(titles, 'science', (t) => t, extra: (t) => t.contains('Biology') ? 'Science' : '');
      expect(r, ['Biology S3', 'Introduction to Biology']);
    });

    test('highlight marks the matched letters', () {
      final spans = highlightMatches('Biology S3', 'bio', const TextStyle(), const TextStyle(fontWeight: FontWeight.bold));
      expect(spans.first.text, 'Bio');
      expect(spans.first.style?.fontWeight, FontWeight.bold);
    });
  });

  testWidgets('typing shows suggestions and tapping one selects it', (tester) async {
    final controller = TextEditingController();
    String? chosen;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SearchSuggestions(
            controller: controller,
            load: (q) async => [for (final t in rankByQuery(titles, q, (t) => t)) SearchSuggestion(id: t, title: t)],
            onSelected: (s) => chosen = s.id,
            child: TextField(controller: controller),
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'bi');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Both Biology courses are suggested (titles are rich text with the match in bold).
    expect(find.textContaining('ology S3', findRichText: true), findsOneWidget);
    expect(find.textContaining('Introduction to', findRichText: true), findsOneWidget);
    expect(find.textContaining('Chemistry', findRichText: true), findsNothing);

    await tester.tap(find.textContaining('ology S3', findRichText: true));
    await tester.pumpAndSettle();
    expect(chosen, 'Biology S3');
    expect(find.textContaining('Introduction to', findRichText: true), findsNothing);
  });

  testWidgets('no match shows a friendly message', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SearchSuggestions(
          controller: controller,
          load: (q) async => const [],
          onSelected: (_) {},
          child: TextField(controller: controller),
        ),
      ),
    ));
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('No course matches "zzz"'), findsOneWidget);
  });
}
