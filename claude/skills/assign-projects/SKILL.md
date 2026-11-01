---
name: "assign-projects"
description: "GitHub ProjectsへPullRequest/Issueを紐づけ、Status/Point/Month/Iterationのフィールドを設定する。既定の紐づけ先はindividual-project。s=/p=/m=/i= 形式の引数でフィールド値を上書きできる"
allowed-tools:
  - "Bash(gh pr view*)"
  - "Bash(gh issue view*)"
  - "Bash(gh ap*)"
---

1. 与えられた指示を元に紐づけ対象のPR/IssueとProjectを特定し紐づけ
2. Projectの各種フィールドを更新

## 対象Issue/PullRequest

$ARGUMENTS でPullRequestのIDやIssueのIDを指定された場合は渡されたIDのItemに紐づける

指定がない場合はカレントのPullRequestに紐づける

番号はカレントディレクトリのリポジトリのものとして扱う(`#123` の `#` は外す)。対象の種別(`-pr` / `-issue`)と状態は推測せず、次のコマンドで確認する

- 番号の指定なし: `gh pr view --json number,state`
- 番号の指定あり: `gh pr view <番号> --json number,state` を実行し、PRが見つからなければ `gh issue view <番号> --json number,state` で Issue と確定する
- 「見つからない」は `Could not resolve to a PullRequest`(Issueなら `Could not resolve to an issue or pull request`)を含むエラーを指す
- PRでもIssueでも見つからない場合や、認証・通信などそれ以外のエラーの場合は `gh ap` を実行せずユーザーに報告する

## 対象Project

$ARGUMENTS で「このプロジェクト」のような指定がない場合、Project名の指定がない場合は`individual-project`へ紐づける

id: 2

## Fieldと設定する項目(individual-projectの場合)

$ARGUMENTS で指定があった場合は指示に従う(指定値は state と食い違っても既定値より優先する)

既定値は次のとおり

| Field | 既定値 |
|---|---|
| Status | Issue: state が `CLOSED` なら `Done`、`OPEN` なら `Idea`<br>PullRequest: state が `CLOSED` / `MERGED` なら `Done`、`OPEN` なら `Review` |
| Point | `1` |
| Month | 今日の日付の月初(例: 2026-03-10 -> `2026-03-01`) |
| Iteration | 今日の日付の月初。Iterationは月ごとに切っているので、Iterationの初日 = 月初になる。Iterationのタイトル(`2026-03`)ではなく初日の日付を渡す |

### 引数の解釈

$ARGUMENTSの内容

構文は `[#番号] [key=value,...]`(空白区切り。`#` 付きまたは数字だけのトークンを番号とみなす)

s: Status
p: Point
m: Month
i: Iteration

`p=1`の場合はPointを1で設定する

複数ある場合は`,`区切りで渡ってくる想定

- 指定されたフィールドだけを上書きし、他は既定値のまま(`m=` を指定しても Iteration は連動させない)
- `m=` / `i=` の値は `YYYY-MM-DD` の月初の日付で `gh ap` に渡す。受け付ける表記と変換は次のとおりで、これ以外は解釈できない値として扱う
    - `YYYY-MM-DD` / `YYYY-MM`: その月の月初
    - `N月`: 今年のN月の月初
    - `今月` / `来月` / `先月` / `再来月`: 今日の月を基準に前後へずらした月の月初

もし解釈できない場合は質問を返す

- 未知のキーや解釈できない値が1つでもあれば、`gh ap` は実行しない(解釈できた部分だけの実行もしない)
- 対象の確認(`gh pr view` / `gh issue view`)は読み取りのみなので質問の前に行ってよい
- 質問では解釈できない項目を名指しし、使えるキー(s/p/m/i)の一覧、確定している対象・フィールド値、その項目を無視した場合に実行するコマンドを添える。誤記の候補を挙げるときは推測であることを明示する(妥当な候補がなければ挙げない)
- 回答を受けたら、その内容で引数を解釈し直し、すべて解釈できればそれ以上確認せず `gh ap` を実行する(「無視して」と言われた項目は除外する)

## 実行コマンド

`gh-ap`というGitHubCLI拡張を使って紐づける。対象リポジトリはカレントディレクトリのものになる

`-field` は Status / Point / Month / Iteration の4つを常にこの順で明示する(例はいずれも 2026-03-10 実行時)

### PR例(引数なし、openなPR #2)

```
gh ap -project-id 2 -pr 2 -field 'Status=Review' -field 'Point=1' -field 'Month=2026-03-01' -field 'Iteration=2026-03-01'
```

### issue例(`#1 p=3`、closedなIssue #1)

```
gh ap -project-id 2 -issue 1 -field 'Status=Done' -field 'Point=3' -field 'Month=2026-03-01' -field 'Iteration=2026-03-01'
```

## 実行結果

`gh ap` は実行後に紐づけ結果(Project・対象Item・各フィールドの値)を標準出力に表示する。
追加で確認用のコマンドは実行せず、この出力を使って次の形で報告する(コードブロック内は `gh ap` の実際の出力例。値を埋めるテンプレートではなく、実際の出力をそのまま貼る)

````
Issue #1 を individual-project に紐づけました。Status は引数 s=Done、Point は引数 p=3 で指定

```
Project: individual-project (#2) https://github.com/users/swfz/projects/2
Item: Issue #1 <タイトル> <URL>
Fields:
  Status: Done
  Point: 3
  Month: 2026-03-01
  Iteration: 2026-03 (2026-03-01)
```
````

- 1行目の Project 名はスキル内の名前(`individual-project`)を使う
- 引数で指定したキーは、既定値と同じ値でも1行目の末尾に読点区切りで添える。指定がなければ何も添えない
- `gh ap` の出力は整形せずコードブロックで囲んで貼る
