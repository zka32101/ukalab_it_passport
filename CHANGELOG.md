# Changelog

## [Unreleased]

### Changed
- ukalab_core を v0.76.0 に更新。間違いノート・読み物の関連問題など一覧系の問題文表示を `q.displayPrompt` に変更（cloze の `{{n}}` や reverseLookup の固定文が一覧に出ない）。出題画面は変更なし。

### Added
- 記録画面に、問題プール全体に対する「解答済み N/M問(xx%)」「正解済み N/M問(xx%)」とプログレスバーを追加（母数0では非表示）。
- 初期実装。G検定アプリ（ukalab_g_kentei）の構成を土台に、ITパスポート用の試験定義・サンプル問題77問・用語71語・解説読み物3本を追加。
- ukalab_core v0.63.0 / app_common_kit v3.0.0 に固定。
