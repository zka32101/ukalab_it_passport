import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q(QuestionType type, String prompt,
        {List<ClozeBlank> blanks = const [], String? clue, List<String> answers = const [], List<String> choices = const []}) =>
    Question(
      qid: 'q',
      examId: 'it_passport',
      subjectId: 's',
      topicId: 't',
      type: type,
      prompt: prompt,
      explanation: '解説',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
      blanks: blanks,
      clue: clue,
      answers: answers,
      choices: choices,
      answerIndex: type == QuestionType.choice ? 0 : null,
    );

void main() {
  test('choice は従来どおり prompt を一覧に出す', () {
    final q = _q(QuestionType.choice, '選択式の問題文', choices: ['a', 'b', 'c', 'd']);
    expect(q.displayPrompt, q.prompt);
  });

  test('cloze の一覧表示に {{n}} が残らない', () {
    final q = _q(QuestionType.cloze, '{{1}}は訓練データに適合しすぎる現象である。',
        blanks: const [ClozeBlank(id: 1, answers: ['過学習'])]);
    expect(q.displayPrompt.contains('{{'), isFalse);
  });

  test('reverseLookup の一覧表示は固定文でなく clue を含む', () {
    final q = _q(QuestionType.reverseLookup, '次の説明に当てはまる用語は何か。',
        clue: '訓練データに過剰に適合し汎化性能が下がる現象',
        answers: const ['過学習'],
        choices: const ['過学習', '正則化', '汎化', '転移学習']);
    expect(q.displayPrompt.contains('訓練データに過剰に適合'), isTrue);
  });
}
