import 'package:app_common_kit/app_common_kit.dart' hide SettingsScreen;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';
import 'package:ukalab_it_passport/screens/settings_screen.dart';

import 'test_support.dart';

const _noAdsOffer = EntitlementOffer(
  id: 'noads',
  productId: 'it_passport_noads',
  title: '広告非表示',
  priceString: '¥480',
);
const _premiumOffer = EntitlementOffer(
  id: 'premium',
  productId: 'it_passport_premium',
  title: 'プレミアム（広告非表示＋追加機能）',
  priceString: '¥1,500',
);

FakeEntitlementService _service() => FakeEntitlementService(
      availableOffers: const [_noAdsOffer, _premiumOffer],
      grantOnPurchase: const {
        'it_passport_noads': EntitlementState(hasNoAds: true),
        'it_passport_premium': EntitlementState(hasPremium: true),
      },
    );

Widget _app(
  FakeEntitlementService service, {
  FileSaver? saver,
  DateTime Function()? now,
}) =>
    ProviderScope(
      overrides: [
        entitlementServiceProvider.overrideWithValue(service),
        handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
        ...studyNotesTestOverrides(),
      ],
      child: MaterialApp(
        home: Scaffold(body: SettingsScreen(fileSaver: saver, now: now)),
      ),
    );

class _SavedFile {
  _SavedFile(this.bytes, this.fileName, this.mimeType);
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  /// BOM（先頭3バイト）を除いた本文。
  String get body => utf8.decode(bytes.sublist(3));
}

/// 保存（共有）の呼び出しを記録するフェイク。[result] が false なら共有シートを閉じた扱い。
class _FakeSaver {
  _FakeSaver({this.result = true, this.error});
  final List<_SavedFile> calls = [];
  final bool result;
  final Object? error;

  Future<bool> call({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    Object? sharePositionOrigin,
  }) async {
    if (error != null) throw error!;
    calls.add(_SavedFile(bytes, fileName, mimeType));
    return result;
  }
}

