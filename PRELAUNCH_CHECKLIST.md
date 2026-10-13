# うかラボ ITパスポート — 公開前チェックリスト

凡例: `content` データ・一次資料の裏取り / `ops` 本番環境・運用の差し替え / `legal` 商標・法務

## コンテンツ

- [ ] `content` 試験定義（分野配分46/27/27・合格基準 総合60%かつ各分野30%は暫定）をIPAの正式発表で確認・更新
- [ ] `content` 問題（1060問）の運営者確認・出典の裏取り。計算・場面型の問題を、さらに増やす。全問の運営者確認・出典の裏取り（`docs/syllabus_coverage.md` 参照）。全問の運営者確認・出典の裏取り
- [ ] `content` 用語データ（640語）の運営者確認（定義の正確性・表現）
- [ ] `content` 新シラバス案 Ver.0.1 が確定版になったら出題範囲を再確認（現在は案で、変更の可能性がある）
- [ ] `content` 解説読み物の拡充（現在3本）

## 本番環境・運用

- [ ] `ops` AdMob のアプリID・広告ユニットIDを発行して差し替え（現在はGoogle公式テスト用）
- [ ] `ops` RevenueCat のAPIキー取得（現在は `FakeEntitlementService`）。商品ID `it_passport_noads` / `it_passport_premium`
- [ ] `ops` アプリアイコンの作成（G検定の複製のまま）
- [ ] `ops` Firebase プロジェクトの作成と `firestore.rules` のデプロイ
- [ ] `ops` 価格（noads ¥480・premium ¥1,500）の最終確認

## 商標・法務

- [ ] `legal` 「ITパスポート」表記の可否をJ-PlatPatで確認し、非公式アプリである旨の表記を確認
- [ ] `legal` 公式過去問・IPAコンテンツの利用条件を確認（転載は確認前は行わない）
