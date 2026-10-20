import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';
import 'package:ukalab_core/ui.dart';

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
    final rows = <Object>[]; // String（見出し）または ChapterReading
    final seenSubjects = <String>{};
    for (final r in readings) {
      final name = subjectNames[r.subjectId];
      if (name != null && seenSubjects.add(r.subjectId)) rows.add(name);
      rows.add(r);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final row = rows[i];
        if (row is String) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Semantics(
              header: true,
              child: Text(row, style: Theme.of(context).textTheme.titleMedium),
            ),
          );
        }
        final r = row as ChapterReading;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(r.title),
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
