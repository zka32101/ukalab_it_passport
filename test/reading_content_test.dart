import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';
import 'package:ukalab_it_passport/data/exam_repository.dart';
import 'package:ukalab_it_passport/screens/reading_screen.dart';

/// 解説読み物（assets/experience）の内容検証。
///
/// 第1弾の拡充（docs/reading_expansion_plan.md）以降、章が増えても
/// 必須項目・ID重複・関連ID（用語・問題）の実在・AI下書き由来の表記（ai-draft の印は外し済み）が崩れないことを確かめる。

/// 拡充前から在る分野ごとの概要（もともとAI下書きの印は付けていない）。
const _overviewIds = {'reading-business', 'reading-technology', 'reading-security_ethics'};

/// 読み物の本文に入れてはいけない表現（保証・断定・権威づけ）。
const _bannedPhrases = ['公式', '本試験', '合格を保証', '必ず出', '確実に出', '絶対に出', '出題される'];

late ExamData _data;

List<ChapterReading> get _chapters =>
    _data.chapterReadings.where((r) => !_overviewIds.contains(r.readingId)).toList();

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // loadExamData は不備があれば StateError を投げる（validateChapterReadings を含む）。
    _data = await loadExamData();
  });

  test('JSONL: 1行ずつ読めて、構文・必須項目の問題がない', () {
    final text = File('assets/experience/reading_it_passport.jsonl').readAsStringSync();
    final parsed = parseChapterReadingsJsonl(text);
    expect(parsed.issues, isEmpty);
    expect(parsed.items.length, _data.chapterReadings.length);
    // 生のJSONにも必須キーがある（読み込み側の既定値に頼らない）。
    for (final line in const LineSplitter().convert(text)) {
      if (line.trim().isEmpty || line.startsWith('//')) continue;
      final j = jsonDecode(line) as Map<String, dynamic>;
      for (final k in const [
        'readingId',
        'examId',
        'subjectId',
        'title',
        'sections',
        'relatedTermIds',
        'relatedQuestionIds',
        'source',
        'sourceRef',
        'contentVer',
      ]) {
        expect(j.containsKey(k), isTrue, reason: '${j['readingId']} に $k がありません');
      }
    }
  });

  test('readingId・title が重複しない', () {
    final ids = _data.chapterReadings.map((r) => r.readingId).toList();
    expect(ids.toSet().length, ids.length);
    final titles = _data.chapterReadings.map((r) => r.title).toList();
    expect(titles.toSet().length, titles.length);
  });

  test('拡充した章が分野ごとに複数ある', () {
    expect(_chapters.length, greaterThanOrEqualTo(10));
    final bySubject = <String, int>{};
    for (final r in _chapters) {
      bySubject[r.subjectId] = (bySubject[r.subjectId] ?? 0) + 1;
    }
    for (final s in _data.exam.subjects) {
      expect(bySubject[s.subjectId] ?? 0, greaterThanOrEqualTo(2), reason: '${s.name} の章が少なすぎます');
    }
  });

  test('拡充した章は 4〜6節で、各節に見出しと本文がある', () {
    for (final r in _chapters) {
      expect(r.sections.length, inInclusiveRange(4, 6), reason: r.readingId);
      for (final s in r.sections) {
        expect(s.heading.trim(), isNotEmpty, reason: r.readingId);
        expect(s.body.trim().length, greaterThan(60), reason: '${r.readingId} / ${s.heading}');
      }
    }
  });

  test('すべて source=original。拡充した章はAI下書きの印（sourceRef の ai-draft）を外し、由来だけ残している', () {
    for (final r in _data.chapterReadings) {
      expect(r.source, QuestionSource.original, reason: r.readingId);
    }
    for (final r in _chapters) {
      // 体験コンテンツのため専門家確認は不要と判断し、印を外した。確認はしていないので「確認済み」とは書かない。
      expect(r.sourceRef, isNot(contains('ai-draft')), reason: r.readingId);
      expect(r.sourceRef, contains('AI下書き由来'), reason: r.readingId);
      expect(r.sourceRef, isNot(contains('専門家確認済み')), reason: r.readingId);
    }
  });

  test('relatedTermIds は実在する用語だけ（重複なし）', () {
    final termIds = _data.terms.map((t) => t.termId).toSet();
    for (final r in _data.chapterReadings) {
      expect(r.relatedTermIds.toSet().length, r.relatedTermIds.length, reason: '${r.readingId} の用語が重複');
      for (final id in r.relatedTermIds) {
        expect(termIds.contains(id), isTrue, reason: '${r.readingId}: 未定義の用語 $id');
      }
    }
    for (final r in _chapters) {
      expect(r.relatedTermIds, isNotEmpty, reason: r.readingId);
    }
  });

  test('relatedQuestionIds は実在し、無効化されていない問題だけ（重複なし）', () {
    final all = _data.questions.map((q) => q.qid).toSet();
    final active = _data.activeQuestions.map((q) => q.qid).toSet();
    for (final r in _data.chapterReadings) {
      expect(r.relatedQuestionIds.toSet().length, r.relatedQuestionIds.length, reason: '${r.readingId} の問題が重複');
      for (final id in r.relatedQuestionIds) {
        expect(all.contains(id), isTrue, reason: '${r.readingId}: 未定義の問題 $id');
        expect(active.contains(id), isTrue, reason: '${r.readingId}: 無効化された問題 $id');
      }
    }
    for (final r in _chapters) {
      expect(r.relatedQuestionIds, isNotEmpty, reason: r.readingId);
    }
  });

  test('保証・断定・権威づけの表現を使っていない', () {
    for (final r in _data.chapterReadings) {
      final text = [r.title, r.sourceRef, for (final s in r.sections) '${s.heading}${s.body}'].join('\n');
      for (final p in _bannedPhrases) {
        expect(text.contains(p), isFalse, reason: '${r.readingId} に「$p」が含まれます');
      }
    }
  });

  group('一覧', () {
    Future<void> pump(WidgetTester t, {Map<String, String> names = const {}}) async {
      t.view.physicalSize = const Size(800, 6000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReadingListScreen(
              readings: _data.chapterReadings,
              terms: _data.terms,
              questions: _data.activeQuestions,
              termReferences: _data.termReferences,
              subjectNames: names,
            ),
          ),
        ),
      ));
      await t.pump();
    }

    testWidgets('分野名の見出しで章がグループ分けされ、全章が並ぶ', (t) async {
      final names = {for (final s in _data.exam.subjects) s.subjectId: s.name};
      await pump(t, names: names);
      for (final n in names.values) {
        expect(find.text(n), findsOneWidget);
      }
      expect(find.byType(ListTile), findsNWidgets(_data.chapterReadings.length));
    });

    testWidgets('見出しなし（既定）でも全章が並ぶ', (t) async {
      await pump(t);
      expect(find.byType(ListTile), findsNWidgets(_data.chapterReadings.length));
    });
  });
}
