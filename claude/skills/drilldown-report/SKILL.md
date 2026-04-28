---
name: drilldown-report
description: 階層的なカテゴリと個別レコードを持つデータ (例 ログ, GitHub annotation, 取引履歴, Issue一覧, テスト失敗ログ, Sentry 的エラートラッキング) を「ドリルダウンレポートにして」と明示的に依頼されたときに、 単一HTMLファイルのインタラクティブなドリルダウンレポートを生成する。 粒度別の集計テーブル群を summary/details で折りたためる構造、 列ソート / 部分一致フィルタ / ヘルプホバー / 列幅ドラッグ可変、 上位粒度の行クリックで全子孫テーブルにクロスフィルタが伝播、 グラフは最大2つ (bar / line / pie / doughnut / scatter) 横並びでテーブルと連動。 単一ファイル完結 (Chart.js のみ CDN)。 単純な「レポートにして」での起動は `gui-report` skill が振り分け先として呼ぶ。 時系列+数値中心のフラットなデータでは `timeseries-report` を使うこと。
---

# drilldown-report

データファイルを単一の HTML ファイルにまとめる。

- **単一ファイル完結**: データ・JS・CSS をすべて埋め込み (Chart.js のみ CDN)
- **粒度別テーブル**: 上から大きい粒度 → 小さい粒度の順に並べ、上位行クリックで下位を絞り込む (クロスフィルタ)
- **列ごとのソート/フィルタ**: 列ヘッダクリックでソート、その下の input で部分一致フィルタ
- **ヘルプホバー**: 列名や指標に `?` アイコン、hover で説明
- **時系列グラフ**: 時間軸が活きるなら Chart.js で描画、グラフのバー/点クリックで対象テーブルにフィルタ伝播

## ワークフロー

1. **入力ファイルを読む**
   - JSON: まず `jq 'type'` で型確認。素の `jq '.'` がエラーになるなら **JSON value が複数連結された stream 形式** の可能性 (例: 配列が複数並んでいる)。その場合は `jq -s '.'` で配列化してから扱う
   - JSONL/NDJSON: `jq -s` で配列化
   - 配列の配列のような入れ子なら `jq '[.[] | .[]]'` でフラット化
   - CSV/TSV: 先頭数行を `head` で確認、`csvkit` (`csvjson`) で JSON 化が便利
   - YAML: `yq` で JSON に変換
2. **データの粒度を推測する**
   - 集計可能なキー (カテゴリ列、ID列、時系列列など) を洗い出す
   - 大きい粒度 → 小さい粒度の順に 2〜4 段の階層を組む
   - 個別レコード (生データ) を最下層に置く
3. **集計してテーブル行データを作る**
   - 各粒度ごとに `jq` などで集計し、行データの配列を作る
   - **クロスフィルタは「親をクリックすると、その下の全子孫テーブル」が絞られる**仕様。なので **子孫テーブルの各行には祖先テーブルすべての `rowKey` 値を持たせる**
     - 例: 4階層 (カテゴリ → リポジトリ → ワークフロー → 個別) なら、ワークフローテーブルの行は `{category, repository, workflow, ...}`、個別テーブルの行は `{category, repository, workflow, ...}` を必ず含む
     - 列に表示するかどうかは別問題 (テーブルの `columns` で省略してもよい)。ただし行データには持たせる
   - 同階層の並列テーブル (`parent: null` を複数置く) はクロスフィルタ的には独立。問題なく動く
4. **グラフを必要なら最大2つまで**
   - データに合った型を選ぶ。時系列縛りではない:
     - 時間軸での推移を見たい: `bar` / `line`
     - カテゴリ間の数量比較: `bar` (ラベルが長いなら `indexAxis: 'y'` で横棒)
     - 全体に対する割合 (合計が意味を持つ): `doughnut` (見やすい) / `pie`
     - 2つの数値変数の関係: `scatter` (散布図)。データ形式が他と違って `[{x: number, y: number, ...任意属性}, ...]` を渡す。`c.xLabel`, `c.yLabel` で軸名を付けられる
     - 何も意味がないなら **載せない**。「とりあえずグラフ」は逆に視認性を下げる
   - **最大2つ**。2つにすると CSS Grid で横並びになる
   - 各グラフは `filterTable` (絞り込み対象テーブルID) と `filterField` (テーブル側の列名) を指定すれば、 クリックで対象テーブル + その祖先テーブルすべてに絞り込みが伝播する。scatter の場合は各点に `[filterField]` 属性を持たせるとクリックフィルタが動く (例: `{x: 5.2, y: 18, date: "2026-04-28"}` で `filterField: "date"`)
