import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_it_passport/data/exam_repository.dart';
import 'package:ukalab_it_passport/screens/home_screen.dart';
import 'package:ukalab_it_passport/screens/learn_screen.dart';
import 'package:ukalab_it_passport/screens/mistake_note_screen.dart';
import 'package:ukalab_it_passport/screens/pace_run_screen.dart';
import 'package:ukalab_it_passport/screens/reading_screen.dart';
import 'package:ukalab_it_passport/screens/route_planner_screen.dart';
import 'package:ukalab_it_passport/screens/terms_screen.dart';

import 'test_support.dart';

/// ホームの区切りと、「学ぶ」タブの「道具」への入口の移動の確認。
/// 見出し名は ukalab_g_kentei / ukalab_boki のホームと同じ（今日やること／記録／試験に向けて／道具）。

late ExamData _data;

Future<Widget> _app(Widget home) async {
  final coin = CoinService(store: InMemoryCoinStore());
  await coin.load();
  return ProviderScope(
    overrides: [
      handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
      ...studyNotesTestOverrides(),
      coinServiceProvider.overrideWithValue(coin),
      outfitServiceProvider.overrideWithValue(OutfitService(store: InMemoryOutfitStore())),
      entitlementServiceProvider.overrideWithValue(FakeEntitlementService()),
      adGateProvider.overrideWithValue(await testAdGate()),
      examStatsServiceProvider.overrideWithValue(FakeExamStatsService()),
    ],
    child: MaterialApp(
      theme: UkalabTheme.light(field: UkalabField.it, cert: UkalabCert.itPassport),
      home: Material(child: home),
    ),
  );
}

Future<void> _boot(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final app = await _app(home);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(app);
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapAndBack(WidgetTester tester, String text, Type screen) async {
  await tester.tap(find.text(text));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(screen), findsOneWidget, reason: '$text の先の画面');
  Navigator.of(tester.element(find.byType(screen))).pop();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _data = await loadExamData();
  });

  Widget home() => HomeScreen(
        exam: _data.exam,
        questions: _data.activeQuestions,
        terms: _data.terms,
        chapterReadings: _data.chapterReadings,
      );

  Widget learn() => LearnScreen(
        questions: _data.activeQuestions,
        terms: _data.terms,
        exam: _data.exam,
        chapterReadings: _data.chapterReadings,
      );

  testWidgets('ホームは「今日やること／記録／試験に向けて」の3区切り', (tester) async {
    await _boot(tester, home());
    for (final h in ['今日やること', '記録', '試験に向けて']) {
      expect(find.widgetWithText(HomeSectionHeader, h), findsOneWidget, reason: h);
    }
    expect(find.byType(HomeSectionHeader), findsNWidgets(3));
  });

  testWidgets('ホームの入口からプランナーとペース走に行ける', (tester) async {
    await _boot(tester, home());
    expect(find.text('最短ルートプランナー'), findsOneWidget);
    expect(find.text('100問ペース走'), findsOneWidget);
    await _tapAndBack(tester, '最短ルートプランナー', RoutePlannerScreen);
    await _tapAndBack(tester, '100問ペース走', PaceRunScreen);
  });

  testWidgets('用語集・読み物・メモ・間違いノートはホームから「学ぶ」へ移った', (tester) async {
    await _boot(tester, home());
    expect(find.text('用語集'), findsNothing);
    expect(find.text('分野ごとの解説読み物'), findsNothing);
    expect(find.text('間違いノート'), findsNothing);
    expect(find.byType(StudyNotesHomeCards), findsNothing);
  });

  testWidgets('「学ぶ」の「道具」から全入口（間違いノート・メモ・用語集・読み物）に行ける', (tester) async {
    expect(_data.chapterReadings, isNotEmpty);
    await _boot(tester, learn());
    expect(find.widgetWithText(HomeSectionHeader, '道具'), findsOneWidget);
    expect(find.byType(StudyNotesHomeCards), findsOneWidget);
    await _tapAndBack(tester, '間違いノート', MistakeNoteScreen);
    await _tapAndBack(tester, '用語集', TermsScreen);
    await _tapAndBack(tester, '分野ごとの解説読み物', ReadingListScreen);
  });

  testWidgets('演習だけを開く使い方（exam なし）では「道具」を出さない', (tester) async {
    await _boot(
        tester, LearnScreen(questions: _data.activeQuestions, terms: _data.terms));
    expect(find.widgetWithText(HomeSectionHeader, '道具'), findsNothing);
  });
}
