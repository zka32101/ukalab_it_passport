import 'dart:convert';

import 'package:app_common_kit/app_common_kit.dart' hide SettingsScreen;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';
import 'package:ukalab_it_passport/data/exam_repository.dart';
import 'package:ukalab_it_passport/main.dart' show UkalabItPassportApp, kAppFontFamily;
import 'package:ukalab_it_passport/screens/home_screen.dart';
import 'package:ukalab_it_passport/screens/learn_screen.dart';
import 'package:ukalab_it_passport/screens/mistake_note_screen.dart';
import 'package:ukalab_it_passport/screens/mock_exam_screen.dart';
import 'package:ukalab_it_passport/screens/pace_run_screen.dart';
import 'package:ukalab_it_passport/screens/reading_screen.dart';
import 'package:ukalab_it_passport/screens/record_screen.dart';
import 'package:ukalab_it_passport/screens/route_planner_screen.dart';
import 'package:ukalab_it_passport/screens/settings_screen.dart';
import 'package:ukalab_it_passport/screens/terms_screen.dart';

import 'test_support.dart';

/// 文字切れ・はみ出しの回帰テスト。
///
/// 狭い幅（320・280dp）× 文字倍率（1・2・3倍）で主要画面を組み、RenderFlex の
/// overflow が出ないことを確かめる。問題は実データのうち、選択肢・問題文・解説が
/// 最長のものを使う（略語・長い用語が多い ITパスポートで起きやすいため）。

const _widths = [320.0, 280.0];
const _scales = [1.0, 2.0, 3.0];

late ExamData _data;
late List<Question> _stress; // 最長の選択肢・問題文・解説を持つ問題

