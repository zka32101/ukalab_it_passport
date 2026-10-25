import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_it_passport/main.dart';

void main() {
  testWidgets('起動画面に透過アイコンとブランド色が渡る', (tester) async {
    await tester.pumpWidget(MaterialApp(home: buildStartupSplash()));
    final splash = tester.widget<UkalabStartupSplash>(find.byType(UkalabStartupSplash));
    expect(splash.iconAsset, 'assets/icon/app_icon_foreground.png');
    expect(splash.backgroundColor, const Color(0xFF4875DE));
    expect(find.byType(Image), findsWidgets);
  });
}
