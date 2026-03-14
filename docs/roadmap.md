# Yanikasu 進捗と今後の計画

## 概要
このドキュメントは、Todo 固定のバックエンド実装から、ユーザーが設定とコード生成を通して拡張できるフレームワークへ寄せるために行った変更と、今後の開発計画をまとめたものです。

## これまでに実施したこと
### PR #2 ユーザー定義ルーティングとスキーマ DSL の追加
- `config/routes.rb` を DSL で記述できるように変更
- `config/schema.rb` を追加し、DB スキーマをアプリ側で定義できるように変更
- `lib/` から Todo 固定の責務を外し、Router/DB を汎用化

### PR #3 サーバー起動設定の外部化
- `YANIKASU_HOST`
- `YANIKASU_PORT`
- `YANIKASU_DB_PATH`

上記の環境変数、またはメソッド引数でサーバー設定を上書きできるように変更

### PR #4 既存 SQLite スキーマとの同期
- 既存の SQLite ファイルに対して、不足しているカラムのみを自動追加する仕組みを追加
- `config/schema.rb` に列を足したあとでも、既存 DB を利用しやすく改善

### PR #5 マイグレーション実行基盤の追加
- `migrations/` 配下の未実行 migration を順番に適用する runner を追加
- `schema_migrations` テーブルで実行履歴を管理
- サーバー起動時に pending migration を自動実行

### PR #6 マイグレーション DSL の拡張
- `create_table`
- `add_column`
- `drop_table`
- `execute`

migration で上記 helper を使えるようにし、生 SQL 依存を一部削減

### PR #7 CLI の初期化と migration 生成
- `bin/yanikasu init`
- `bin/yanikasu generate migration NAME`

アプリ初期化と migration 雛形生成を CLI から実行できるように変更

### PR #8 resource generator の追加
- `bin/yanikasu generate resource posts title:string published:boolean`

上記のような形式で、schema・routes・migration をまとめて生成できるように変更

## 現在の到達点
- ルーティングはフレームワーク内部を編集せず `config/routes.rb` で定義可能
- DB スキーマは `config/schema.rb` と migration の両方で管理可能
- サーバー設定はハードコードされておらず、環境変数で変更可能
- CLI から最小限の初期化と生成作業を実行可能

## 既知の制約
- `generate resource` は `config/routes.rb` と `config/schema.rb` の文字列構造に依存して追記している
- migration は `down` や rollback をまだ持っていない
- schema と migration の責務分担がまだ粗く、型変更や削除の扱いは限定的
- controller / handler 分離は未着手で、ルート定義に処理が残りやすい

## 次にやるべきこと
### 優先度 高
- resource generator の追記処理を安全化する
  - AST ベース編集、または専用設定ファイルへの移行を検討
- migration に rollback 戦略を追加する
  - `up/down` 方式、または `change` + 制限付き reversible を検討
- handler / controller の生成導線を追加する
  - ルート定義と処理本体の責務を分ける

### 優先度 中
- migration helper を拡張する
  - `rename_column`
  - `remove_column`
  - `timestamps`
- Request / Response の HTTP 仕様対応を強化する
  - `Content-Type` の扱い
  - 不正 body の扱い
  - ヘッダ処理の厳密化

### 優先度 低
- CLI に scaffold 全体生成を追加する
  - resource 生成時に handler や serializer を合わせて作る
- README と docs をユースケース別に整理する

## 開発方針
- 変更は小さい PR に分けて積み上げる
- 既存の挙動を壊さないよう、各 PR でテストを追加する
- フレームワーク層とアプリ層の責務分離を優先する
