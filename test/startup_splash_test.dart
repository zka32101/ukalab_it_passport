import 'package:app_common_kit/app_common_kit.dart' hide SettingsScreen;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_it_passport/main.dart';

void main() {
  testWidgets('起動画面にアイコンとブランド色が渡る', (tester) async {
    await tester.pumpWidget(MaterialApp(home: buildStartupSplash()));
    final splash = tester.widget<StartupSplash>(find.byType(StartupSplash));
    expect(splash.appIconAsset, 'assets/icon/app_icon.png');
    expect(splash.backgroundColor, const Color(0xFF4875DE));
    expect(find.byType(Image), findsWidgets);
  });
}
