# autopilot-audit 使用コマンド一覧

`<o>/<r>` はリポジトリ、`<b>` はデフォルトブランチ。

## リポジトリ情報

```bash
gh repo view <o>/<r> --json owner,name,defaultBranchRef,visibility,isArchived \
  --jq '{owner: .owner.login, default: .defaultBranchRef.name, visibility, isArchived}'
```

## Security / CI 設定

```bash
# ブランチ保護と required checks(HTTP 404 "Branch not protected" なら保護なし → ruleset も確認)
gh api repos/<o>/<r>/branches/<b>/protection --jq '.required_status_checks.contexts' 2>&1
# ruleset(protection の代わりに使っている場合)
gh api repos/<o>/<r>/rules/branches/<b> --jq '[.[] | .type]'
# secret scanning / push protection
gh api repos/<o>/<r> --jq '.security_and_analysis'
# デフォルトの workflow 権限
gh api repos/<o>/<r>/actions/permissions/workflow --jq '.default_workflow_permissions'
# Dependabot alerts (High 以上, open)
gh api "repos/<o>/<r>/dependabot/alerts?state=open&severity=high,critical&per_page=100" --jq 'length'
```

## CI 履歴

```bash
# デフォルトブランチの直近 run(workflow ごとの最新を見る)
gh api "repos/<o>/<r>/actions/runs?branch=<b>&status=completed&per_page=50" \
  --jq '.workflow_runs[] | {name, conclusion, run_attempt, head_sha, created_at, updated_at, run_started_at, id}'
# 最新 run の annotations
gh api "repos/<o>/<r>/commits/<sha>/check-runs" --jq '.check_runs[] | {name, id, annotations: .output.annotations_count}'
gh api "repos/<o>/<r>/check-runs/<check_run_id>/annotations" --jq '.[] | {annotation_level, path, message}'
# PR の CI 所要時間(直近 10 run)
gh api "repos/<o>/<r>/actions/runs?event=pull_request&status=completed&per_page=10" \
  --jq '.workflow_runs[] | {name, run_started_at, updated_at}'
```

## Renovate 自動マージ実績

```bash
gh pr list -R <o>/<r> --state merged --author app/renovate --limit 20 --json number,mergedAt,mergedBy \
  --jq '.[] | {number, mergedAt, by: .mergedBy.login}'
```

## Issue / ラベル

```bash
gh label list -R <o>/<r> --limit 200 --json name --jq '.[].name'
gh issue list -R <o>/<r> --label autopilot --state open --limit 200 --json number,title,labels,body
gh issue create -R <o>/<r> --title "<title>" --body-file <file> --label autopilot,autopilot:proposed,autopilot:risk-low
gh issue edit <n> -R <o>/<r> --body-file <file>
gh issue comment <n> -R <o>/<r> --body-file <file>
gh issue close <n> -R <o>/<r> --comment "<理由>" [--reason "not planned"]
```

## ローカル精査

```bash
# Actions の SHA 固定漏れ
grep -hE '^\s*-?\s*uses:' .github/workflows/*.y*ml | grep -vE '@[0-9a-f]{40}' | grep -v 'uses: \./'
# 抑制コメントの数
git ls-files | xargs grep -cE 'eslint-disable|@ts-ignore|@ts-expect-error|type: ignore|noqa' 2>/dev/null | awk -F: '{s+=$2} END {print s}'
# 秘匿情報
gitleaks detect --no-banner --redact 2>/dev/null || echo "gitleaks なし → パターン grep で代替"

# JS のみのアプリのソース行数(style.L2.typecheck の 3000 行判定。テスト・vendoring を除く)
git ls-files '*.js' '*.jsx' '*.mjs' '*.cjs' | grep -vE '\.(test|spec)\.|/components/ui/|(^|/)(dist|build|vendor|e2e)/' | xargs cat | wc -l
# テストランナーのリトライ設定
git grep -nE 'retries\s*:|retry\s*:|retryTimes|reruns' -- '*.config.*' 'pytest.ini' 'pyproject.toml' 'setup.cfg'
```
