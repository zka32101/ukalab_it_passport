# 解説読み物（分野ごと）拡充計画

状態: **ai-draft（AIが下書きした読み物・専門家レビュー前）**。広告表現・「公式」「本試験相当」「合格保証」の根拠には使えない。第1弾の章は、運営者または専門家による事実確認・表現確認を終えるまで、`sourceRef` に `ai-draft` を残す。

## 背景と方針

- 拡充前の読み物は分野ごとに1件（ビジネス3節・テクノロジ2節・セキュリティ・倫理2節）だけで、分野の中身を体系的に読むには足りなかった。
- 現スキーマ（core の `ChapterReading`）のまま、**1章=1レコード、1分野に複数レコード**で増やす。スキーマ・core の変更は不要。章は `title` の先頭の章番号（例: `1-6`）と見出しで区別する。
- 章の単位は、アプリの問題データの `topicId`（中分類）。語数が多い `strategy` `organization` `sec_measure` `system` は2章に分ける。計 **29章**（既存の分野概要3件は別枠で残す）。
- 内容は自作。IPA等の資料・市販教材の文章や構成を転載・言い換えしない。事実は一般的な知識に基づく。一次資料での裏取りは未実施。
- 1章は4〜6節、各節に具体例（身近な例・数値例）を含める。「合格を保証」「出題を断定」「公式」「本試験相当」の表現は使わない（`test/reading_content_test.dart` で機械検査）。

## データ上の約束（全レコード共通）

| 項目 | 値 |
|---|---|
| `readingId` | `reading-<subjectId>-<topicId>`（2章に分ける場合は `<topicId>_<区別>`） |
| `examId` | `it_passport` |
| `subjectId` | `business` / `technology` / `security_ethics`（`assets/exam/it_passport.json` の分野） |
| `source` | `original` |
| `sourceRef` | `自作の解説（一般的な基礎知識）。ai-draft: AI下書き・専門家レビュー前・要確認` |
| `contentVer` | 第1弾は `2026.10.9` |
| `relatedTermIds` | 実在する `termId` のみ。章の対象 `topicId` の問題が `conceptId` で指す用語を中心に、本文に出てくる用語を選ぶ（用語自体は `topicId` を持たないため、`conceptId` と `relatedQuestionIds` から分野を引く） |
| `relatedQuestionIds` | 実在し、無効化されていない `qid` のみ。対象 `topicId` の問題のうち、`relatedTermIds` の用語を `conceptId` に持つものを用語ごとに1問ずつ（AI下書き問題は後回し）、最大10問 |

本アプリには読み物単位の AI 下書きフラグがない（`ChapterReading` に `tags` が無い）。問題側の `tags: ["ai-draft"]` に倣い、`sourceRef` の文字列 `ai-draft` を印とする。core 側に `tags` が入った場合は、そちらへ移す。

## 章立て一覧（全29章）

状態の「済」は第1弾で執筆した章。節数は想定（済は実績）。

### ビジネス（13章）

| 章 | readingId | タイトル | topicId | 節案 | 節数 | 関連用語の目安 | 状態 |
|---|---|---|---|---|---|---|---|
| 1-1 | `reading-business-strategy_mgmt` | 経営戦略と分析手法 | `strategy` | 経営理念と戦略／SWOT／PPM／アンゾフ・M&A・OEM／KGI・CSF・KPI／コアコンピタンス・ブルーオーシャン | 6 | 13語 | 済 |
| 1-2 | `reading-business-strategy_system` | システム戦略・企画・調達 | `strategy` | 情報システム戦略／システム化計画／RFI・RFP・提案書／調達方式（入札）／EA・UML・DFD／ERP・CRM・SCM | 5〜6 | 約20語 | 未 |
| 1-3 | `reading-business-business_model` | マーケティングとビジネスモデル | `business_model` | マーケティングとは／3C・STP／4P・SEO／RFM・BtoB/BtoC／課金モデル／BPR・RPA | 6 | 17語 | 済 |
| 1-4 | `reading-business-transformation` | DXとイノベーション | `transformation` | DXとは／イノベーションの種類／オープンイノベーション・リーンスタートアップ／アジャイル開発・スクラム／SDGs・カーボンニュートラル | 5 | 約20語 | 未 |
| 1-5 | `reading-business-ai_use` | AI活用の基本と留意点 | `ai_use` | 生成AIとは／学習の種類／プロンプト・RAG／ハルシネーション／AIの原則・ガイドライン | 5 | 16語 | 未 |
| 1-6 | `reading-business-data_analysis` | データ分析と統計の基本 | `data_analysis` | 代表値とばらつき／欠損値・外れ値／グラフの選び方／相関と因果／ABC分析／標本調査とデータ基盤 | 6 | 18語 | 済 |
| 1-7 | `reading-business-data_mgmt` | データ管理とデータガバナンス | `data_mgmt` | データとは（DIKW）／メタデータ／データ品質／データライフサイクル／データガバナンス | 4〜5 | 7語 | 未 |
| 1-8 | `reading-business-design` | デザイン思考とUX | `design` | 人間中心設計／ペルソナ・カスタマージャーニー／発想法／プロトタイプ・ユーザビリティテスト／サービスデザイン | 5 | 約15語 | 未 |
| 1-9 | `reading-business-organization_hr` | 組織・人事・働き方 | `organization` | 組織形態／CSR・PDCA・OODA／人材育成（OJT・Off-JT・リスキリング）／採用・評価（MBO）／テレワーク・ウェルビーイング／IR・IPO | 5〜6 | 約25語 | 未 |
| 1-10 | `reading-business-finance` | 財務・会計の基本 | `organization` | 3つの決算書／貸借対照表／損益計算書／損益分岐点／ROE・ROAなどの指標 | 5 | 18語 | 済 |
| 1-11 | `reading-business-project` | プロジェクトマネジメント | `project` | プロジェクトとは／ステークホルダ・体制／スコープ・WBS／ガント・アロー／クリティカルパス／ウォーターフォール | 6 | 12語 | 済 |
| 1-12 | `reading-business-service` | ITサービスマネジメント | `service` | サービスとは／SLA／インシデント・問題・変更管理／サービスデスク・SPOC／顧客満足 | 4〜5 | 11語 | 未 |
| 1-13 | `reading-business-governance` | ガバナンス・監査・コンプライアンス | `governance` | コンプライアンス／コーポレートガバナンス／内部統制・J-SOX／システム監査／BCP | 5 | 約20語 | 未 |

