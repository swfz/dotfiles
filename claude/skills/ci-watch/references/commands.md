# ci-watch 使用コマンド一覧

承認・許可リスト精査の参考。実際の修正(push / PR作成)はサブエージェント内で行うため、ここにはメインフローと調査で使うコマンドを挙げる。

## 検出(メインフロー / 読み取り専用)

```bash
# 同梱スクリプトで巡回検出(推奨)
python3 ~/.claude/skills/ci-watch/scripts/detect_failures.py --output /tmp/ci-failures.json
python3 ~/.claude/skills/ci-watch/scripts/detect_failures.py --repos dotfiles foo   # 特定リポのみ

# リポジトリ一覧(スクリプトを使わない場合)
gh repo list swfz --limit 500 --json name,defaultBranchRef,isArchived,isFork

# 単一リポのデフォルトブランチ最新 run をワークフロー別に確認
gh api "repos/swfz/<repo>/actions/runs?branch=<default>&per_page=100" \
  --jq '.workflow_runs[] | select(.status=="completed") | {name, conclusion, event, url: .html_url, id}'

# run 一覧(簡易確認)
gh run list -R swfz/<repo> --branch <default> --limit 20
```

## 調査(サブエージェント内)

```bash
# 失敗ジョブの特定
gh run view <run_id> -R swfz/<repo>

# 失敗ログをエラー行に絞って確認
gh run view <run_id> -R swfz/<repo> --log-failed 2>&1 | grep -iE "error|fail" | head -20
gh run view --job <job_id> -R swfz/<repo> --log-failed 2>&1 | grep -iE "error|fail" | head -20

# 既存PRの確認(重複PRを避ける)
gh pr list -R swfz/<repo> --state open
```

## ローカル取得・修正・PR(サブエージェント内)

```bash
# ローカルパス解決(優先順): ~/ghq/github.com/swfz/<repo> → ~/gh/<repo>
ghq get swfz/<repo>            # 無ければ取得
gh repo clone swfz/<repo>      # ghq が無い環境の代替

# デフォルトブランチから修正ブランチを切る
git fetch origin <default_branch>
git switch -c fix/ci-<内容> origin/<default_branch>

# 修正後(push-pr スキルの流儀に従う)
git push -u origin fix/ci-<内容>
gh pr create --fill                 # 詳細は push-pr スキル参照

# 修正PRのCI監視(待ち時間に他リポを並行処理)
gh pr checks <PR番号> -R swfz/<repo> --watch
```
