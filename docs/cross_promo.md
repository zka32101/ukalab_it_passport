# 相互紹介（うかラボ8アプリ）

`ukalab_core` の薄いラッパー（内部は `cross_promo_kit`）を使う。独自実装はしない。

- appId（Android）: `com.yourwish.ukalab.it_passport`
- 起動時: `lib/main.dart` で `unawaited(UkalabCrossPromo.init())`（Firebase 初期化と Remote Config 取得。失敗しても起動は止まらない）
- 画面: 設定画面の末尾に `UkalabCrossPromoSection(currentAppId: ...)`。掲載0件なら何も表示しない
- 学習・模擬試験・復習の画面には置かない。大人向けのため `isChildDirected` は既定（false）で、保護者ゲートは不要

## 掲載リスト（Remote Config 側の作業）

掲載リストの中身（各アプリのストア URL・アイコン・category「うかラボ」）は Firebase の Remote Config で配信し、コードでは変えられない。
キー名と JSON の形式は `cross_promo_kit` の README を参照すること（ここでは推測で書かない）。
入れる値の例（プレースホルダ）:

```json
[{"id":"<applicationId>","name":"<アプリ名>","tagline":"<ひとこと>","iconUrl":"<アイコンURL>","storeUrl":"<ストアURL>","category":"うかラボ"}]
```

未投入（空）のうちは、セクションは表示されない。投入先の Firebase プロジェクトは運営判断。
`google-services.json` の注入方法は README の「Firebase 設定」を参照。

## テスト

`test/cross_promo_test.dart`（掲載0件・Firebase 未初期化・設定画面の表示）。
