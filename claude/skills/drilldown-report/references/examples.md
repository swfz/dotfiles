# 設計サンプル集

`SKILL.md` の補助資料。粒度設計と config の組み立て例を示す。

## 例1: GitHub Actions Annotations (本スキル開発のきっかけになったデータ)

### 入力データの形

```json
[[{"repository": "swfz/til", "workflow_name": "ci", "annotation_level": "warning", "message": "..."}], ...]
```
複数リポジトリの annotation を配列の配列で持つ JSONL ライク。

### 粒度設計

| # | テーブル | rowKey | parent |
|---|---|---|---|
| 1 | カテゴリ別 | `category` | (なし) |
| 2 | リポジトリ別 | `repository` | `category` |
| 3 | ワークフロー別 | `workflow` | `repository` |
| 4 | 個別アノテーション | (省略) | `workflow` |

カテゴリは `message` から正規表現で分類して付与する (例: `node20-deprecation`, `dependabot-error`, `cache-service-fail`)。

### 時系列グラフ

`workflow_run_started_at` を日付に丸めて件数を出す。クリックで個別アノテーションテーブルを当該日に絞る。

### Claudeがやる前処理 (jq の例)

```bash
# 全アノテーションをフラット化、カテゴリ列を追加
jq -s '[.[] | .[]] | map(. + {category: (
  if (.message | test("Node.js 20 actions are deprecated")) then "node20-deprecation"
  elif (.message | test("Dependabot encountered")) then "dependabot-error"
  ...
  else "other" end
)})' annotations.json > /tmp/flat.json

# 粒度1: カテゴリ別
jq 'group_by(.category) | map({category: .[0].category, total: length, failure: (...), warning: (...)})' /tmp/flat.json
```

## 例2: 取引履歴 (CSV)

入力: `date, account, category, amount, memo`

### 粒度設計

| # | テーブル | rowKey | parent |
|---|---|---|---|
| 1 | カテゴリ別月次 | (省略) | (なし) |
| 2 | カテゴリ別 | `category` | (なし) |
| 3 | アカウント別 | `account` | `category` |
| 4 | 個別取引 | (省略) | `account` |

### 時系列グラフ

月次合計を bar chart。クリックで個別取引を当月に絞る。

## 例3: アクセスログ (JSONL)

入力: `{"ts": "...", "path": "/...", "status": 200, "user_id": "...", "ms": 12}`

### 粒度設計

| # | テーブル | rowKey | parent |
|---|---|---|---|
| 1 | ステータスコード別 | `status` | (なし) |
| 2 | パス別 | `path` | `status` |
| 3 | ユーザー別 | `user_id` | `path` |
| 4 | 個別リクエスト | (省略) | `user_id` |

ステータスは `render: "level"` で 5xx を failure 風、4xx を warning 風に色付けする。

## 集計と「祖先キー値の埋め込み」のコツ

クロスフィルタは「親をクリックしたら、その下の **全子孫テーブル** に絞り込みが伝播する」仕様。実装は「親 `rowKey` の名前を field とした値が、子孫テーブルの行データに入っているか」を見る。

このため、**子孫テーブルの行には祖先テーブルすべての `rowKey` 値を持たせる**必要がある。

```jq
# カテゴリ別 (粒度1, root)
group_by(.category) | map({
  category: .[0].category,
  total:    length,
  failure:  (map(select(.annotation_level == "failure")) | length)
})

# リポジトリ別 (粒度2, parent=category)
# → 行に category を持たせる
group_by([.category, .repository]) | map({
  category:   .[0].category,
  repository: .[0].repository,
  total:      length
})

# ワークフロー別 (粒度3, parent=repository, ancestors=category, repository)
# → 行に category と repository 両方を持たせる
group_by([.category, .repository, .workflow_name]) | map({
  category:   .[0].category,     # 祖父キー
  repository: .[0].repository,   # 親キー
  workflow:   .[0].workflow_name,
  total:      length
})

# 個別レコード (粒度4, ancestors=category, repository, workflow)
# → 行に category, repository, workflow すべてを持たせる
[.[] | {
  category, repository, workflow: .workflow_name,
  level: .annotation_level, message, started: .workflow_run_started_at, url: .workflow_url
}]
```

「祖父のクリックで孫もフィルタ」は祖父の `rowKey` 名 (例: `category`) を孫の行データに残しておくことで実現する。

列として表示するかどうかは別問題。`columns` から省略しても、行データに値が入っていればクロスフィルタは効く。ただし「親が一目でわかる」UI 観点では、祖先の列を残しておくのが見やすい。

## render の使いどころ

- `render: "link"` — `url` 列がある最下層テーブルで使うと便利。タイトル列の表示テキストを保ちつつクリックで飛べる。
- `render: "level"` — `failure`/`warning`/`success` の文字列を色付け。
- `render: "truncate"` — 長文の `message` 列など。デフォルト 480px で切り、hover で全文展開。

## summary に何を出すか

- 全件数, 主要カテゴリの件数, 期間, 重要指標 (failure 数など)
- 4〜8 個に絞る。多すぎると視認性が落ちる
- 各 item は `help` を必要に応じて付ける
