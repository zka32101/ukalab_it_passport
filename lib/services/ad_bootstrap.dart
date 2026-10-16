import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/foundation.dart';

import 'no_ads_backend.dart';

/// 広告の初期化。失敗しても起動を止めず、広告なしで続行する。
///
/// [AdGate.init] は、リリースビルドでテスト広告IDが残っていると [StateError] を投げる。
/// それを `main` でそのまま呼ぶと起動時に落ちるため、ここで握りつぶし、
/// 理由を [log] に出したうえで「広告を出さない [AdGate]」を返す。
/// 広告を出さない [AdGate] は、空のユニットID＋[NoAdsBackend]（SDK を触らない）で作る。
Future<AdGate> initAdGateSafely({
  required AdUnitIds unitIds,
  required bool Function() adsHidden,
  AdsBackend? backend,
  bool isRelease = kReleaseMode,
  void Function(String message) log = debugPrint,
}) async {
  try {
    return await AdGate.init(
      config: AdConfig(unitIds: unitIds),
      backend: backend,
      adsHidden: adsHidden,
      isRelease: isRelease,
    );
  } catch (e) {
    log('AdGate.init failed; continuing without ads: $e');
    return AdGate.init(
      config: const AdConfig(unitIds: AdUnitIds(banner: '', interstitial: '', rewarded: '')),
      backend: NoAdsBackend(),
      adsHidden: () => true,
      isRelease: isRelease,
    );
  }
}

/// 使う RevenueCat の公開SDKキーを選ぶ。キーが空、または対象外のプラットフォームなら
/// null（仮の購入サービスを使う）。キーは `--dart-define` で渡し、コミットしない。
String? revenueCatKeyFor({
  required bool isWeb,
  required bool isAndroid,
  required bool isIOS,
  required String googleKey,
  required String appleKey,
}) {
  if (isWeb) return null;
  if (isAndroid && googleKey.isNotEmpty) return googleKey;
  if (isIOS && appleKey.isNotEmpty) return appleKey;
  return null;
}
