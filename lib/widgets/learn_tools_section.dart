import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/exam_repository.dart';
import '../screens/it_staff_story_screen.dart';
import '../screens/mistake_note_screen.dart';
import '../screens/reading_screen.dart';
import '../screens/terms_screen.dart';

/// 「学ぶ」タブの「道具」。用語集・読み物・メモ（しおり）・間違いノートへの入口。
/// 以前はホームに平置きだったもの。見出し名は ukalab_g_kentei / ukalab_boki のホームの「道具」と同じ。
class LearnToolsSection extends ConsumerWidget {
  const LearnToolsSection({
    super.key,
    required this.exam,
    required this.questions,
    required this.terms,
    required this.chapterReadings,
  });

  final ExamConfig exam;
  final List<Question> questions;
  final List<Term> terms;
  final List<ChapterReading> chapterReadings;

  /// 一覧から開く問題の詳細。選択肢の記号は演習（A・B・C…）に合わせる。
  Widget _detailBuilder(BuildContext context, Question q) => QuestionDetailScreen(
        question: q,
        choiceLabels: const ['A', 'B', 'C', 'D', 'E', 'F'],
      );

  void _push(BuildContext context, String title, Widget body) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (context) => Scaffold(appBar: AppBar(title: Text(title)), body: body),
      ));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termReferences =
        ref.watch(examDataProvider).valueOrNull?.termReferences ?? const [];
    return HomeSection(
      title: '道具',
      subtitle: '調べる・見返す',
      leading: const Icon(Icons.handyman_outlined),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeMenuTile(
              icon: Icons.edit_note_outlined,
              title: '間違いノート',
              subtitle: '間違えた問題を見返して、解き直せます。',
              onTap: () =>
                  openMistakeNote(context, exam: exam, questions: questions, terms: terms),
            ),
            // しおり・メモ（core のカード）。
            StudyNotesHomeCards(
                loadQuestions: () async => questions, detailBuilder: _detailBuilder),
            const SizedBox(height: 4),
            HomeMenuTile(
              icon: Icons.menu_book_outlined,
              title: '用語集',
              subtitle: '収録${terms.length}語。わからない用語をいつでも調べられます。',
              onTap: () => _push(context, '用語集', TermsScreen(exam: exam, terms: terms)),
            ),
            const SizedBox(height: 8),
            HomeMenuTile(
              icon: Icons.business_center_outlined,
              title: '会社のIT担当1年目',
              subtitle: '架空の会社で月ごとに判断して学ぶ体験型教材。最初の2本は無料です。',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ItStaffStoryListScreen(terms: terms),
              )),
            ),
            if (chapterReadings.isNotEmpty) ...[
              const SizedBox(height: 8),
              HomeMenuTile(
                icon: Icons.auto_stories_outlined,
                title: '分野ごとの解説読み物',
                subtitle: 'ビジネス・テクノロジ・セキュリティ・倫理の3分野を、体系的に読めます。',
                onTap: () => _push(
                  context,
                  '分野ごとの解説読み物',
                  ReadingListScreen(
                    readings: chapterReadings,
                    terms: terms,
                    questions: questions,
                    termReferences: termReferences,
                    subjectNames: {for (final s in exam.subjects) s.subjectId: s.name},
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
