---
name: "ship"
description: "commit → push-pr → assign-projects をまとめて実行し、コミットからPR作成・Project紐づけまでを一気に行う。トリガー例：「shipして」「コミットからPR作成まで一気にやって」「PRまで出してプロジェクトに紐づけて」"
---

以下の3つのスキルをSkillツールで順番に実行する。各スキルの手順・ルールはそれぞれのSKILL.mdに従う。

1. `commit` — 差分を確認しコミットする
2. `push-pr` — remoteへpushしPull Requestを作成する
3. `assign-projects` — 作成したPRをGitHub Projectsへ紐づける

## 実行ルール

- 前のステップが失敗した場合は後続を実行せず、状況を報告して停止する
- 未コミットの差分がなく、すでにコミット済みの変更だけがある場合は `commit` をスキップして `push-pr` から始める
- 差分もコミット済みの未push変更もない場合は何もせずその旨を報告する

## 引数の受け渡し

$ARGUMENTS を解釈し、該当するスキルへそのまま引き渡す

- `main` / `master` の指定 → `commit` へ（デフォルトブランチへの直接コミット許可）
- `s=` `p=` `m=` `i=` 形式（`,`区切り） → `assign-projects` へ
- Project名やその他の指示 → 文脈から判断して該当スキルへ

解釈できない引数があった場合は実行前に質問を返す
