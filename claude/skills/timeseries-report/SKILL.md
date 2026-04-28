---
name: timeseries-report
description: 1行=1日 (もしくは時刻) のような時系列+数値中心のフラットなデータ (例 通信データ使用量, 体重・歩数の日次記録, 日次KPI, アクセス数の日次集計, 株価) を渡されてユーザーが「時系列レポートにして」と明示的に依頼されたときに、 単一HTMLファイルの時系列レポートを生成する。 期間プリセット (全期間 / 直近1年 / 直近6ヶ月 / 直近3ヶ月 / 直近1ヶ月 / 直近1週間) と自由日付指定で全グラフ・テーブルが連動。 グラフ最大2つ (line / bar / scatter) は横並び、 生データテーブルは折りたたみ。 単純な「レポートにして」での起動は `gui-report` skill が振り分け先として呼ぶ。 階層的なカテゴリと個別レコードを持つデータでは `drilldown-report` を使うこと。
---

# timeseries-report

時系列+数値中心のデータを単一HTMLにまとめる。 ドリルダウン用途ではなく「期間を絞って推移と平均を見る」用途。

## ワークフロー

1. **入力ファイルを読む**: `jq 'type'` / `head` で構造把握 (drilldown-report と同じ流儀で)
2. **日付列を決める**: `dateField` (例: `date`, `ts`, `timestamp`) を1つ選ぶ
3. **時系列粒度を決める**: 日次そのまま / 月次に丸める / 週次, など
4. **サマリ指標を抽出**: 全期間の合計・平均・最大・最小、 主要指標 4〜8 個
5. **グラフ最大2つ**:
   - 主指標の推移: `line` (滑らかに見たい) or `bar` (棒で値を比較)
   - 副指標または別軸: 月別合計の `bar`、 2変数の関係なら `scatter`、 構成比の `doughnut`
   - 「とりあえず」のグラフは載せない
6. **生データテーブル**: 1個。 列ソート / フィルタ / 列幅可変対応。 大量行なら `open: false` 推奨
7. **`assets/template.html` の `{{TITLE}}` `{{META}}` `{{CONFIG_JSON}}` を置換して出力**
   - CONFIG_JSON は `<` を `<` にエスケープしてから埋め込む (Python なら `json.dumps(cfg, ensure_ascii=False).replace('<', '\\u003c')`)
   - 出力ファイル名は **入力ファイル名から派生** (例: `povo.json` → `povo-report.html`)。 入力と同じディレクトリへ
8. **完了報告**: `file:///` と `file://wsl.localhost/Ubuntu/...` の両方を出す

## config の仕様

```json
{
  "title": "povo データ使用量",
  "meta": "2024-02-11 〜 2026-04-28 (751日)",
  "dateField": "date",
  "presets": [
    {"label": "全期間", "days": null},
    {"label": "直近1年", "days": 365},
    {"label": "直近6ヶ月", "days": 180},
    {"label": "直近3ヶ月", "days": 90},
    {"label": "直近1ヶ月", "days": 30},
    {"label": "直近1週間", "days": 7}
  ],
  "summary": [
    {"label": "総使用量", "value": "36.7 GB", "sub": "全期間", "help": "..."},
    {"label": "1日平均", "value": "0.05 GB"}
  ],
  "charts": [
    {
      "id": "daily",
      "type": "line",
      "title": "日次使用量",
      "xField": "date",
      "yField": "used",
      "yLabel": "GB",
      "data": [
        {"date": "2024-02-11", "used": 0.05},
        {"date": "2024-02-12", "used": 0.12}
      ]
    },
    {
      "id": "monthly",
      "type": "bar",
      "title": "月別合計",
      "xField": "month",
      "yField": "total",
      "data": [
        {"month": "2024-02", "total": 2.23, "date": "2024-02-15"}
      ]
    }
  ],
  "tables": [
    {
      "id": "raw",
      "title": "生データ",
      "open": false,
      "columns": [
        {"field": "date", "label": "日付", "type": "string"},
        {"field": "used", "label": "使用量GB", "type": "number"},
        {"field": "remaining", "label": "残量GB", "type": "number"}
      ],
      "rows": [
        {"date": "2024-02-11", "used": 0.05, "remaining": 0.8}
      ]
    }
  ]
}
```

### 期間フィルタの仕組み

