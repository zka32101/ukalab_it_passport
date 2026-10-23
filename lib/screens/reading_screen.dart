import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';
import 'package:ukalab_core/ui.dart';

import '../data/progress_store.dart';
import '../data/solve_coverage.dart';
import 'learn_screen.dart';
import '../widgets/scrollable_center.dart';

/// 章ごとの解説読み物（教科書的なまとめページ）の一覧。
class ReadingListScreen extends ConsumerWidget {
  const ReadingListScreen({
    super.key,
    required this.readings,
    required this.terms,
    required this.questions,
    required this.termReferences,
    this.subjectNames = const {},
  });

  final List<ChapterReading> readings;
  final List<Term> terms;
  final List<Question> questions;

  /// 本文中で検出してタップ可能にする用語（既存の用語集と同じ一覧）。
  final List<TermReference> termReferences;

  /// subjectId → 分野名。渡すと、一覧を分野ごとの見出しでグループ分けする（章が増えても探しやすくする）。
  /// 空なら見出しなしの1本のリストで表示する。
  final Map<String, String> subjectNames;

  Term? _termById(String termId) {
    for (final t in terms) {
      if (t.termId == termId) return t;
    }
    return null;
  }

  Question? _questionById(String qid) {
    for (final q in questions) {
      if (q.qid == qid) return q;
    }
    return null;
  }

  bool _isPremium(WidgetRef ref) => canUsePremiumFeature(
        PremiumFeature.readingReadAloud,
        isPremium: (ref.read(entitlementStateProvider).valueOrNull ?? EntitlementState.free)
            .hasPremium,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (readings.isEmpty) {
      return const ScrollableCenter(child: EmptyState(message: '解説読み物のデータがまだありません。'));
    }
    // 分野の見出し（subjectNames にある分野のみ）。章の並びは読み込み順（データ側で分野ごとに並べる）を保つ。
    final rows = <Object>[]; // MapEntry<subjectId, 分野名>（見出し）または ChapterReading
    final seenSubjects = <String>{};
    for (final r in readings) {
      final name = subjectNames[r.subjectId];
      if (name != null && seenSubjects.add(r.subjectId)) rows.add(MapEntry(r.subjectId, name));
      rows.add(r);
    }
    // 解いた割合は一覧全体で1回だけ集計する（行ごとには計算しない）。
    final answered = ref.watch(progressProvider.select((p) => p.answeredQidToCorrect));
    final coverage = computeSolveCoverage(
      questions: questions,
      readings: readings,
      answered: answered,
    );
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final row = rows[i];
        if (row is MapEntry<String, String>) {
          final sub = coverage.bySubject[row.key];
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(row.value, style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                if (sub != null && sub.total > 0)
                  Semantics(
                    label: '解いた割合 ${sub.semanticsLabel}',
                    excludeSemantics: true,
                    child: _CoverageChip(
                      key: ValueKey<String>('subject-coverage-${row.key}'),
                      coverage: sub,
                    ),
                  ),
              ],
            ),
          );
        }
        final r = row as ChapterReading;
        final cov = coverage.byReading[r.readingId];
        final scheme = Theme.of(context).colorScheme;
        final bg = cov == null ? null : solveCoverageColor(scheme, cov.ratio);
        return Card(
          key: ValueKey<String>('reading-card-${r.readingId}'),
          color: bg,
          child: ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(r.title),
            subtitle: cov == null || cov.total == 0
                ? null
                : Semantics(
                    label: '解いた割合 ${cov.semanticsLabel}',
                    excludeSemantics: true,
                    child: Text(
                      '${cov.label}（${cov.percent}%）',
                      key: ValueKey<String>('reading-coverage-${r.readingId}'),
                    ),
                  ),
            textColor: bg == null ? null : solveCoverageForeground(scheme, bg),
            iconColor: bg == null ? null : solveCoverageForeground(scheme, bg),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: Text(r.title)),
                  body: ChapterReadingWidget(
                    title: r.title,
                    sections: [
                      for (final s in r.sections)
                        ReadingSectionView(heading: s.heading, body: s.body),
                    ],
                    relatedTerms: [
                      for (final id in r.relatedTermIds)
                        if (_termById(id) != null)
                          RelatedTermRef(termId: id, label: _termById(id)!.term),
                    ],
                    relatedQuestions: [
                      for (final id in r.relatedQuestionIds)
                        if (_questionById(id) != null)
                          RelatedQuestionRef(
                            questionId: id,
                            label: _questionById(id)!.displayPrompt,
                          ),
                    ],
                    bodyTermReferences: termReferences,
                    onRelatedTermTap: (termId) {
                      final term = _termById(termId);
                      if (term == null) return;
                      showTermCard(
                        context,
                        term: term.term,
                        headline: term.headline,
                        definition: term.definition,
                        analogy: term.analogy,
                        commonMistake: term.commonMistake,
                      );
                    },
                    onRelatedQuestionTap: (qid) {
                      final question = _questionById(qid);
                      if (question == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => Scaffold(
                            appBar: AppBar(title: const Text('関連問題')),
                            body: LearnScreen(
                              questions: [question],
                              terms: terms,
                              sessionSize: 1,
                            ),
                          ),
                        ),
                      );
                    },
                    onReadAloud: !_isPremium(ref)
                        ? null
                        : () {
                            final text = r.sections.map((s) => '${s.heading}。${s.body}').join('');
                            ref.read(handsFreeSpeakerProvider).speakNow(text);
                          },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 分野見出しの横に出す「12/40問」の小さなチップ。背景は解いた割合の濃淡。
class _CoverageChip extends StatelessWidget {
  const _CoverageChip({super.key, required this.coverage});

  final SolveCoverage coverage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = solveCoverageColor(scheme, coverage.ratio);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        '${coverage.label}（${coverage.percent}%）',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: solveCoverageForeground(scheme, bg)),
      ),
    );
  }
}
