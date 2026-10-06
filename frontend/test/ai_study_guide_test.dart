import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:excellencecoachinghub/presentation/widgets/ai_lesson/ai_study_guide.dart';

final _content = <String, dynamic>{
  'summary': 'Financial management is about acquiring, financing and managing assets to maximise shareholder wealth.',
  'learningObjectives': ['Define financial management', 'Explain the objectives of financial management'],
  'notes': '## Meaning\nFinancial management is **concerned with** the acquisition of assets.\n\n| Goal | Focus |\n|---|---|\n| Profit | Short term |\n| Wealth | Long term |',
  'keyPoints': ['Wealth maximisation is the primary objective', 'Profit maximisation ignores risk and timing'],
  'keyTerms': [
    {'term': 'Wealth maximisation', 'definition': 'Maximising the market value of shares.', 'page': 14},
    {'term': 'Agency problem', 'definition': 'Conflict between managers and shareholders.', 'page': 15},
  ],
  'examples': [
    {'title': 'Present value of 1,000', 'body': '1. PV = 1000 / (1.1)^2\n2. PV = **826.45**', 'page': 16},
  ],
  'formulas': [
    {
      'name': 'Present value',
      'expression': 'PV = FV / (1 + r)^n',
      'variables': [
        {'symbol': 'FV', 'meaning': 'Future value'},
        {'symbol': 'r', 'meaning': 'Discount rate per period'},
      ],
      'explanation': 'Discounts a future amount to today.',
      'page': 16,
    }
  ],
  'flashcards': [
    {'front': 'Primary objective of FM?', 'back': 'Shareholder wealth maximisation'},
    {'front': 'What is PV?', 'back': 'Value today of a future amount'},
  ],
  'examTips': ['Always state the formula before substituting numbers'],
  'commonMistakes': ['Confusing profit maximisation with wealth maximisation'],
  'visuals': [
    {'type': 'flow', 'title': 'Investment decision process', 'steps': [
      {'label': 'Identify', 'detail': 'Find opportunities'},
      {'label': 'Evaluate', 'detail': 'NPV, IRR'},
      {'label': 'Select', 'detail': 'Choose the best project with a long description that wraps'},
      {'label': 'Review', 'detail': 'Post-audit'},
    ]},
    {'type': 'cycle', 'title': 'Working capital cycle', 'steps': [
      {'label': 'Cash'}, {'label': 'Raw materials'}, {'label': 'Finished goods'}, {'label': 'Debtors'},
    ]},
    {'type': 'comparison', 'title': 'Profit vs wealth', 'columns': ['Aspect', 'Profit max.', 'Wealth max.'], 'rows': [
      ['Time value', 'Ignored', 'Considered'],
      ['Risk', 'Ignored', 'Considered'],
    ]},
    {'type': 'timeline', 'title': 'History', 'events': [
      {'label': '1950s', 'detail': 'Traditional approach'},
      {'label': '1960s', 'detail': 'Modern approach'},
    ]},
    {'type': 'hierarchy', 'title': 'Finance decisions', 'root': 'Financial management', 'children': [
      {'label': 'Investment', 'children': [{'label': 'Capital budgeting'}]},
      {'label': 'Financing', 'children': [{'label': 'Debt'}, {'label': 'Equity'}]},
      {'label': 'Dividend'},
    ]},
    {'type': 'chart', 'chartType': 'bar', 'title': 'Cash flows', 'labels': ['Y1', 'Y2', 'Y3'], 'series': [
      {'name': 'Project A', 'values': [100, 200, 300]},
      {'name': 'Project B', 'values': [150, 120, 90]},
    ]},
    {'type': 'chart', 'chartType': 'pie', 'title': 'Capital structure', 'labels': ['Debt', 'Equity'], 'series': [
      {'name': 'Share', 'values': [40, 60]},
    ]},
    {'type': 'chart', 'chartType': 'line', 'title': 'Growth', 'labels': ['2019', '2020', '2021', '2022'], 'series': [
      {'name': 'Revenue', 'values': [10, 14, 13, 18]},
    ]},
  ],
  'sources': [{'page': 14, 'section': '1.2'}, {'page': 16, 'section': '1.3'}],
  'estimatedMinutes': 18,
};

Future<void> _pumpAt(WidgetTester tester, double width, {bool dark = false}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  String? asked;
  await tester.pumpWidget(MaterialApp(
    theme: dark ? ThemeData.dark() : ThemeData.light(),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AiStudyGuideView(content: _content, onAskAi: (p) => asked = p),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  expect(asked, isNull);
}

void main() {
  testWidgets('study guide renders every section and visual on desktop', (tester) async {
    await _pumpAt(tester, 1200);
    expect(find.text('Study guide'), findsOneWidget);
    expect(find.text('What you will learn'), findsOneWidget);
    expect(find.text('Investment decision process'), findsOneWidget);
    expect(find.text('Working capital cycle'), findsOneWidget);
    expect(find.text('Profit vs wealth'), findsOneWidget);
    expect(find.text('Finance decisions'), findsOneWidget);
    expect(find.text('Capital structure'), findsOneWidget);
    expect(find.text('Present value'), findsOneWidget);
    expect(find.text('PV = FV / (1 + r)^n'), findsOneWidget);
    expect(find.text('Primary objective of FM?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('study guide fits a phone screen without overflow (dark mode)', (tester) async {
    await _pumpAt(tester, 380, dark: true);
    expect(find.text('Key terms'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flashcards flip and advance', (tester) async {
    await _pumpAt(tester, 900);
    await tester.ensureVisible(find.text('Primary objective of FM?'));
    await tester.tap(find.text('Primary objective of FM?'));
    await tester.pumpAndSettle();
    expect(find.text('Shareholder wealth maximisation'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('What is PV?'), findsOneWidget);
  });
}
