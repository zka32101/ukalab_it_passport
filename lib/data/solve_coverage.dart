import 'package:flutter/material.dart';
import 'package:ukalab_core/ukalab_core.dart';

/// 「解いた割合」の濃淡の段階数（0=未着手 … 4=すべて解いた）。
const solveCoverageStages = 5;

/// 解いた問題数と全体の問題数。割合は「解答済み（正誤は問わない）」の問題数で数える。
class SolveCoverage {
  const SolveCoverage({required this.solved, required this.total});

  final int solved;
  final int total;

  /// 0.0〜1.0。問題が0件のときは0。
  double get ratio => total <= 0 ? 0.0 : (solved / total).clamp(0.0, 1.0);

  /// 表示用の割合（四捨五入、0〜100）。
  int get percent => (ratio * 100).round();

  /// 「12/40問」。
  String get label => '$solved/$total問';

  /// 読み上げ用。
  String get semanticsLabel => '$total問中$solved問を解答済み、$percent%';
}

/// 割合を濃淡の段階（0〜4）に変換する。0%は0、100%は4、途中は1〜3。
int solveCoverageStage(double ratio) {
  if (ratio.isNaN || ratio <= 0) return 0;
  if (ratio >= 1) return solveCoverageStages - 1;
  if (ratio < 0.34) return 1;
  if (ratio < 0.67) return 2;
  return 3;
}

/// 段階ごとの資格色の混ぜ具合（0%は無色、100%で資格色そのまま＝最も濃い）。
const _stageAlpha = <double>[0.0, 0.25, 0.5, 0.75, 1.0];

/// 段階に応じた背景色。[ColorScheme.surface] に [certColor]（資格色）を重ねて導出する（ライト/ダーク共通）。
/// [certColor] は `certColorFor(cert, brightness)` で取得する。
Color solveCoverageColor(ColorScheme scheme, Color certColor, double ratio) {
  final alpha = _stageAlpha[solveCoverageStage(ratio)];
  return Color.alphaBlend(certColor.withValues(alpha: alpha), scheme.surface);
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// [background] の上で読みやすい文字色。テーマの onSurface / surface で 4.5:1 を満たせばそれを使い、
/// 満たせない中間の濃さでは黒か白のうちコントラストが高い方にする。
Color solveCoverageForeground(ColorScheme scheme, Color background) {
  for (final c in [scheme.onSurface, scheme.surface]) {
    if (_contrast(c, background) >= 4.5) return c;
  }
  return _contrast(Colors.black, background) >= _contrast(Colors.white, background)
      ? Colors.black
      : Colors.white;
}

/// 分野（subjectId）ごと・読み物の章ごとの解いた割合。
class SolveCoverageSummary {
  const SolveCoverageSummary({required this.bySubject, required this.byReading});

  final Map<String, SolveCoverage> bySubject;
  final Map<String, SolveCoverage> byReading;
}

/// 問題と読み物の一覧から、解いた割合を1回の走査でまとめて集計する。
///
/// 分母は [questions] のうち無効でないもの。章は [ChapterReading.relatedQuestionIds]
/// （プールにある qid のみ）を分母にし、関連問題が無い章は分野全体の割合を使う。
SolveCoverageSummary computeSolveCoverage({
  required List<Question> questions,
  required List<ChapterReading> readings,
  required Map<String, bool> answered,
}) {
  final subjectTotal = <String, int>{};
  final subjectSolved = <String, int>{};
  final isSolved = <String, bool>{};
  for (final q in questions) {
    if (q.disabled) continue;
    subjectTotal[q.subjectId] = (subjectTotal[q.subjectId] ?? 0) + 1;
    final done = answered.containsKey(q.qid);
    isSolved[q.qid] = done;
    if (done) subjectSolved[q.subjectId] = (subjectSolved[q.subjectId] ?? 0) + 1;
  }
  final bySubject = {
    for (final e in subjectTotal.entries)
      e.key: SolveCoverage(solved: subjectSolved[e.key] ?? 0, total: e.value),
  };
  final byReading = <String, SolveCoverage>{};
  for (final r in readings) {
    final ids = {for (final id in r.relatedQuestionIds) if (isSolved.containsKey(id)) id};
    if (ids.isEmpty) {
      byReading[r.readingId] =
          bySubject[r.subjectId] ?? const SolveCoverage(solved: 0, total: 0);
    } else {
      byReading[r.readingId] = SolveCoverage(
        solved: ids.where((id) => isSolved[id] == true).length,
        total: ids.length,
      );
    }
  }
  return SolveCoverageSummary(bySubject: bySubject, byReading: byReading);
}
