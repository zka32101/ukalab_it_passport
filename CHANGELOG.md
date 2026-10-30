# Changelog

## [Unreleased]

- ukalab_core を v0.86.0 から v0.87.0 に更新（読み物の表現拡張・RelatedReadingsCard などの追加。後方互換で、このアプリのコード変更なし）。
- 体験コンテンツ（解説読み物10章・「IT担当1年目」物語10本）から「AI下書き」の印を外した（2026-10-28）。体験コンテンツは専門家確認不要と運営者が判断したため。**専門家確認は行っていない**ので「専門家確認済み」とは書かず、`sourceRef` に「AI下書き由来（体験コンテンツ、専門家確認は不要と判断）」と由来を残した。読み物は `sourceRef` の `ai-draft` を除き `contentVer` 2026.10.18、物語は `contentStatus: ai-draft` を削除し `contentVer` 2。本文は変更なし。物語の品質ゲートは「ai-draft であること」の必須を外し、未知の `contentStatus` と「専門家確認済み」の誤記を検出するようにした。画面の「AI下書き」注記は `ai-draft` のシナリオがあるときだけ出る（現在は非表示）。問題データ（確認済み409問）は対象外。
- 専門家の確認OKを受け、問題409問から `ai-draft` タグを外し、`sourceRef` を「AI下書き・専門家確認済み」に更新（`contentVer` 2026.10.17）。問題文・選択肢・正誤・解説は変更なし。読み物・IT担当シナリオの AI 下書き表示は対象外。
- 分野ごとの解説読み物の一覧に、解いた問題の割合を色の濃淡と「12/40問（30%）」の数値で表示。
- ukalab_core を v0.82.2 に更新(資格専用キャラの画像が表示される)。
### Changed
- ukalab_core を v0.82.1、app_common_kit を v4.0.0 に更新。kit v4.0.0 で学習向け部品（QuestionCard・AnswerFeedback など）が core の `learning.dart` に移ったため、使うファイルに `import 'package:ukalab_core/learning.dart';` を追加（名前・挙動は同じ）。
- ホームの推しカードに `onLockedTap` を渡し、ロック中の資格専用キャラ（サーキ）のプレビューの「プレミアムを見る」から、選択画面を閉じて設定画面を開き、購入欄までスクロールするようにした。
- ukalab_core を v0.81.0 に更新し、資格専用キャラ（サーキ）の配線を追加。appId `it_passport` とプレミアム状態を core に渡す（プレミアム購入者のみ選択可、無料はロック表示）。メダル共有は `effectiveCharacterPackProvider` を使う。画像は別PRで core に取り込み予定で、無い間は標準キャラ表示。
- ukalab_core を v0.79.1 に更新（app_common_kit は v3.12.0 のまま。share_plus は 12.x で core の要求範囲内）。
- 設定の「学習履歴をコピー（CSV）」を「学習履歴をダウンロード（CSV）」に変更。クリップボードではなく、core の `shareCsv` で UTF-8 BOM 付きの `ukalab_history_YYYYMMDD.csv` として保存（Web はダウンロード、他は共有シート）。個人情報の列は含まない。
- ukalab_core を v0.76.0 に更新。間違いノート・読み物の関連問題など一覧系の問題文表示を `q.displayPrompt` に変更（cloze の `{{n}}` や reverseLookup の固定文が一覧に出ない）。出題画面は変更なし。

### Added
- 設定の購入欄に、core の `PremiumBenefitsCard`（プレミアムでできること）を追加。プレミアム購入済みの人には出さない。
- 分野ごとの解説読み物を拡充（第1弾）。ビジネス5章・テクノロジ3章・セキュリティ・倫理2章を追加（各4〜6節・具体例つき）。全29章の計画は `docs/reading_expansion_plan.md`。AI下書き（`sourceRef` に `ai-draft`）で専門家レビュー前。読み物の内容検証テスト（必須項目・ID重複・用語/問題IDの実在）を追加。
- 解説読み物の一覧を分野名の見出しでグループ表示（章が増えても探しやすくする）。
- 記録画面に、問題プール全体に対する「解答済み N/M問(xx%)」「正解済み N/M問(xx%)」とプログレスバーを追加（母数0では非表示）。
- 初期実装。G検定アプリ（ukalab_g_kentei）の構成を土台に、ITパスポート用の試験定義・サンプル問題77問・用語71語・解説読み物3本を追加。
- ukalab_core v0.63.0 / app_common_kit v3.0.0 に固定。