### テクノロジ（8章）

| 章 | readingId | タイトル | topicId | 節案 | 節数 | 関連用語の目安 | 状態 |
|---|---|---|---|---|---|---|---|
| 2-1 | `reading-technology-system` | コンピュータとシステムの構成 | `system` | 5つの役割／記憶装置／周辺機器／OS／稼働率／RAID・スケール | 6 | 17語 | 済 |
| 2-2 | `reading-technology-system_devices` | IoT・スマート機器と先端技術 | `system` | センサー・IoT／ドローン・スマートメーター／CPS・デジタルツイン／AR・VR・MR／入出力装置 | 5 | 約25語 | 未 |
| 2-3 | `reading-technology-cloud` | クラウドと仮想化 | `cloud` | オンプレミスとクラウド／SaaS・IaaS・PaaS／配備形態／仮想化／クラスタ・マルチクラウド | 5 | 10語 | 未 |
| 2-4 | `reading-technology-network` | ネットワークとインターネット | `network` | LAN/WAN・機器／IPアドレス／DNS・URL／プロトコル／メール・cookie／モバイル通信 | 6 | 25語 | 済 |
| 2-5 | `reading-technology-database` | データベースの基本 | `database` | データベースとは／主キー・外部キー／正規化／SQL／トランザクション・排他制御 | 5 | 10語 | 済 |
| 2-6 | `reading-technology-ai_tech` | AI技術のしくみ | `ai_tech` | 機械学習とディープラーニング／過学習／LLMとトークン／自然言語処理・画像認識／コンテキスト内学習 | 4〜5 | 8語 | 未 |
| 2-7 | `reading-technology-digital_service` | デジタルサービスと業務システム | `digital_service` | 業務システム（販売・購買・物流）／EDI・POS／キャッシュレス決済／電子政府（e-Gov・マイナポータル）／生産方式（JIT・リーン）／フィンテック・ブロックチェーン／オフィスツール | 6 | 約30語 | 未 |
| 2-8 | `reading-technology-media` | 情報メディアと情報デザイン | `media` | 画像・音声・動画の形式／圧縮／色（加法混色・CMYK）／デザインの原則／ユニバーサルデザイン／UI（ジェスチャー）／VR・AR・メタバース | 6 | 約30語 | 未 |

### セキュリティ・倫理（8章）

