# rdpick

Raindrop.io からテーマ関連記事の候補を取得して整形出力する Go 製 CLI。

このツールは Raindrop API から候補を取得して Markdown/JSON/TSV で出力するだけで、テーマ関連性の最終判定は行わない。出力を Claude Code に読ませて判定させる用途を想定している。

## セットアップ

1. https://app.raindrop.io/settings/integrations を開き、Test token を発行する
2. 環境変数 `RAINDROP_TOKEN` にセットする

```sh
export RAINDROP_TOKEN=xxxxxxxx
```

## ビルド

```sh
cd src/rdpick
go build -o ../../bin/rdpick .
```

mise の shim が go を解決できない場合（`config/mise/config.toml` で指定したバージョンが未インストールなど）は、実体を直接呼ぶ。

```sh
"$(mise where go)/bin/go" build -o ../../bin/rdpick .
```

## 使い方

```
rdpick [options] <query>
```

`<query>` は位置引数（省略可。`-tag` や `-since` だけで絞り込む使い方もできる）。ただし `query` / `-tag` / `-since` が全部空の場合、および `-tag ""` のように中身が空で組み立て後の search が空文字になる場合は、コレクション全件を引いてしまわないよう usage を出して終了する。

### オプション

| オプション | 説明 | デフォルト |
| --- | --- | --- |
| `-collection int` | コレクションID（`0`=全件、`-1`=未整理） | `0` |
| `-limit int` | 最大取得件数 | `100` |
| `-format string` | 出力形式: `markdown` / `json` / `tsv` | `markdown` |
| `-sort string` | 並び順（下の表を参照） | `score` |
| `-tag value` | タグ絞り込み（複数指定可） | - |
| `-since string` | 作成日の下限 `YYYY-MM-DD` | - |
| `-nested` | ネストしたコレクションも含める | `false` |
| `-verbose` | デバッグ出力を stderr に出す | `false` |

### 例

```sh
# タグ2つ + キーワードで検索し、Markdownで出力（Claude Codeに食わせる想定）
rdpick -tag sre -tag slo "可観測性"

# 特定コレクション内、2026-01-01以降の作成分をJSONで
rdpick -collection 12345 -since 2026-01-01 -format json "kubernetes"

# タグのみで絞ってTSV出力
rdpick -tag golang -limit 20 -format tsv
```

## 並び順

`-sort` に渡せる値は Raindrop API が受け付けるものと同じ。

| 値 | 順序 |
| --- | --- |
| `score` | 関連度（検索時のみ意味を持つ）。rdpick の既定 |
| `-created` | 追加日の新しい順（Raindrop API 自体の既定） |
| `created` | 追加日の古い順 |
| `title` / `-title` | タイトル昇順 / 降順 |
| `domain` / `-domain` | ドメイン昇順 / 降順 |
| `-sort` | Raindrop アプリ上の手動並び順 |

`score` の算出方法は公開されていない（キーワードマッチとセマンティック検索の合成と思われる）。また、タグだけで絞ってテキストクエリを与えない場合は照合対象のテキストが無いため `score` が機能しない可能性がある。その場合は `-sort -created` を明示したほうが順序が予測できる。

## search クエリの組み立て

位置引数の `query` に加えて、`-tag foo` は `#foo`（タグ名に空白を含む場合は `#"foo bar"`）に、`-since 2026-01-01` は `created:>2026-01-01` に変換され、スペース区切りで連結されて Raindrop API の `search` パラメータになる。

## ページング・エラー処理

- `perpage=50` 固定で `page` を 0 から進めながら取得する
- 打ち切り条件は次のいずれか
    - 取得済み件数が `-limit` に到達（超過分は切り捨てて `-limit` 件に揃える）
    - 返却件数が `perpage` 未満（Raindrop の規約でこれが最終ページを意味する）
- Raindrop のレート制限は 120 リクエスト/分。`perpage=50` なので `-limit 6000` 程度までは1分あたりの制限内で取り切れる
- HTTP 401: トークンが無効/期限切れである旨のエラー
- HTTP 429: `Retry-After` ヘッダ（無ければ2秒、上限60秒）待って1回だけリトライ。それでも 429 ならエラー
- 待機中も含めて Ctrl-C（SIGINT）/ SIGTERM で中断できる
- その他の非200: ステータスコードとレスポンス本文の先頭部分を含むエラー