5. **`assets/template.html` を読み、3 箇所のプレースホルダを置換して出力**
   - `{{TITLE}}` / `{{META}}` / `{{CONFIG_JSON}}`
   - **CONFIG_JSON のエスケープ**: JSON文字列に `</script` が含まれているとHTMLが壊れる。`json.dumps(..., ensure_ascii=False).replace("<", "\\u003c")` のように `<` を全部 `<` に置換してから埋め込む (タグ的な意味のない `<` も影響を受けないし、JSON の正当性は保たれる)
   - 出力ファイル名は **入力ファイル名から派生** (例: `annotations.json` → `annotations-report.html`)
   - 入力と同じディレクトリに出力する
6. **完成したらユーザーにファイルパスを伝える**
   - WSL なので `file:///...` と `file://wsl.localhost/Ubuntu/...` の両方を返す

## config の仕様

template.html に埋め込む JSON。Claude が生成するのはこれだけ。

```json
{
  "title": "レポートタイトル",
  "meta": "副題・データ概要・取得日時など",
  "summary": [
    {"label": "総数", "value": 220, "help": "オプション説明"},
    {"label": "failure", "value": 59}
  ],
  "tables": [
    {
      "id": "category",
      "title": "カテゴリ別",
      "description": "オプションの短い説明 (summary行に表示)",
      "open": true,
      "rowKey": "category",
      "parent": null,
      "columns": [
        {"field": "category", "label": "カテゴリ", "type": "string", "help": "メッセージから推定"},
        {"field": "total", "label": "合計", "type": "number"},
        {"field": "failure", "label": "failure", "type": "number"},
        {"field": "warning", "label": "warning", "type": "number"}
      ],
      "rows": [
        {"category": "node20-deprecation", "total": 98, "failure": 0, "warning": 98},
        {"category": "process-failed",     "total": 25, "failure": 25, "warning": 0}
      ]
    },
    {
      "id": "repository",
      "title": "リポジトリ別",
      "open": true,
      "rowKey": "repository",
      "parent": "category",
      "columns": [
        {"field": "category",   "label": "カテゴリ",     "type": "string"},
        {"field": "repository", "label": "リポジトリ",   "type": "string"},
        {"field": "total",      "label": "件数",         "type": "number"}
      ],
      "rows": [
        {"category": "node20-deprecation", "repository": "swfz/foo", "total": 5},
        {"category": "process-failed",     "repository": "swfz/bar", "total": 3}
      ]
    }
  ],
  "charts": [
    {
      "id": "daily",
      "type": "bar",
      "title": "日付別件数",
      "description": "クリックで個別テーブルを絞り込み",
      "filterTable": "individual",
      "filterField": "date",
      "data": [
        {"x": "2026-04-27", "y": 22},
        {"x": "2026-04-28", "y": 41}
      ]
    }
  ]
}
```

### tables 各フィールド

| フィールド | 必須 | 内容 |
|---|---|---|
| `id` | yes | テーブル識別子 (DOM id, 親子参照に使う) |
| `title` | yes | 見出し |
| `description` | no | summary 行に表示する短い説明 |
| `open` | no | デフォルト開閉状態。デフォルト true。下位の重い表は false 推奨 |
| `rowKey` | yes\* | 子テーブルへフィルタを流すときの行キーになる列名。子から参照されないテーブルでは省略可 |
| `parent` | no | 直接の親テーブル ID。null/未指定なら最上位。クロスフィルタ伝播の階層を構成する |
| `columns[].field` | yes | rows の キー名 |
| `columns[].label` | yes | 列ヘッダ表示名 |
| `columns[].type` | no | `string`/`number`。number は右寄せ・数値ソート |
| `columns[].help` | no | `?` アイコンに表示する説明 |
| `columns[].sortable` | no | デフォルト true |
| `columns[].filterable` | no | デフォルト true |
| `columns[].render` | no | `link` (urlに飛ぶ) / `level` (failure/warning/success に色付け) / `truncate` (長文を省略表示, hover展開) |
| `columns[].linkField` | no | render が link のとき URL を取る列名 (デフォルト `url`) |
| `rows` | yes | 行データの配列 |

