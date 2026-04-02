---
name: "assign-projects"
description: "GitHub ProjectsへPullRequest/Issueを紐づける"
allowed-tools:
  - "Bash(gh pr view*)"
  - "Bash(gh ap*)"
---

1. 与えられた指示を下に紐づけ対象のPR/IssueとProjectを特定し紐づけ
2. Projectの各種フィールドを更新

## 対象Issue/PullRequest

$ARGUMENTS でPullRequestのIDやIssueのIDを指定された場合は渡されたIDのItemに紐づける

指定がない場合はカレントのPullRequestに紐づける

## 対象Project

$ARGUMENTS で「このプロジェクト」のような指定がない場合、Project名の指定がない場合は`individual-project`へ紐づける

id: 2

## Fieldと設定する項目(individual-projectの場合)

$ARGUMENTS で指定があった場合は指示に従う

- Status
    - Issue
        - すでに閉じられている場合は`Done`
        - それ以外の場合は`Idea`
    - PullRequest
        - すでに閉じられている場合は`Done`
        - それ以外の場合は`Review`
- Point
    - 1
- Month
    - 基本的には現在の月の月初の日付
    - 例) 2026-03-10 -> 2026-03-01
- Iteration
    - 現在のIteration
    - Iterationの初日を指定する
    - 現在は月ごとに切ってるので月初

### 引数の解釈

$ARGUMENTSの内容

s: Status
p: Point
m: Month
i: Iteration

`p=1`の場合はPointを1で設定する

複数ある場合は`,`区切りで渡ってくる想定

もし解釈できない場合は質問を返す

## 実行コマンド

`gh-ap`というGitHubCLI拡張を使って紐づける

### issue例

```
gh ap -project-id 2 -issue 1 -field 'Month=2026-03-01' -field 'Point=1'
```

### PR例

```
gh ap -project-id 2 -pr 2 -field 'Iteration=2026-03-01' -field 'Point=1'
```

