import 'package:app_common_kit/app_common_kit.dart' hide SettingsScreen;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/cross_promo.dart' show UkalabCrossPromoSection;
import 'package:ukalab_core/src/cross_promo_test_support.dart'
    show ukalabCrossPromoSectionForTest;
import 'package:ukalab_it_passport/screens/settings_screen.dart';

import 'test_support.dart';

const _appId = 'com.yourwish.ukalab.it_passport';
const _sampleJson =
    '[{"id":"com.example.ukalab.other","name":"うかラボ サンプル","tagline":"テスト用",'
    '"iconUrl":"","storeUrl":"https://example.com","category":"うかラボ"},'
    '{"id":"$_appId","name":"自アプリ","tagline":"","iconUrl":"",'
    '"storeUrl":"https://example.com","category":"うかラボ"}]';

Future<void> _pumpInList(WidgetTester tester, Widget w) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: ListView(children: [w]))),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('掲載リストが空なら何も表示されず例外にならない', (tester) async {
    await _pumpInList(
      tester,
      ukalabCrossPromoSectionForTest(currentAppId: _appId, rawJson: '[]'),
    );
    expect(find.text('他のアプリもチェック！'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Firebase 未初期化でも例外にならない', (tester) async {
    await _pumpInList(
      tester,
      const UkalabCrossPromoSection(currentAppId: _appId),
    );
    expect(find.text('他のアプリもチェック！'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('掲載リストがあれば自アプリを除いて表示する', (tester) async {
    await _pumpInList(
      tester,
      ukalabCrossPromoSectionForTest(currentAppId: _appId, rawJson: _sampleJson),
    );
    expect(find.text('他のアプリもチェック！'), findsOneWidget);
    expect(find.text('うかラボ サンプル'), findsOneWidget);
    expect(find.text('自アプリ'), findsNothing);
  });

  testWidgets('設定画面が Firebase 無しで例外なく表示される', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entitlementServiceProvider.overrideWithValue(FakeEntitlementService()),
          handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
          ...studyNotesTestOverrides(),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('他のアプリもチェック！'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
