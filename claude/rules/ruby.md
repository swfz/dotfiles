---
name: ruby
description: swfzのRubyコーディングスタイルガイド。Rubyのコード生成・レビュー時に参照する。
paths:
  - "**/*.rb"
  - "**/Gemfile"
  - "**/Rakefile"
  - "**/*.gemspec"
  - "**/spec/**/*_spec.rb"
---

# swfz Ruby スタイルガイド

Rubyのコードを書く・レビューするときの swfz の指針をまとめたルール集。

## 共通の哲学

- **実用性重視**: 複雑なデザインパターンより動くコードを優先
- **モジュール化と単一責任**: 各クラスが単一の責務を持つ
- **テスト重視**: RSpec + SimpleCov
- **日本語を自然に使う**: テスト説明に日本語を使う
- **エラーハンドリング**: バリデーション + raise で明示的に
- **不要な抽象化を避ける**: メタプログラミングは最小限、可読性優先

---

## 設計パターン

- ファサードパターンで公開インターフェースを整理（`class << self` + `new(...).publish`）
- シングルレスポンシビリティ原則に沿ったクラス分離
- コンテキストオブジェクトパターンでメタデータ管理

## ディレクトリ構造

```
lib/
├── module_name/
│   ├── client.rb       # オーケストレーション
│   ├── api.rb          # API通信
│   ├── entry.rb        # ドメインオブジェクト
│   └── generator/      # コンテンツ生成
spec/
├── spec_helper.rb
└── module_name/
    └── *_spec.rb
exe/
└── command             # 実行可能スクリプト
```

## 命名

- メソッド: `snake_case`（動詞始まり: `upload`, `publish`, `read_context`）
- 述語メソッド: `posted_image?`, `data_file?`
- クラス: `PascalCase`
- 定数: `UPPER_SNAKE_CASE` + `.freeze`

## 文字列

- ダブルクォート主流
- ヒアドキュメント: `<<~"XML"` でインデント対応
- シンボルキーを優先（`deep_symbolize_keys`）
- 正規表現定数: `IMAGE_PATTERN = /pattern/.freeze`

## エラーハンドリング

- バリデーション + `raise` で明示的にエラー
- `RequestLogger` モジュールパターンでAPI通信ログ（`with_logging_request` + `yield`）
- 環境変数の存在チェック → `exit 1`

## テスト

- **RSpec** + **SimpleCov**（`enable_coverage :branch`）
- `config.disable_monkey_patching!` で厳密性確保
- `config.expect_with :rspec { |c| c.syntax = :expect }` で最新構文
- `describe/context/it` 構造
- `let` で値定義（遅延評価）
- `expect/change` マッチャ活用（`.from({}).to({...})`）
- テスト説明に日本語

## Gem選好

- `activesupport` - `deep_symbolize_keys` など core extensions を活用
- `oauth` - OAuth認証
- `oga` - XML解析（軽量、Nokogiriより軽い）
- `front_matter_parser` - Markdown front matter
- `sanitize` - HTML/XMLサニタイズ
- 開発: `rspec`, `pry-byebug`, `awesome_print`

## パターンと慣用句

- `OpenStruct` 継承でオプション管理
- `class << self` でクラスメソッド定義
- `attr_reader` を積極活用（attr_accessor は必要な場合のみ）
- lambda: `key_is_set = ->(key) { ... }`
- `dig()` で安全なネストアクセス
- 定数は `.freeze` で不変化
- 環境変数で機密情報管理（`ENV['TOKEN']`）
- YAML設定: `YAML.safe_load(ERB.new(File.read(config_file)).result)`

## コメント

- 日本語コメントを使用
- 意思決定や注意点のみコメント記載（コードが自明な場合は省略）

## コードレビュー時の観点

1. 各クラスが単一責任になっているか
2. 定数に `.freeze` が付いているか
3. `dig()` で安全にネストアクセスしているか
4. RSpecが `expect` 構文を使っているか（`should` ではなく）
5. `let` で遅延評価されているか
6. ダブルクォートが使われているか
