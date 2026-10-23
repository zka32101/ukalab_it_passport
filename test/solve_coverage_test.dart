import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_it_passport/data/app_cert.dart';
import 'package:ukalab_it_passport/data/progress_store.dart';
import 'package:ukalab_it_passport/data/solve_coverage.dart';
import 'package:ukalab_it_passport/screens/reading_screen.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q(String qid, String subjectId) => Question(
      qid: qid,
      examId: 'it_passport',
      subjectId: subjectId,
      topicId: 't',
      prompt: 'p',
      choices: const ['a', 'b'],
      answerIndex: 0,
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

ChapterReading _r(String id, String subjectId, List<String> qids) => ChapterReading(
      readingId: id,
      examId: 'it_passport',
      subjectId: subjectId,
      title: 'title-$id',
      sections: const [ReadingSection(heading: 'h', body: 'b')],
      relatedQuestionIds: qids,
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

class _FakeProgress extends ProgressNotifier {
  _FakeProgress(this._answered);
  final Map<String, bool> _answered;
  @override
  ProgressState build() => ProgressState(answeredQidToCorrect: _answered);
}

Widget _app(Map<String, bool> answered, List<Question> qs, List<ChapterReading> rs,
    {Brightness brightness = Brightness.light, UkalabCert cert = UkalabCert.itPassport}) {
  return ProviderScope(
    overrides: [
      progressProvider.overrideWith(() => _FakeProgress(answered)),
      appCertProvider.overrideWithValue(cert),
    ],
    child: MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: brightness)),
      home: Scaffold(
        body: ReadingListScreen(
          readings: rs,
          terms: const [],
          questions: qs,
          termReferences: const [],
          subjectNames: const {'business': 'ビジネス'},
        ),
      ),
    ),
  );
}

void main() {
  group('solveCoverageStage', () {
    test('0%は0、100%は最大、途中は1〜3', () {
      expect(solveCoverageStage(0), 0);
      expect(solveCoverageStage(0.01), 1);
      expect(solveCoverageStage(0.33), 1);
      expect(solveCoverageStage(0.34), 2);
      expect(solveCoverageStage(0.5), 2);
      expect(solveCoverageStage(0.67), 3);
      expect(solveCoverageStage(0.99), 3);
      expect(solveCoverageStage(1), solveCoverageStages - 1);
      expect(solveCoverageStage(2), solveCoverageStages - 1);
      expect(solveCoverageStage(-1), 0);
      expect(solveCoverageStage(double.nan), 0);
    });
  });

  group('solveCoverageColor（資格色）', () {
    for (final b in Brightness.values) {
      for (final cert in UkalabCert.values) {
        final certColor = certColorFor(cert, b);
        final scheme = ColorScheme.fromSeed(seedColor: Colors.teal, brightness: b);
        test('${cert.id}/$b: 0%は無色、段階が上がるほど資格色に近づき100%で資格色', () {
          expect(solveCoverageColor(scheme, certColor, 0), scheme.surface);
          final colors = [for (final r in [0.0, 0.2, 0.5, 0.8, 1.0]) solveCoverageColor(scheme, certColor, r)];
          double dist(Color c) =>
              (c.r - certColor.r).abs() + (c.g - certColor.g).abs() + (c.b - certColor.b).abs();
          for (var i = 1; i < colors.length; i++) {
            expect(dist(colors[i]), lessThan(dist(colors[i - 1])));
          }
          expect(colors.last.toARGB32(), certColor.toARGB32());
        });

        test('${cert.id}/$b: 全段階で文字が4.5:1以上', () {
          for (final r in [0.0, 0.2, 0.5, 0.8, 1.0]) {
            final bg = solveCoverageColor(scheme, certColor, r);
            final fg = solveCoverageForeground(scheme, bg);
            final l1 = bg.computeLuminance();
            final l2 = fg.computeLuminance();
            final contrast = (l1 > l2 ? l1 + 0.05 : l2 + 0.05) / (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
            expect(contrast, greaterThanOrEqualTo(4.5));
          }
        });
      }
    }

    test('certColorForはライト/ダークで資格のlight/darkを返す', () {
      expect(certColorFor(kAppCert, Brightness.light), kAppCert.light);
      expect(certColorFor(kAppCert, Brightness.dark), kAppCert.dark);
    });
  });

  group('computeSolveCoverage', () {
    test('分野・章ごとに解答済みを数える（正誤は問わない）', () {
      final qs = [_q('a1', 'business'), _q('a2', 'business'), _q('a3', 'business'), _q('t1', 'technology')];
      final rs = [_r('r1', 'business', ['a1', 'a2', 'zzz']), _r('r2', 'business', [])];
      final s = computeSolveCoverage(
        questions: qs,
        readings: rs,
        answered: {'a1': true, 'a2': false, 't1': true},
      );
      expect(s.bySubject['business']!.solved, 2);
      expect(s.bySubject['business']!.total, 3);
      expect(s.byReading['r1']!.label, '2/2問');
      expect(s.byReading['r2']!.label, '2/3問'); // 関連問題なし→分野全体
      expect(s.bySubject['technology']!.percent, 100);
    });

    test('問題が無ければ0%', () {
      expect(const SolveCoverage(solved: 0, total: 0).ratio, 0);
    });
  });

  group('ReadingListScreen の解いた割合', () {
    final qs = [for (var i = 0; i < 4; i++) _q('b$i', 'business')];
    final rs = [
      _r('none', 'business', ['b0', 'b1']),
      _r('half', 'business', ['b2', 'b3']),
    ];

    testWidgets('0%・途中・100%を数値で併記する', (tester) async {
      await tester.pumpWidget(_app({'b0': true, 'b1': false, 'b2': true}, qs, rs));
      await tester.pump();
      expect(find.text('2/2問（100%）'), findsOneWidget);
      expect(find.text('1/2問（50%）'), findsOneWidget);
      expect(find.text('3/4問（75%）'), findsOneWidget); // 分野見出し
      expect(
        find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == '解いた割合 2問中2問を解答済み、100%'),
        findsOneWidget,
      );
    });

    testWidgets('0%は数値0/Nで表示し、100%のカードは0%より濃い', (tester) async {
      await tester.pumpWidget(_app({'b2': true, 'b3': true}, qs, rs));
      await tester.pump();
      expect(find.text('0/2問（0%）'), findsOneWidget);
      Color cardColor(String id) =>
          tester.widget<Card>(find.byKey(ValueKey<String>('reading-card-$id'))).color!;
      final scheme = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
      expect(cardColor('none'), scheme.surface);
      expect(cardColor('half'), certColorFor(UkalabCert.itPassport, Brightness.light));
    });

    testWidgets('資格を差し替えると100%の色もその資格色になる', (tester) async {
      await tester.pumpWidget(_app({'b2': true, 'b3': true}, qs, rs, cert: UkalabCert.boki3));
      await tester.pump();
      final c = tester.widget<Card>(find.byKey(const ValueKey<String>('reading-card-half'))).color!;
      expect(c, UkalabCert.boki3.light);
    });

    testWidgets('ダークテーマでも表示できる', (tester) async {
      await tester.pumpWidget(_app({'b0': true}, qs, rs, brightness: Brightness.dark));
      await tester.pump();
      expect(find.text('1/2問（50%）'), findsOneWidget);
      final c = tester.widget<Card>(find.byKey(const ValueKey<String>('reading-card-none'))).color!;
      final scheme = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
      expect(c, isNot(scheme.surface));
      expect(c, isNot(UkalabCert.itPassport.light));
    });
  });
}
