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
  exam/it_passport.json               ExamConfig（新制度の3分野: ビジネス・テクノロジ・セキュリティ・倫理）
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

## 試験定義（新制度・シラバス案 Ver.0.1 準拠、暫定）

- 2027年度春頃に移行する新制度（IPA）に合わせ、分野は「ビジネス」「テクノロジ」「セキュリティ・倫理」。出題数100問・試験時間120分（**現行試験の値を目安として使用。新制度の公式値は未確認**）。
- 分野別の出題数（46/27/27）と合格基準（総合60%・各分野30%）は**暫定値**。IPAの公開資料に記載がなく、中分類の数に比例させた値と、現行制度の値を使っている。正式発表で更新する。
- 分野・中分類との対応と要確認事項は [`docs/syllabus_coverage.md`](docs/syllabus_coverage.md) を参照。

## 現状（2026-10-13 時点）

- 共通部品（core v0.63.0）: 用語集・間違いノート・週間ふりかえり・推しの一言・試験日カウントダウン・試験直前モード／チェックリスト・衣装／背景プレゼントの土台を継承。
- 問題は**1074問**（ビジネス443・テクノロジ316・セキュリティ・倫理315）、用語640語、解説読み物3本。シラバス案の全中分類の用語例を網羅するように作成し、新制度で強化された領域（データマネジメント・AI利活用・AI倫理）も含む。全て自作・運営者確認前の仮データで、**公開前に運営者確認と追加が必要**（目標の約1,000問には到達。運営者確認が必要）。
- 広告は Google 公式のテスト用ID、課金は `FakeEntitlementService`（仮）。本番IDの発行・差し替えは `PRELAUNCH_CHECKLIST.md` を参照。
- アプリアイコン・Android/iOS のパッケージ ID（`com.yourwish.ukalab.it_passport`）は G検定の複製のまま。アイコン差し替えが必要。
