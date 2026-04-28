---
description: commit
allowed-tools:
  - "Bash(git status*)"
  - "Bash(git log*)"
  - "Bash(git add*)"
  - "Bash(git diff*)"
  - "Bash(git commit*)"
  - "Bash(git checkout*)"
---

修正した差分の確認をし、コミットする

修正内容のフォーカスが複数ある場合は、必要な単位で分割してコミットする

コミットメッセージはConventional Commitsにならって日本語で設定

コミットメッセージにはHowではなくWhyを記載する

もしブランチがデフォルトブランチだった場合は適切な名前でブランチを切る、$ARGUMENTSの中に`main`や`master`と指定があった場合はそのままデフォルトブランチにコミットする

