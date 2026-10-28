# 専門家レビュー対象（AI下書き・未確認）

- 対象: ai-draft 問題 271問（it_passport-1089〜1359）
- 必要な専門性: ITパスポート指導者・IT/経営の基礎に詳しい人
- 一覧: `review_ai_draft.csv`（UTF-8 BOM付き。Excel で開ける。末尾3列「判定(OK/修正/削除)」「コメント」「根拠」は空欄）
- 依頼文・確認観点・反映方法・範囲外事項: ukalab_core の `docs/expert_review_requests.md` と `docs/expert_review_session_handover.md`

## 運用ルール
- `ai-draft` タグは専門家の「OK」が出るまで外さない。広告表現（別の観点で出題 等）の根拠にも数えない。
- 判定が出た問題だけ別PRで反映（`contentVer` 更新）。「OK」のみタグを外す。「削除」は `disabled: true` か行削除。
- 記録するのは確認日（年月）と確認者区分のみ。氏名・所属・連絡先は記録しない。
- CSV の再生成: `python3 <core>/tools/export_review_csv.py <jsonl> --tag ai-draft -o docs/expert_review/review_ai_draft.csv`

## 確認済み
- 確認済み(2026-10-28): 問題データの ai-draft 409問（上記271問＋追加分）について専門家の確認OKを受け、`ai-draft` タグを外し `sourceRef` を「AI下書き・専門家確認済み」に更新（`contentVer` は 2026.10.17）。確認者区分のみ記録し、氏名等は記録しない。
- 読み物（`reading_it_passport.jsonl`）と「IT担当1年目」シナリオ（`contentStatus: ai-draft`）は問題タグではないため今回の対象外（未反映）。