void _seedHistory(List<ProgressRecord> records) {
  SharedPreferences.setMockInitialValues({
    if (records.isNotEmpty) 'ukalab_it_passport_history_v1': encodeHistory(records),
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
  await tester.pump();
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapDownload(WidgetTester tester) async {
  final tile = find.byKey(const ValueKey('downloadHistoryCsv'));
  await tester.scrollUntilVisible(tile, 300, scrollable: find.byType(Scrollable).first);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('バージョンは固定文字でなく、実際の版を表示する', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'test',
      packageName: 'com.example.test',
      version: '9.8.7',
      buildNumber: '42',
      buildSignature: '',
    );
    await tester.pumpWidget(_app(_service()));
    await tester.pumpAndSettle();

    expect(find.text('9.8.7'), findsOneWidget);
    expect(find.text('0.1.0'), findsNothing);
  });

  testWidgets('無料の間は購入ボタンが出る', (tester) async {
    await tester.pumpWidget(_app(_service()));
    await tester.pumpAndSettle();

    expect(find.text('広告非表示'), findsOneWidget);
    expect(find.text('¥480'), findsOneWidget);
    expect(find.text('プレミアム（広告非表示＋追加機能）'), findsOneWidget);
  });

  testWidgets('購入すると購入済み表示になり、ボタンが消える', (tester) async {
    final service = _service();
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('¥480'));
    await tester.pumpAndSettle();

    expect(find.text('広告非表示を購入済みです'), findsOneWidget);
    expect(find.text('広告非表示'), findsNothing);
    expect(service.state.hasNoAds, isTrue);
  });

  testWidgets('復元できる購入がなければその旨を表示する', (tester) async {
    await tester.pumpWidget(_app(_service()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('購入を復元'));
    await tester.pumpAndSettle();

    expect(find.text('復元できる購入がありませんでした。'), findsOneWidget);
  });

  testWidgets('復元できる購入があれば購入済み表示になる', (tester) async {
    final service = _service()..restorable = const EntitlementState(hasPremium: true);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('購入を復元'));
    await tester.pumpAndSettle();

    expect(find.text('購入を復元しました。'), findsOneWidget);
    expect(find.text('プレミアムを購入済みです'), findsOneWidget);
  });

  testWidgets('設定画面の相互紹介は、掲載リストが空（Firebase無し）なら何も出ず例外にもならない', (tester) async {
    await tester.pumpWidget(_app(_service()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('他のアプリもチェック！'), findsNothing);
  });

  testWidgets('無料の間は、プレミアムでできること（広告なし・実在する機能）が出る', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_service()));
    await tester.pumpAndSettle();

    expect(find.byType(PremiumBenefitsCard), findsOneWidget);
    expect(find.text('プレミアムでできること'), findsOneWidget);
    for (final f in [
      PremiumFeature.weakDrill,
      PremiumFeature.examEveMode,
      PremiumFeature.tenMinutePlan,
      PremiumFeature.mockExamHistory,
      PremiumFeature.customMockExam,
      PremiumFeature.readingReadAloud,
    ]) {
      expect(find.byKey(ValueKey('premiumBenefit_${f.name}')), findsOneWidget);
    }
    // 設定のCSVは無料なので、プレミアム限定としては載せない。
    expect(find.byKey(const ValueKey('premiumBenefit_historyExport')), findsNothing);
    expect(find.textContaining('広告も表示されなくなります'), findsOneWidget);
    final all = kItPassportPremiumBenefits.allTexts.join();
    expect(all.contains('公式'), isFalse);
    expect(all.contains('合格保証'), isFalse);
    expect(all.contains('サーキ'), isFalse);
    expect(all.contains('円'), isFalse);
  });

  testWidgets('プレミアム購入済みなら、プレミアムでできること は出さない', (tester) async {
    _tall(tester);
    final service = _service()..restorable = const EntitlementState(hasPremium: true);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumBenefitsCard), findsOneWidget);

    await tester.tap(find.text('購入を復元'));
    await tester.pumpAndSettle();

    expect(find.byType(PremiumBenefitsCard), findsNothing);
  });

  group('学習履歴のCSV（ファイル保存・共有）', () {
    testWidgets('履歴があれば、UTF-8 BOM付き text/csv で ukalab_history_YYYYMMDD.csv として渡す', (tester) async {
      _seedHistory([
        ProgressRecord(
          qid: 'q1',
          subjectId: 'ml_overview',
          correct: true,
          at: DateTime(2026, 10, 14, 9),
          topicId: 'overfitting',
        ),
      ]);
      final saver = _FakeSaver();
      await tester.pumpWidget(_app(_service(), saver: saver.call, now: () => DateTime(2026, 10, 20, 8)));
      await _settle(tester);

      await _tapDownload(tester);

      expect(saver.calls, hasLength(1));
      final f = saver.calls.single;
      expect(f.fileName, 'ukalab_history_20261020.csv');
      expect(f.mimeType, 'text/csv');
      expect(f.bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
      expect(f.body, contains('2026-10-14'));
      // 個人情報（氏名・ID・端末情報・問題文）の列を持たない。
      final lines = f.body.split('\n');
      expect(lines.first, '日付,解答数,正答数,正答率(%),学習時間(分)');
      expect(lines, contains('分野,解答数,正答数,正答率(%)'));
      expect(f.body.contains('q1'), isFalse); // 問題ID・問題文は含めない
      expect(find.text(ExamPrepStrings.ja.exportSaved), findsOneWidget);
      expect(find.text('学習履歴をコピーしました。'), findsNothing);
    });

    testWidgets('履歴が空なら保存せず、その旨を表示する', (tester) async {
      _seedHistory(const []);
      final saver = _FakeSaver();
      await tester.pumpWidget(_app(_service(), saver: saver.call));
      await _settle(tester);

      await _tapDownload(tester);

      expect(saver.calls, isEmpty);
      expect(find.text('まだ学習履歴がありません。'), findsOneWidget);
    });

    testWidgets('保存に失敗したら失敗の文言を出す（例外にしない）', (tester) async {
      _seedHistory([
        ProgressRecord(
          qid: 'q1',
          subjectId: 'ml_overview',
          correct: false,
          at: DateTime(2026, 10, 14, 9),
          topicId: 'overfitting',
        ),
      ]);
      final saver = _FakeSaver(error: StateError('share failed'));
      await tester.pumpWidget(_app(_service(), saver: saver.call));
      await _settle(tester);

      await _tapDownload(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(ExamPrepStrings.ja.exportSaveFailed), findsOneWidget);
    });

    testWidgets('共有シートを閉じた（保存されなかった）ときは、保存済みと言わない', (tester) async {
      _seedHistory([
        ProgressRecord(
          qid: 'q1',
          subjectId: 'ml_overview',
          correct: true,
          at: DateTime(2026, 10, 14, 9),
          topicId: 'overfitting',
        ),
      ]);
      final saver = _FakeSaver(result: false);
      await tester.pumpWidget(_app(_service(), saver: saver.call));
      await _settle(tester);

      await _tapDownload(tester);

      expect(saver.calls, hasLength(1));
      expect(find.text(ExamPrepStrings.ja.exportSaved), findsNothing);
    });
  });
}
