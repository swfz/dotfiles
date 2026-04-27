---
name: "push-pr"
description: "GitHubへpush, Pull Requestを作成する"
allowed-tools:
  - "Bash(git push*)"
  - "Bash(git status*)"
  - "Bash(git log*)"
  - "Bash(gh pr list*)"
  - "Bash(gh pr create*)"
  - "Bash(gh pr edit*)"
  - "Bash(ls *)"
---

1. すでにコミットされている変更をremoteへpushする
- コンフリクトしてしまう場合は
- fource pushはせず、既存の変更を取り込んでpushできるような状態にしてからpushする

2. Pull Requestを作成する
- PRテンプレートがある場合はそれに従った内容をBodyにする
- 必ず含めてほしいもの
    - PRの概要
    - why: 変更の背景、理由
    - how: 変更の手法
    - 確認観点 何をもってPR出してOKとしたのか
        - チェック項目
- すでにPRが作成されている場合は現在のコミット内容に合わせPRの内容も更新する

