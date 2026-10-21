import 'package:app_common_kit/app_common_kit.dart' hide SettingsScreen;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_it_passport/data/character_wiring.dart';
import 'package:ukalab_it_passport/data/exam_repository.dart';
import 'package:ukalab_it_passport/screens/home_screen.dart';
import 'package:ukalab_it_passport/screens/settings_screen.dart';

import 'test_support.dart';

/// ホームの推しカードの onLockedTap（ロック中の資格専用キャラ「サーキ」→ 設定の購入欄）の確認。

late ExamData _data;

/// 推しが常にアニメーションするため pumpAndSettle は使えない。一定時間だけ進める。
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _boot(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final coin = CoinService(store: InMemoryCoinStore());
  await coin.load();
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    overrides: [
      handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
      ...studyNotesTestOverrides(),
      coinServiceProvider.overrideWithValue(coin),
      outfitServiceProvider.overrideWithValue(OutfitService(store: InMemoryOutfitStore())),
      entitlementServiceProvider.overrideWithValue(FakeEntitlementService()),
      adGateProvider.overrideWithValue(await testAdGate()),
      examStatsServiceProvider.overrideWithValue(FakeExamStatsService()),
      ...characterOverrides,
    ],
    child: MaterialApp(
      theme: UkalabTheme.light(field: UkalabField.it, cert: UkalabCert.itPassport),
      home: Material(
        child: HomeScreen(
          exam: _data.exam,
          questions: _data.activeQuestions,
          terms: _data.terms,
          chapterReadings: _data.chapterReadings,
        ),
      ),
    ),
  ));
  await _pumpFrames(tester);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _data = await loadExamData();
  });

  testWidgets('ホームの UkalabOshiCard に onLockedTap が渡っている', (tester) async {
    await _boot(tester);
    final card = tester.widget<UkalabOshiCard>(find.byType(UkalabOshiCard));
    expect(card.onLockedTap, isNotNull);
  });

  testWidgets('無料でサーキのプレビューから「プレミアムを見る」を押すと、設定の購入欄が見える位置で開く', (tester) async {
    await _boot(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await _pumpFrames(tester);
    await tester.tap(find.text('推しを選ぶ'));
    await _pumpFrames(tester);
    expect(find.byType(CharacterSelectScreen), findsOneWidget);

    final circa = find.text('サーキ');
    await tester.ensureVisible(circa);
    await _pumpFrames(tester);
    await tester.tap(circa);
    await _pumpFrames(tester);
    await tester.tap(find.text('プレミアムを見る'));
    await _pumpFrames(tester);

    expect(find.byType(CharacterSelectScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
    final header = find.text('購入');
    expect(header, findsOneWidget);
    // 画面内（高さ 6000 の縦長ビュー）に収まっている。
    final top = tester.getTopLeft(header).dy;
    expect(top, greaterThanOrEqualTo(0));
    expect(top, lessThan(6000));
  });

  testWidgets('SettingsScreen(focusPurchase) は標準の 800x600 でも購入欄までスクロールする', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      overrides: [
        handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
        ...studyNotesTestOverrides(),
        entitlementServiceProvider.overrideWithValue(FakeEntitlementService()),
      ],
      child: const MaterialApp(home: Scaffold(body: SettingsScreen(focusPurchase: true))),
    ));
    await tester.pumpAndSettle();
    final top = tester.getTopLeft(find.text('購入')).dy;
    expect(top, greaterThanOrEqualTo(0));
    expect(top, lessThan(600));
  });
}