int _maxChoice(Question q) => q.choices.map((c) => c.length).reduce((a, b) => a > b ? a : b);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // アプリと同じ同梱フォントで測る（既定の Ahem だと全角・半角とも1emで実機とずれる）。
    final loader = FontLoader(kAppFontFamily)
      ..addFont(rootBundle.load('assets/fonts/BIZUDPGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BIZUDPGothic-Bold.ttf'));
    await loader.load();
    _data = await loadExamData();
    final qs = _data.activeQuestions;
    final byChoice = [...qs]..sort((a, b) => _maxChoice(b).compareTo(_maxChoice(a)));
    final byPrompt = [...qs]..sort((a, b) => b.prompt.length.compareTo(a.prompt.length));
    final byExpl = [...qs]..sort((a, b) => b.explanation.length.compareTo(a.explanation.length));
    final seen = <String>{};
    _stress = [
      for (final q in [...byChoice.take(4), ...byPrompt.take(3), ...byExpl.take(3)])
        if (seen.add(q.qid)) q,
    ];
  });

  group('文字倍率・狭い幅でのはみ出し', () {
    for (final w in _widths) {
      for (final s in _scales) {
        final tag = '幅${w.toInt()} 倍率$s';

        testWidgets('ホーム $tag', (t) async {
          await _check(t, w, s, (_) => HomeScreen(
                exam: _data.exam,
                questions: _data.activeQuestions,
                terms: _data.terms,
                chapterReadings: _data.chapterReadings,
              ), tall: true);
        });

        testWidgets('学ぶ（出題→解答→解説→結果） $tag', (t) async {
          await _check(t, w, s, (_) => LearnScreen(questions: _stress, terms: _data.terms, sessionSize: 3),
              act: (t) async {
            for (var i = 0; i < 3; i++) {
              await _tapFirst(t, find.byType(ChoiceTile));
              await _settle(t);
              await _tapText(t, '次へ');
              await _settle(t);
            }
          });
        });

        testWidgets('模擬試験（開始画面→出題→結果） $tag', (t) async {
          await _check(t, w, s, (_) => MockExamScreen(exam: _data.exam, questions: _data.activeQuestions),
              act: (t) async {
            await _tapText(t, '模擬試験を始める');
            await _settle(t);
            for (var i = 0; i < 130; i++) {
              if (find.byType(ChoiceTile).evaluate().isEmpty) break;
              await _tapFirst(t, find.byType(ChoiceTile));
              await t.pump(const Duration(milliseconds: 50));
              final next = find.text('次へ');
              await _tapFirst(t, next.evaluate().isNotEmpty ? next : find.text('結果を見る'));
              await t.pump(const Duration(milliseconds: 50));
            }
            await _settle(t);
          });
        });

        testWidgets('100問ペース走 $tag', (t) async {
          await _check(t, w, s, (_) => Scaffold(body: PaceRunScreen(questions: _stress)),
              act: (t) async {
            final start = find.byType(FilledButton);
            if (start.evaluate().isNotEmpty) await _tapFirst(t, start);
            await _settle(t);
            for (var i = 0; i < 3; i++) {
              if (find.byType(ChoiceTile).evaluate().isEmpty) break;
              await _tapFirst(t, find.byType(ChoiceTile));
              await _settle(t);
            }
          });
        });

        testWidgets('学習の記録 $tag', (t) async {
          await _check(t, w, s, (_) => RecordScreen(exam: _data.exam, questions: _data.activeQuestions),
              prefs: _seededPrefs(), tall: true);
        });

        testWidgets('設定（購入2商品） $tag', (t) async {
          PackageInfo.setMockInitialValues(
              appName: 'a', packageName: 'p', version: '1.0.0', buildNumber: '1', buildSignature: '');
          await _check(t, w, s, (_) => Scaffold(
                body: SettingsScreen(questions: _data.activeQuestions, exam: _data.exam, terms: _data.terms),
              ), tall: true);
        });

        testWidgets('用語集（検索・用語カード） $tag', (t) async {
          await _check(t, w, s, (_) => Scaffold(body: TermsScreen(exam: _data.exam, terms: _data.terms)),
              tall: true, act: (t) async {
            final tiles = find.byType(ListTile);
            if (tiles.evaluate().isNotEmpty) {
              await _tapFirst(t, tiles);
              await _settle(t);
            }
          });
        });

        testWidgets('解説読み物（一覧→本文） $tag', (t) async {
          await _check(t, w, s, (_) => Scaffold(
                body: ReadingListScreen(
                  readings: _data.chapterReadings,
                  terms: _data.terms,
                  questions: _data.activeQuestions,
                  termReferences: _data.termReferences,
                ),
              ), tall: true, act: (t) async {
            await _tapFirst(t, find.byType(ListTile));
            await _settle(t);
          });
        });

        testWidgets('間違いノート $tag', (t) async {
          await _check(t, w, s, (_) => MistakeNoteScreen(
                exam: _data.exam,
                questions: _data.activeQuestions,
                terms: _data.terms,
              ), prefs: _seededPrefs(), tall: true);
        });

        testWidgets('最短ルートプランナー $tag', (t) async {
          await _check(t, w, s, (_) => RoutePlannerScreen(
                exam: _data.exam,
                level: _data.exam.levels.first,
                questions: _data.activeQuestions,
              ), prefs: _seededPrefs(), tall: true);
        });

        testWidgets('ホーム（プレミアム購入済み） $tag', (t) async {
          await _check(t, w, s, (_) => HomeScreen(
                exam: _data.exam,
                questions: _data.activeQuestions,
                terms: _data.terms,
                chapterReadings: _data.chapterReadings,
              ), prefs: _seededPrefs(), tall: true, premium: true);
        });

        testWidgets('設定（プレミアム購入済み） $tag', (t) async {
          PackageInfo.setMockInitialValues(
              appName: 'a', packageName: 'p', version: '1.0.0', buildNumber: '1', buildSignature: '');
          await _check(t, w, s, (_) => Scaffold(
                body: SettingsScreen(questions: _data.activeQuestions, exam: _data.exam, terms: _data.terms),
              ), tall: true, premium: true);
        });

        testWidgets('学ぶ（ながら学習モード） $tag', (t) async {
          await _check(t, w, s, (_) => LearnScreen(questions: _stress, terms: _data.terms, sessionSize: 3),
              act: (t) async {
            final container = ProviderScope.containerOf(t.element(find.byType(LearnScreen)));
            await container.read(handsFreeProvider.notifier).setEnabled(true);
            await _settle(t);
          });
        },
            // 共通キット app_common_kit の HandsFreeQuestionLayout は、選択肢のボタンを画面下に
            // 固定して並べるだけでスクロールせず、文字倍率2倍以上だと収まらない。キット側の修正が要るため、
            // このリポジトリでは1倍だけ検証し、2倍・3倍は修正後に外す。
            skip: s > 1.0);

        testWidgets('アプリ全体（下部ナビ・各タブ） $tag', (t) async {
          await _checkApp(t, w, s);
        });
      }
    }
  });
}

/// 進捗・履歴が入った状態にする（記録・間違いノート・ルートプランナーの表示用）。
Map<String, Object> _seededPrefs() {
  final qs = _data.activeQuestions.take(60).toList();
  final progress = {for (var i = 0; i < qs.length; i++) qs[i].qid: i % 3 != 0};
  final now = DateTime.now();
  final history = [
    for (var i = 0; i < qs.length; i++)
      {
        'qid': qs[i].qid,
        'correct': i % 3 != 0,
        'ms': 4000,
        'at': now.subtract(Duration(hours: i)).toIso8601String(),
      },
  ];
  return {
    'ukalab_it_passport_progress_v1': jsonEncode(progress),
    'ukalab_it_passport_history_v1': jsonEncode(history),
    'ukalab_it_passport_streak_days_v1': 123,
    'ukalab_it_passport_mock_passed_ever_v1': true,
  };
}

