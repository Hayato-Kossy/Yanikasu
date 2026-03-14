## Yanikasu　（自作バックエンドフレームワーク）
### テスト用フロントエンド　https://github.com/Hayato-Kossy/YanikasuTestReact

### 構成
- `bin/main.rb`: サーバー起動エントリーポイント
- `lib/`: HTTP サーバー、Router、Request、Response、DB の基礎実装
- `config/routes.rb`: アプリケーションルート定義
- `config/schema.rb`: SQLite テーブル定義
- `test/`: Minitest による単体テスト

### セットアップ
Debian / Ubuntu 系を想定:

```bash
sudo apt-get update
sudo apt-get install -y ruby-full ruby-sqlite3 build-essential
gem install bundler
bundle install
```

### 起動
```bash
ruby bin/main.rb
```

環境変数で起動設定を上書きできます。

```bash
YANIKASU_HOST=0.0.0.0 YANIKASU_PORT=4567 YANIKASU_DB_PATH=tmp/app.sqlite3 ruby bin/main.rb
```

### テスト
```bash
ruby -Itest test/request_test.rb
ruby -Itest test/response_test.rb
ruby -Itest test/router_test.rb
ruby -Itest test/routes_test.rb
ruby -Itest test/yanikasu_test.rb
```

### 追加済みエンドポイント
- `GET /health`
- `GET /todos`
- `GET /todos/:id`
- `POST /todos`
- `PUT /todos/:id`
- `DELETE /todos/:id`

### ルーティング定義
`config/routes.rb` では DSL を使ってユーザーがルートを定義できます。

```ruby
Yanikasu.draw_routes do
  get '/health' do
    json(status: 'ok')
  end

  post '/posts' do |req|
    post = db.add('posts', req.json_body)
    json(post, http_status: '201 Created')
  end
end
```

ルートブロック内では `db`, `params`, `json`, `text`, `not_found`, `no_content` が使えます。

### スキーマ定義
`config/schema.rb` で永続化対象のコレクションを定義します。

```ruby
Yanikasu.define_schema do
  collection :posts do
    string :title
    text :body
    boolean :published
  end
end
```

既存の SQLite ファイルに対しては、起動時に不足しているカラムだけ自動追加します。既存カラムの型変更や削除はまだ扱わないため、その段階では migration 導入が必要です。
