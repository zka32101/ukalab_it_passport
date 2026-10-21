import 'package:app_common_kit/app_common_kit.dart' show EntitlementState, entitlementStateProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart' show characterAppIdProvider, characterPremiumProvider;

/// ukalab_core に登録されている、このアプリの appId（資格専用キャラの絞り込み用）。
const kCharacterAppId = 'it_passport';

/// 資格専用キャラ（サーキ）の配線。appId と、プレミアムかどうか（権利の変化に追従）を core に渡す。
final List<Override> characterOverrides = [
  characterAppIdProvider.overrideWithValue(kCharacterAppId),
  characterPremiumProvider.overrideWith(
    (ref) => (ref.watch(entitlementStateProvider).valueOrNull ?? EntitlementState.free).hasPremium,
  ),
];