| 章 | readingId | タイトル | topicId | 節案 | 節数 | 関連用語の目安 | 状態 |
|---|---|---|---|---|---|---|---|
| 3-1 | `reading-security_ethics-sec_mgmt` | 情報セキュリティマネジメント | `sec_mgmt` | 機密性・完全性・可用性／リスクアセスメントと対応／ポリシー・情報資産／ゼロトラスト・バイデザイン／CSIRT・プライバシー | 5 | 16語 | 未 |
| 3-2 | `reading-security_ethics-threat` | 情報セキュリティの脅威 | `threat` | 脅威の分類／マルウェア／人をだます攻撃／パスワード攻撃／Web攻撃・DoS／内部不正・AI時代の脅威 | 6 | 22語 | 済 |
| 3-3 | `reading-security_ethics-sec_measure_crypto` | 暗号・電子署名・証明書 | `sec_measure` | 暗号化／共通鍵／公開鍵／ハッシュ・電子署名／証明書・認証局／TLS・PQC | 6 | 14語 | 済 |
| 3-4 | `reading-security_ethics-sec_measure_auth` | 認証と防御の技術 | `sec_measure` | 認証の3要素・多要素認証／生体認証（FAR・FRR）／パスキー・SSO／マルウェア対策（パターンマッチング・ビヘイビア）／ファイアウォール・WAF・IDS/IPS／バックアップ・脆弱性検査 | 6 | 約25語 | 未 |
| 3-5 | `reading-security_ethics-sec_law` | セキュリティ関連法規 | `sec_law` | 不正アクセス禁止法／ウイルス作成罪／特定電子メール法／サイバーセキュリティ基本法 | 4 | 4語 | 未 |
| 3-6 | `reading-security_ethics-privacy_law` | 個人情報とプライバシー | `privacy_law` | 個人情報保護法／要配慮個人情報・個人識別符号／匿名加工情報・オプトイン/アウト／マイナンバー／GDPR・忘れられる権利 | 5 | 10語 | 未 |
| 3-7 | `reading-security_ethics-biz_law` | 知的財産・契約・労働の法規 | `biz_law` | 著作権・引用／産業財産権／営業秘密／ライセンス契約／請負と準委任・偽装請負／労働関連法規・景品表示法など | 6 | 約26語 | 未 |
| 3-8 | `reading-security_ethics-ethics` | 情報倫理とAI倫理 | `ethics` | ネチケット・デジタルタトゥー／フェイクニュース・エコーチェンバー／盗用・ねつ造／ヒューマンインザループ／AIの公平性・説明責任 | 5 | 15語 | 未 |

合計: 29章（第1弾で執筆 10章、未執筆 19章）。ほかに拡充前から在る分野概要3件（`reading-business` `reading-technology` `reading-security_ethics`）は、そのまま残す。

## 第1弾（このPR）

- 執筆: 10章（1-1, 1-3, 1-6, 1-10, 1-11, 2-1, 2-4, 2-5, 3-2, 3-3）、合計 58節、約1万3千字。全体の約34%。3分野すべてに2章以上。
- 選定理由: 各分野の中でも、計算や図解で具体例を示しやすく、学習者が最初につまずきやすい章を先に書いた。
- 検査: `test/reading_content_test.dart`（必須項目、ID・title重複なし、節数、`source`、`ai-draft` の印、関連の用語ID・問題IDの実在、禁止表現）。

## 専門家レビュー前であること（要対応）

- 第1弾の10章はAIの下書きで、**専門家レビュー前**。数値例・用語の定義・法令の説明は、一般的な知識に基づくが、一次資料での照合はしていない。
- 公開前に、運営者が全章を通読し、事実誤り・誤解を招く表現・新シラバス案との範囲のずれを確認すること。確認が終わった章から `sourceRef` の `ai-draft` を外す（外す基準と担当は運営者が決める）。
- 新シラバス案の範囲かどうか要確認の用語（`docs/syllabus_coverage.md` の一覧）が、第1弾にも含まれる: PPM、標準偏差、クリティカルパス、ウォーターフォールモデル、外部キー、電子署名。
- 広告表現・ストア説明文に「解説読み物の充実」を載せる場合も、`ai-draft` が残る間は件数・品質を根拠に使わない。

## 残りの執筆作業量

- 未執筆19章 × 平均5節 ≒ 95節（1節あたり約250字、1章あたり約1,300字）。合計 約2.5万字。
- 1回の作業で6〜10章を書ける量（第1弾と同程度）なので、あと2回に分けると進めやすい。第2弾: 1-5, 1-7, 1-8, 1-12, 1-13, 2-3, 2-6, 3-1, 3-5, 3-6（語数が少ない章）。第3弾: 1-2, 1-4, 1-9, 2-2, 2-7, 2-8, 3-4, 3-7, 3-8。
- 各回で、章を足したら `test/reading_content_test.dart` の「拡充した章」の件数（下限）を上げ、このファイルの状態列を更新する。

## 表示面の確認結果

- 読み込み: `loadExamData()` は全レコードを `validateChapterReadings` にかける。レコードが増えても処理は行単位で、実行時間・メモリの問題は出ない見込み（全体約5万字）。
- 一覧: `ReadingListScreen` は `ListView.separated` で遅延構築のため、件数が増えても問題ない。章が13件を超えて長くなるので、**分野名の見出し**で区切るよう最小の変更を入れた（`subjectNames` を渡したときだけ。ホームから渡す。渡さない場合の表示は従来どおり）。
- 本文: 1章あたり1,000〜1,500字は、既存の `ChapterReadingWidget`（縦スクロール）でそのまま読める。関連用語・関連問題のリンクは最大25語・10問。