Future<List<Override>> _overrides({bool premium = false}) async {
  final coin = CoinService(store: InMemoryCoinStore());
  await coin.load();
  return [
    handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
    ...studyNotesTestOverrides(),
    coinServiceProvider.overrideWithValue(coin),
    outfitServiceProvider.overrideWithValue(OutfitService(store: InMemoryOutfitStore())),
    entitlementServiceProvider.overrideWithValue(FakeEntitlementService(
      initial: premium ? const EntitlementState(hasPremium: true) : EntitlementState.free,
      availableOffers: const [
        EntitlementOffer(id: 'noads', productId: 'it_passport_noads', title: '広告非表示', priceString: '¥480'),
        EntitlementOffer(
          id: 'premium',
          productId: 'it_passport_premium',
          title: 'プレミアム（広告非表示＋追加機能）',
          priceString: '¥1,500',
        ),
      ],
    )),
    adGateProvider.overrideWithValue(await testAdGate()),
    examStatsServiceProvider.overrideWithValue(FakeExamStatsService()),
  ];
}

ThemeData _theme() {
  final t = UkalabTheme.light(field: UkalabField.it, cert: UkalabCert.itPassport);
  return t.copyWith(
    textTheme: t.textTheme.apply(fontFamily: kAppFontFamily),
    primaryTextTheme: t.primaryTextTheme.apply(fontFamily: kAppFontFamily),
  );
}

Widget _wrap(List<Override> overrides, double scale, Widget home) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: _theme(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Material(child: home),
      ),
    );

/// 画面を組み、[act] で操作しながら、出た overflow を集めて空であることを確かめる。
Future<void> _check(
  WidgetTester tester,
  double width,
  double scale,
  Widget Function(BuildContext) build, {
  Map<String, Object>? prefs,
  bool tall = false,
  bool premium = false,
  Future<void> Function(WidgetTester)? act,
}) async {
  SharedPreferences.setMockInitialValues(prefs ?? {});
  tester.view.physicalSize = Size(width, tall ? 6000 : 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final errors = <String>[];
  final prior = FlutterError.onError;
  FlutterError.onError = (d) {
    final s = d.exceptionAsString();
    if (s.contains('overflowed')) {
      errors.add(_describe(d));
    } else {
      prior?.call(d);
    }
  };
  addTearDown(() => FlutterError.onError = prior);

  final overrides = await _overrides(premium: premium);
  await tester.pumpWidget(_wrap(overrides, scale, Builder(builder: build)));
  await _settle(tester);
  if (act != null) await act(tester);
  // 画面を片付ける（ペース走のタイマーを止める）。
  await tester.pumpWidget(const SizedBox());
  await tester.pump();

  FlutterError.onError = prior;
  expect(errors, isEmpty, reason: errors.join('\n'));
}

Future<void> _checkApp(WidgetTester tester, double width, double scale) async {
  SharedPreferences.setMockInitialValues(_seededPrefs());
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final errors = <String>[];
  final prior = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exceptionAsString().contains('overflowed')) {
      errors.add(_describe(d));
    } else {
      prior?.call(d);
    }
  };
  addTearDown(() => FlutterError.onError = prior);

  final overrides = await _overrides();
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.runAsync(() async {
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: const UkalabItPassportApp(),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await _settle(tester);
  // 下部ナビの各タブを順に開く。
  final dests = find.byType(NavigationDestination);
  final n = dests.evaluate().length;
  for (var i = 0; i < n; i++) {
    await tester.tap(dests.at(i), warnIfMissed: false);
    await _settle(tester);
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  FlutterError.onError = prior;
  expect(errors, isEmpty, reason: errors.join('\n'));
}

Future<void> _settle(WidgetTester tester) async {
  // タイマー（ペース走・模擬試験）が残っても止まるよう、pumpAndSettle は使わず時間を区切って進める。
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapFirst(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) return;
  await tester.ensureVisible(f.first);
  await tester.tap(f.first, warnIfMissed: false);
}

Future<void> _tapText(WidgetTester tester, String text) => _tapFirst(tester, find.text(text));

/// overflow の報告から、はみ出した量と原因ウィジェットの位置を取り出す。
String _describe(FlutterErrorDetails d) {
  final text = d.toString();
  final head = d.exceptionAsString().split('\n').first;
  final m = RegExp(r'relevant error-causing widget was:\s*\n\s*(.*)\n\s*(.*)').firstMatch(text);
  return m == null ? head : '$head @ ${m.group(1)} ${m.group(2)}';
}
