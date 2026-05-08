---
name: deps-handler
description: RenovateボットやDependabotによるPR（依存関係更新）の対応を自動化するスキル。リリースノートの確認、CI失敗の修正、反復的なpush→CI確認のサイクルを実施する。トリガー例：「Renovateの対応をして」「renovateのPRをマージして」「依存関係の更新PRを処理して」「renovate対応」「dependabotの対応をして」「dependabotのPRをマージして」「dependabot対応」
allowed-tools:
- Bash(gh pr list:*)
- Bash(gh pr view:*)
- Bash(gh pr edit:*)
- Bash(gh pr merge:*)
- Bash(gh pr comment:*)
- Bash(gh pr close:*)
- Bash(gh pr update-branch:*)
- Bash(gh pr checks:*)
- Bash(gh run view:*)
- Bash(gh run list:*)
- Bash(git fetch:*)
- Bash(git switch:*)
---

# Renovate / Dependabot Handler

Renovateボット・DependabotによるPR対応を効率的に処理するワークフロー。

## ワークフロー

### 1. PR一覧の取得と優先順位付け

対象のbotを特定し、PR一覧を取得する:

```bash
# Renovate
gh pr list --author "renovate[bot]" --state open

# Dependabot
gh pr list --author "app/dependabot" --state open
```

ユーザーがbot種別を指定しない場合は両方確認する。

影響度で分類し、小さいものから対応する:
- **パッチ/マイナー**: バグ修正、新機能追加のみ → 低リスク
- **メジャー**: 破壊的変更あり → 高リスク、慎重に対応

### 2. 各PRの確認

CIステータスのみ並列取得する。jqで必要な項目だけ抽出する:

```bash
gh pr view <PR番号> --json title,headRefName,statusCheckRollup --jq '{title: .title, branch: .headRefName, checks: [.statusCheckRollup[] | {name: .name, conclusion: .conclusion}]}'
```

すべてのPRについてサブエージェントに変更内容の調査を委譲する（後述）。メインコンテキストにリリースノートの長文を入れないための措置。

確認すべき項目:
- CI（build, lint, test, prettier check）の状態
- サブエージェントの調査結果（破壊的変更の有無）

### 2.1. 変更内容調査（サブエージェント）

Agentツール（subagent_type: Explore）で変更内容を調査させる。パッチ/マイナー・メジャーいずれの場合も実行する。複数PRがある場合は1つのサブエージェントにまとめて調査させてよい。

**Bot別のPRボディ形式の違い:**
- **Renovate**: リリースノートがPRボディに直接埋め込まれている
- **Dependabot**: PRボディにリリースノートのサマリーが含まれるが、詳細はリンク先を参照する形式が多い。`Dependabot compatibility score`セクションも含まれる

サブエージェントへのプロンプト例:
```
以下のパッケージのアップデートについて調査してください。

<パッケージごとに以下を列挙>
- パッケージ: <パッケージ名> <旧バージョン> → <新バージョン>（<patch/minor/major>）
- PR番号: <PR番号>
- Bot: <Renovate or Dependabot>

調査項目:
1. PR bodyからリリースノートの破壊的変更（BREAKING CHANGES）を抽出
2. メジャーアップデートのみ: WebSearchで公式Changelog・Migration Guideを検索し、対応手順を確認
3. メジャーアップデートのみ: 主要な依存パッケージとの互換性（例: eslint-config-nextがESLint新バージョンに対応しているか等）

パッケージごとに以下の形式で簡潔にまとめてください:
- 破壊的変更の有無（あれば一覧を箇条書き）
- このプロジェクトに影響がありそうな項目
- メジャーのみ: 必要なマイグレーション手順
- メジャーのみ: 依存互換性の問題（あれば）
```

### 3. CI全パスの場合

サブエージェントの調査結果で破壊的変更がなければそのままマージ:

```bash
gh pr merge <PR番号>
```

### 4. CI失敗の場合

#### ブランチチェックアウトと修正サイクル

```bash
git fetch origin <ブランチ名>
git checkout <ブランチ名>
pnpm install
```

#### 失敗ログの確認

`--log-failed` の出力にはgit cleanup等の無関係な行が大量に含まれるため、grepでエラー行のみ抽出する:
```bash
gh run view --job <job_id> --log-failed 2>&1 | grep -E "Error|error|failed|FAIL" | head -10
```

#### 失敗タイプ別の対応

**prettier check失敗**: フォーマットルール変更による差分
```bash
pnpm format
git add <変更ファイル>
git commit -m "style: apply prettier vX.Y.Z formatting"
```

**eslint失敗**: プラグイン互換性問題、新ルール追加等
```bash
pnpm lint  # ローカルで再現確認
# エラー内容に応じてlockfile更新やコード修正
pnpm update <問題のパッケージ>
```

**build失敗**: API変更、型エラー等
```bash
pnpm build  # ローカルで再現確認
# リリースノートのマイグレーションガイドに従い修正
```

**test失敗**: テストコードを通すためだけの修正は行わない。本質的な対応のみ行う。

#### 修正のpushとCI確認

```bash
git push origin <ブランチ名>
# バックグラウンド（run_in_background: true）でCI監視し、待ち時間中に他のPR対応を並行して進める
gh pr checks <PR番号> --watch
```

CIが全パスするまでこのサイクルを繰り返す。

### 5. エラー調査

ローカルで再現しない場合やエラー原因が不明な場合:
- `WebSearch`で該当パッケージのGitHub Issueを検索
- `gh issue view`でIssueの詳細とworkaroundを確認
- Node.jsバージョン差異（`.node-version` vs ローカル）を確認

### 6. 完了後

mainブランチに戻る:
```bash
git checkout main
git pull
```

## 重要なルール

- テストコードを通すためだけの修正は行わない（本質的な対応のみ）
- コミットメッセージは変更内容となぜこの修正をしたかの理由を正確に反映する
- CIが全パスするまで修正→pushを反復する
- メジャーアップデートは影響範囲を慎重に確認する
- 対応の最後に、対応で用いた、承認や確認が必要なツールやコマンドのリストを列挙する
    - 許可リストの精査を行うため

## トークン削減ガイドライン

### ビルド/lintの出力を絞る

成功時のルート一覧等は不要。失敗時だけ詳細を確認する:
```bash
pnpm build > /dev/null 2>&1 || pnpm build 2>&1 | tail -10
```

### エラーを全件把握してから一括修正する

同一パターンのエラーが複数ファイルにある場合、1ファイルずつ修正→ビルド→次のエラー発見、の往復を避ける。最初に全エラーを把握する:
```bash
pnpm build 2>&1 | grep "Type error"
# 全ファイルのエラーを確認してから一度に修正
```

### Globの検索範囲を限定する

`**/*.d.ts` のような広範なパターンは `node_modules` 内のファイルが大量にヒットする。`path` を指定して検索範囲を限定する。

## 使用ツール・コマンド一覧

詳細なコマンドリストは [references/commands.md](references/commands.md) を参照。
