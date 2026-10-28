import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:ukalab_core/ukalab_core.dart';

/// 「会社のIT担当1年目」(ストーリー型の体験。ukalab_boki の会社経営モード・
/// ukalab_g_kentei のAIプロジェクト経営モードと同じ構造)のデータ。

/// 画面に出す、AI下書きであることの表示。`contentStatus` が `ai-draft` のシナリオにだけ出す。
/// 現在の10本は体験コンテンツのため専門家確認は不要と判断し、印を外した(2026-10-28)。
const String kItStaffStoryDraftNotice = '学習用の架空シナリオ(AI下書き・専門確認前)';

/// データに付ける AI 下書きの印(`contentStatus`)。印がない(キーなし)のが通常の状態。
const String kItStaffContentStatusAiDraft = 'ai-draft';

/// 無料で遊べるシナリオ(最初の2本)。残りはプレミアム限定。
const Set<String> freeItStaffScenarioIds = {
  'it_staff_story-0001',
  'it_staff_story-0002',
};

const String kItStaffStoryAsset = 'assets/experience/it_staff_story_it_passport.jsonl';

/// 学習コンテンツに使わない表現。
const List<String> kItStaffForbiddenWords = ['公式', '本試験相当', '過去問', '合格保証'];

/// コア側の [StoryScenario] に、アプリ側の追加項目(AI下書きの印・関連用語)を足したもの。
class ItStaffScenario {
  const ItStaffScenario({
    required this.story,
    required this.contentStatus,
    required this.termIds,
  });

  final StoryScenario story;

  /// 'ai-draft' など。印がなければ空文字。
  final String contentStatus;

  /// 既存の用語集の termId。画面の「関連用語」から用語カードを開く。
  final List<String> termIds;

  String get scenarioId => story.scenarioId;
  bool get isFree => freeItStaffScenarioIds.contains(scenarioId);
  bool get isAiDraft => contentStatus == kItStaffContentStatusAiDraft;
}

class ParsedItStaffScenarios {
  const ParsedItStaffScenarios(this.scenarios, this.issues);

  final List<ItStaffScenario> scenarios;
  final List<ContentIssue> issues;
}

ParsedItStaffScenarios parseItStaffScenarios(String text) {
  final base = parseStoryScenariosJsonl(text);
  final issues = [...base.issues];
  final extras = <String, Map<String, dynamic>>{};
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('//')) continue;
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map<String, dynamic> && decoded['scenarioId'] is String) {
        extras[decoded['scenarioId'] as String] = decoded;
      }
    } on FormatException {
      // 構文の問題は parseStoryScenariosJsonl 側で報告済み。
    }
  }
  final scenarios = <ItStaffScenario>[];
  for (final s in base.scenarios) {
    final j = extras[s.scenarioId] ?? const <String, dynamic>{};
    final ids = j['termIds'];
    scenarios.add(ItStaffScenario(
      story: s,
      contentStatus: j['contentStatus'] is String ? j['contentStatus'] as String : '',
      termIds: ids is List ? [for (final e in ids) if (e is String) e] : const [],
    ));
  }
  return ParsedItStaffScenarios(scenarios, issues);
}

/// 配信前の品質ゲート。コアの検査に加えて、AI下書きの印の値・出典・禁止表現・関連用語の参照先を確かめる。
List<ContentIssue> validateItStaffScenarios(
  List<ItStaffScenario> items, {
  required ExamConfig exam,
  required Iterable<String> termIds,
}) {
  final issues = <ContentIssue>[
    ...validateStoryScenarios([for (final i in items) i.story], exam: exam),
  ];
  final known = termIds.toSet();
  for (final item in items) {
    final s = item.story;
    void add(String code, String message) => issues.add(ContentIssue(s.scenarioId, code, message));
    // 印(contentStatus)は任意。付けるなら既知の値(ai-draft)だけにして、表記ゆれを防ぐ。
    if (item.contentStatus.isNotEmpty && !item.isAiDraft) {
      add('unknown-content-status', 'contentStatus は ai-draft 以外を使いません: ${item.contentStatus}');
    }
    // 由来は残すが、確認していないものを「専門家確認済み」と書かない。
    if (s.sourceRef.contains('専門家確認済み')) {
      add('false-confirmed', 'sourceRef に「専門家確認済み」と書かないでください(確認はしていません)');
    }
    if (s.source != QuestionSource.original) add('not-original', 'source は original(自作)である必要があります');
    if (!s.sourceRef.contains('自作')) add('no-self-made', 'sourceRef に自作である旨がありません');
    if (item.termIds.isEmpty) add('no-terms', '関連用語(termIds)がありません');
    for (final id in item.termIds) {
      if (!known.contains(id)) add('unknown-term', '用語集にない termId: $id');
    }
    final all = jsonEncode(s.toJson());
    for (final w in kItStaffForbiddenWords) {
      if (all.contains(w)) add('forbidden-word', '使わない表現が含まれています: $w');
    }
  }
  return issues;
}

Future<List<ItStaffScenario>> loadItStaffScenarios() async {
  final text = await rootBundle.loadString(kItStaffStoryAsset);
  final parsed = parseItStaffScenarios(text);
  if (parsed.issues.isNotEmpty) {
    throw StateError('IT担当1年目のデータに不備があります: ${parsed.issues.first}');
  }
  return parsed.scenarios.where((s) => !s.story.disabled).toList();
}