- ヘッダの `select` でプリセット切替、 `<input type=date>` 2つで自由指定可
- 期間範囲は `dateField` の値で chart と table をフィルタ (起動時に各データの最大日を `to`、 そこから `days` 日遡って `from` を決める)
- chart の data に含まれる `xField` 値を `dateField` と同じ書式 (例 `2024-02-15` のような ISO date) で持たせること。 月別 bar の場合は `xField: "month"` (値は `"2024-02"`) でも、 別途 `date` キーに代表日 (例 月の中日) を入れておくと期間フィルタが効く ※ x がdate直接ならそれだけで OK

### `summary` を期間で再集計したい場合

現状のテンプレは `summary` を **静的** に表示する (期間切り替えで変わらない)。 「全期間の値」を入れる前提。

期間連動の動的 summary が必要なら、Claude が config 出力時に「主要な期間別の数値を `sub` 行に併記」する形で対応する (例: `value: "36.7 GB"`, `sub: "直近30日: 1.4 GB / 直近7日: 0.3 GB"`)。

### `tables` 各フィールド (drilldown-report と同等)

| フィールド | 必須 | 内容 |
|---|---|---|
| `id` | yes | DOM id |
| `title` | yes | 見出し |
| `open` | no | デフォルト開閉。 数百行超は false 推奨 |
| `columns[].field` | yes | rows のキー |
| `columns[].label` | yes | 列ヘッダ表示名 |
| `columns[].type` | no | `string` / `number` |
| `columns[].help` | no | `?` ホバー説明 |
| `columns[].render` | no | `link` / `level` / `truncate` |
| `rows` | yes | 全期間の行データ。 期間フィルタはJSが適用 |

各行に `dateField` の値が入っていれば期間フィルタが効く。

### `charts` 各フィールド

| フィールド | 必須 | 内容 |
|---|---|---|
| `id` | yes | チャートID |
| `type` | no | `line` / `bar` / `scatter` / `pie` / `doughnut`。 デフォルト `line` |
| `title` | yes | 見出し |
| `xField` | no | x軸の値を取る key (デフォルト `x`) |
| `yField` | no | y軸の値を取る key (デフォルト `y`) |
| `xLabel` / `yLabel` | no | 軸タイトル (主に scatter) |
| `data` | yes | `[{xField値, yField値, ...}, ...]`。 scatter は `[{x, y, ...任意属性}, ...]` |
| `dateKey` | no | 期間フィルタの日付列名。scatter のように x/y が数値で日付ではない場合、各点に `date` のような日付属性を付けて `dateKey: "date"` を指定する。省略時 line/bar は `xField`、scatter は全体の `dateField` を使う |
| `datasets` | no | 多系列にしたい場合の配列 (各 `{label, field}` または `{label, data}`) |
| `beginAtZero` | no | y軸ゼロ起点。 デフォルト true。 株価のように差分中心の場合は false |

## 粒度の選び方

- **日次データ** (1行=1日): `line` で日次推移 + `bar` で月別合計。 動きと総量を両方掴める
- **5分粒度** (高頻度時系列): `bar` で時間帯別、 `line` で日次集計など、 集計してから出す方が見やすい
- **複数指標** (体重・歩数・睡眠): 別々のグラフ2つ or `datasets` で多系列1グラフ

## 完了報告

```
~/.claude/skills/timeseries-report/assets/template.html を元に <出力ファイル名> を生成した。

期間: <最古> 〜 <最新> (<日数>日)
グラフ: <タイトル1> / <タイトル2>
テーブル: <件数>行

ファイルパス:
- file:///<絶対パス>
- file://wsl.localhost/Ubuntu/<絶対パス>
```

## 設計の背景

- **drilldown-report と分けた理由**: drilldown-report は「複数の集計粒度を辿る」 体験が主。 単純な日次時系列データではクロスフィルタの意味が薄く、 むしろ「期間を絞って推移を見る」UIのほうが本質的に役立つ
- **期間プリセット**: ユーザーが「直近1ヶ月」「6ヶ月」のような典型期間を1クリックで切替できると探索効率が上がる
- **テンプレ流用**: drilldown-report と CSS / テーブル機能 (sort, filter, resize) は同じ。 違いは「単一テーブル + cross-filter なし + 期間フィルタ」のみ
