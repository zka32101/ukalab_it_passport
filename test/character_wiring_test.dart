import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart' show characterAppIdProvider, characterPremiumProvider;
import 'package:ukalab_it_passport/data/character_wiring.dart';

void main() {
  test('appId は it_passport', () {
    final c = ProviderContainer(overrides: characterOverrides);
    addTearDown(c.dispose);
    expect(c.read(characterAppIdProvider), 'it_passport');
  });

  test('プレミアム判定は権利に追従する（無料 false、プレミアム true）', () {
    var state = EntitlementState.free;
    final c = ProviderContainer(overrides: [
      ...characterOverrides,
      entitlementStateProvider.overrideWith((ref) => Stream.value(state)),
    ]);
    addTearDown(c.dispose);
    c.listen(characterPremiumProvider, (_, __) {});
    return Future(() async {
      await c.read(entitlementStateProvider.future);
      expect(c.read(characterPremiumProvider), isFalse);
      state = const EntitlementState(hasPremium: true);
      c.invalidate(entitlementStateProvider);
      await c.read(entitlementStateProvider.future);
      expect(c.read(characterPremiumProvider), isTrue);
    });
  });
}
