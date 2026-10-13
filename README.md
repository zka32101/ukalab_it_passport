# うかラボ ITパスポート

ITパスポート試験対策アプリ。**IPA（独立行政法人情報処理推進機構）とは無関係の非公式アプリ**です。

## 位置づけ

```
うかラボ ITパスポート（本リポジトリ） → ukalab_core（共通エンジン） / app_common_kit（共通UI・推し・コイン・課金・広告）
```

試験定義（ExamConfig）・問題データ・用語データ・解説読み物・テーマ設定・ストア設定だけを持つ薄いリポジトリです。
出題・採点・間隔反復などのロジックは `ukalab_core`、共通UIは `app_common_kit` にあり、どちらも `ref: vX.Y.Z` のタグ固定で参照します（`main` は参照しません）。
構成は先行アプリ [ukalab_g_kentei](https://github.com/zka32101/ukalab_g_kentei) を土台にしています（AI分野固有の体験画面は外しています）。

## 構成

```
assets/
  exam/it_passport.json               ExamConfig（3分野: ストラテジ系・マネジメント系・テクノロジ系）
  questions/it_passport.jsonl         問題データ（JSON Lines）
  terms/it_passport.jsonl             用語データ
  experience/reading_it_passport.jsonl 分野ごとの解説読み物
  features/checklist.jsonl            試験当日チェックリスト（会場受験）
  features/update_log.jsonl           更新ログ
lib/
  data/      assets の読み込み・進捗/履歴の端末内保存
  screens/   ホーム／学ぶ／模擬／記録／設定／用語集／間違いノート／解説読み物／最短ルート／100問ペース走
  widgets/   推し（MascotWidget・学習コイン）カード、メダル
  main.dart
```

## 開発

```bash
flutter pub get
flutter analyze
flutter test
```

コンテンツ検証（CI でも実行）:

```bash
dart run ukalab_core:validate_content assets/exam/it_passport.json --subtopic-scope=subject --terms assets/terms/it_passport.jsonl assets/questions/it_passport.jsonl
```

## 試験定義（暫定・公式要確認）

- 出題数100問・試験時間120分。出題分野はストラテジ系35問・マネジメント系20問・テクノロジ系45問。
- 合格ライン: 総合 60%（600/1,000点）かつ各分野 30%（300/1,000点）以上（`passRule: totalPct 60 / subjectMinPct 30`）。
- **IPA公式の最新の案内（出題数・配分・合格基準・シラバス版）で運営者確認が必須**。

## 現状（2026-10-13 時点）

- 共通部品（core v0.63.0）: 用語集・間違いノート・週間ふりかえり・推しの一言・試験日カウントダウン・試験直前モード／チェックリスト・衣装／背景プレゼントの土台を継承。
- 問題は**サンプル77問**（ストラテジ26・マネジメント11・テクノロジ40）、用語71語、解説読み物3本。本番の出題比率（35:20:45）に対しマネジメント系が少ないため、**公開前に大幅な追加が必要**（目標は数百問規模）。全て自作・運営者確認前の仮データ。
- 広告は Google 公式のテスト用ID、課金は `FakeEntitlementService`（仮）。本番IDの発行・差し替えは `PRELAUNCH_CHECKLIST.md` を参照。
- アプリアイコン・Android/iOS のパッケージ ID（`com.yourwish.ukalab.it_passport`）は G検定の複製のまま。アイコン差し替えが必要。
