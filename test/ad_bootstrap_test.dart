import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_it_passport/services/ad_bootstrap.dart';

import 'test_support.dart';

const _testIds = AdUnitIds(
  banner: 'ca-app-pub-3940256099942544/6300978111',
  interstitial: 'ca-app-pub-3940256099942544/1033173712',
  rewarded: 'ca-app-pub-3940256099942544/5224354917',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('initAdGateSafely', () {
    test('リリース扱いでテスト広告IDが残っていても例外にならず、理由をログに出す', () async {
      // 素の AdGate.init なら StateError になる条件。
      await expectLater(
        AdGate.init(
          config: const AdConfig(unitIds: _testIds),
          adsHidden: () => false,
          backend: FakeAdsBackend(),
          isRelease: true,
        ),
        throwsStateError,
      );

      final logs = <String>[];
      final gate = await initAdGateSafely(
        unitIds: _testIds,
        adsHidden: () => false,
        backend: FakeAdsBackend(),
        isRelease: true,
        log: logs.add,
      );
      expect(logs.single, contains('continuing without ads'));
      // 広告なしの AdGate: インタースティシャルは出ない。
      expect(await gate.maybeShowInterstitial(InterstitialTrigger.sessionEnd), isFalse);
    });

    test('デバッグ扱いのテストIDは従来どおり初期化でき、ログも出ない', () async {
      final logs = <String>[];
      final gate = await initAdGateSafely(
        unitIds: _testIds,
        adsHidden: () => false,
        backend: FakeAdsBackend(),
        isRelease: false,
        log: logs.add,
      );
      expect(logs, isEmpty);
      expect(gate, isA<AdGate>());
    });
  });

  group('revenueCatKeyFor', () {
    String? k({bool web = false, bool android = false, bool ios = false, String g = '', String a = ''}) =>
        revenueCatKeyFor(isWeb: web, isAndroid: android, isIOS: ios, googleKey: g, appleKey: a);

    test('Android は Google キー、iOS は Apple キーを使う', () {
      expect(k(android: true, g: 'goog_x', a: 'appl_y'), 'goog_x');
      expect(k(ios: true, g: 'goog_x', a: 'appl_y'), 'appl_y');
    });

    test('キー未指定・Web・対象外は null（仮の購入サービス）', () {
      expect(k(android: true), isNull);
      expect(k(ios: true), isNull);
      expect(k(ios: true, g: 'goog_x'), isNull);
      expect(k(android: true, a: 'appl_y'), isNull);
      expect(k(web: true, g: 'goog_x', a: 'appl_y'), isNull);
      expect(k(g: 'goog_x', a: 'appl_y'), isNull);
    });
  });
}
