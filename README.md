## Yanikasu　（自作バックエンドフレームワーク）
### テスト用フロントエンド　https://github.com/Hayato-Kossy/YanikasuTestReact

### 構成
- `bin/main.rb`: サーバー起動エントリーポイント
- `lib/`: HTTP サーバー、Router、Request、Response、DB の基礎実装
- `config/routes.rb`: アプリケーションルート定義
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

### テスト
```bash
ruby -Itest test/request_test.rb
ruby -Itest test/response_test.rb
ruby -Itest test/router_test.rb
ruby -Itest test/routes_test.rb
```

### 追加済みエンドポイント
- `GET /health`
- `GET /todos`
- `GET /todos/:id`
- `POST /todos`
- `PUT /todos/:id`
- `DELETE /todos/:id`