### charts 各フィールド

| フィールド | 必須 | 内容 |
|---|---|---|
| `id` | yes | チャート識別子 |
| `type` | no | `bar`/`line`。デフォルト `bar` |
| `title` | yes | 見出し |
| `description` | no | summary 行の補足 |
| `filterTable` | no | クリック時にフィルタを掛ける対象テーブルID |
| `filterField` | no | テーブル側の列名 (この値が x にマッチする行のみ表示) |
| `data` | yes | `[{x, y}, ...]` の配列。x の順序で表示される |

## 粒度設計の指針

データの形にもよるが、典型的には次のような階層が有効:

- **何が** (カテゴリ/エラー種別/タグ) → **どこで** (リポジトリ/サービス/エンドポイント) → **いつ** (日付) → **個別レコード**
- **誰が** (ユーザー/組織) → **何を** (アクション) → **個別ログ**
- **状態** (success/warning/failure) → **対象** → **個別レコード**

迷ったら次の順で組む:

1. レコードを最も意味ある軸で 5〜30 件くらいにグルーピング → 一番上の表
2. 1 を更に分解する軸 (主要属性) → 2 番目の表
3. 必要に応じて 3 番目
4. 最下層に **生データのテーブル** を置く (詳細を直接見られるように)

最下層の生データテーブルは、URL があれば `render: "link"` で外部リンク化、長文メッセージは `render: "truncate"` を使う。

## 出力ファイル名

入力ファイル名から拡張子を取り、`-report.html` を付けて入力と同じディレクトリに出力する。

| 入力 | 出力 |
|---|---|
| `/path/annotations.json` | `/path/annotations-report.html` |
| `data.csv` | `data-report.html` |
| `events.jsonl` | `events-report.html` |

ユーザーが明示的に出力先を指定したらそれに従う。

## 出力前のチェック

- `summary` と `tables` の件数が一致しているか (合計値が summary と sum(rows) でずれない)
- 親テーブルの `rowKey` 値と、子孫テーブル各行の同名キー値が実データで一致するか (型違い・スペースに注意。文字列比較で合うように揃える)
- 大量データ (5000 行超) の場合、最下層の生データテーブルは `open: false` で初期は閉じておく
- 数値列は `type: "number"` を付け忘れない (ソートが文字列ソートになると誤解を招く)

## 完了報告のフォーマット

```
~/.claude/skills/html-report/assets/template.html を元に <出力ファイル名> を生成した。

主なテーブル構成:
- <親テーブル>: <件数>
- <子テーブル>: <件数>
...

ファイルパス:
- file:///<絶対パス>
- file://wsl.localhost/Ubuntu/<絶対パス>
```

## なぜこの設計なのか (背景)

- **ペラ1の HTML** にこだわる: メールやチャットに添付してダブルクリックで開ける、外部サーバ不要、後から再生成不要、というシンプルさが最大の価値。だからデータも JS も CSS も1ファイルに埋め込む。Chart.js だけは CDN にしているのは、自前バンドルすると数百KB増えて編集も面倒なため。オフラインで開く可能性が高い場合はユーザーに聞いて self-hosted に切り替えてもよい。
- **クロスフィルタを「親 `rowKey` 値で子孫テーブルを絞る」だけ** にしているのは、複数粒度の組み合わせフィルタを許すと UI と JS が一気に複雑化するため。粒度ツリーを設計時に明示する制約のおかげで、ユーザーは "上から下へ掘る" 直感的な操作だけで済む。子孫テーブル各行に祖先 rowKey 値を持たせることで、 単純な等価フィルタだけでカスケードが成立する。
- **集計を Claude が事前に行う** 設計にしている (動的集計ではない) のは、テンプレートを薄く保つため、そして集計ロジックがデータごとに千差万別だから。jq や pandas で柔軟に集計し、結果だけ rows に入れる。
- **`render` プロパティ** は "URL があるなら飛ばしたい" "長文は省略して hover で展開したい" "level は色付け" のような頻出要件をテンプレ側で受け持つもの。これ以外の特殊表示が必要になったら、その時点で `render` の種類を増やす。
