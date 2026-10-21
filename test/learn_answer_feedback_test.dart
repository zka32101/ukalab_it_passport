import 'package:app_common_kit/app_common_kit.dart';
import 'package:ukalab_core/learning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';
import 'package:ukalab_it_passport/screens/learn_screen.dart';

import 'test_support.dart';

/// 選択式の解答直後は「解答した問題」の解説・正誤・「N / 全体問目」が出ること、
/// 解答直後に親を再描画しても同じこと、「次へ」で進み、最後の問題は解説を見てから
/// 結果画面へ移ることの回帰テスト（乙4・簿記で起きた不具合の再発防止）。
Question _q(String id, String label) => Question(
      qid: id,
      examId: 'it_passport',
      subjectId: 'ml_overview',
      topicId: id,
      prompt: '問題$labelの文',
      choices: ['$labelの正解', '$labelの誤り1', '$labelの誤り2', '$labelの誤り3'],
      answerIndex: 0,
      explanation: '解説$labelの本文',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

late void Function() _rebuildParent;

Widget _app(List<Question> qs, AdGate adGate) => ProviderScope(
      overrides: [
        handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
        ...studyNotesTestOverrides(),
        coinServiceProvider.overrideWithValue(CoinService(store: InMemoryCoinStore())),
        adGateProvider.overrideWithValue(adGate),
      ],
      child: MaterialApp(
        theme: UkalabTheme.light(field: UkalabField.it, cert: UkalabCert.itPassport),
        home: StatefulBuilder(builder: (context, setState) {
          _rebuildParent = () => setState(() {});
          return Scaffold(
            body: LearnScreen(questions: qs, terms: const [], sessionSize: qs.length),
          );
        }),
      ),
    );

String _shown() => find.text('問題Aの文').evaluate().isNotEmpty ? 'A' : 'B';

ChoiceState _stateOf(WidgetTester tester, String text) =>
    tester.widget<ChoiceTile>(find.widgetWithText(ChoiceTile, text)).state;

Future<void> _tapNext(WidgetTester tester) async {
  await tester.ensureVisible(find.text('次へ'));
  await tester.tap(find.text('次へ'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('解答直後(親を再描画しても)解答した問題の解説・正誤・N/全体問目が出る', (tester) async {
    await tester.pumpWidget(_app([_q('qa', 'A'), _q('qb', 'B')], await testAdGate()));
    await tester.pumpAndSettle();

    final first = _shown();
    final other = first == 'A' ? 'B' : 'A';
    final label = KitStrings.of(tester.element(find.byType(QuestionCard))).questionNoOfTotal(1, 2);
    expect(find.text(label), findsOneWidget);

    await tester.tap(find.text('$firstの誤り1'));
    await tester.pumpAndSettle();

    void check() {
      expect(find.text('解説$firstの本文'), findsOneWidget);
      expect(find.text('解説$otherの本文'), findsNothing);
      expect(find.text('問題$firstの文'), findsOneWidget);
      expect(find.text('問題$otherの文'), findsNothing);
      expect(find.text(label), findsOneWidget);
      expect(_stateOf(tester, '$firstの正解'), ChoiceState.correct);
      expect(_stateOf(tester, '$firstの誤り1'), ChoiceState.incorrect);
      expect(_stateOf(tester, '$firstの誤り2'), ChoiceState.idle);
    }

    check();
    _rebuildParent();
    await tester.pumpAndSettle();
    check();
  });

  testWidgets('「次へ」で次の問題に進み、2問目は 2 / 2 になる', (tester) async {
    await tester.pumpWidget(_app([_q('qa', 'A'), _q('qb', 'B')], await testAdGate()));
    await tester.pumpAndSettle();

    final first = _shown();
    final other = first == 'A' ? 'B' : 'A';
    await tester.tap(find.text('$firstの正解'));
    await tester.pumpAndSettle();
    _rebuildParent();
    await tester.pumpAndSettle();
    await _tapNext(tester);

    expect(find.text('問題$otherの文'), findsOneWidget);
    expect(find.text('解説$firstの本文'), findsNothing);
    expect(find.text('解説$otherの本文'), findsNothing);
    expect(_stateOf(tester, '$otherの正解'), ChoiceState.idle);
    final label = KitStrings.of(tester.element(find.byType(QuestionCard))).questionNoOfTotal(2, 2);
    expect(find.text(label), findsOneWidget);
  });

  testWidgets('最後の問題は解説を見てから「次へ」で結果画面へ移る(親を再描画しても)', (tester) async {
    await tester.pumpWidget(_app([_q('qa', 'A'), _q('qb', 'B')], await testAdGate()));
    await tester.pumpAndSettle();

    final first = _shown();
    final other = first == 'A' ? 'B' : 'A';
    await tester.tap(find.text('$firstの正解'));
    await tester.pumpAndSettle();
    await _tapNext(tester);

    await tester.tap(find.text('$otherの誤り1'));
    await tester.pumpAndSettle();
    _rebuildParent();
    await tester.pumpAndSettle();
    expect(find.text('解説$otherの本文'), findsOneWidget);
    expect(find.byType(ResultSummary), findsNothing);
    expect(_stateOf(tester, '$otherの誤り1'), ChoiceState.incorrect);

    await _tapNext(tester);
    expect(find.byType(ResultSummary), findsOneWidget);
  });
}
