# コマンド・ツール一覧

## 承認不要（自動実行可能）

| カテゴリ | コマンド/ツール | 用途 |
|---|---|---|
| GitHub CLI | `gh pr list` | PR一覧取得 |
| GitHub CLI | `gh pr view` | PR詳細・CI状態確認 |
| GitHub CLI | `gh pr checks --watch` | CI結果の監視 |
| GitHub CLI | `gh run view --job <id> --log` | CIログ確認 |
| GitHub CLI | `gh run view --job <id> --log-failed` | CI失敗ログ確認 |
| Git | `git fetch origin <branch>` | リモートブランチ取得 |
| Git | `git checkout <branch>` | ブランチ切替 |
| Git | `git diff` / `git diff --stat` | 差分確認 |
| Git | `git status` | 状態確認 |
| パッケージ | `pnpm install` | 依存関係インストール |
| パッケージ | `pnpm list` / `pnpm why` | 依存関係調査 |
| 環境確認 | `node -v` / `cat .node-version` | Node.jsバージョン確認 |
| Claude Code | `Read` | ファイル読み取り |
| Claude Code | `Grep` / `Glob` | コード検索 |

## 承認が必要（ユーザー確認を要するもの）

| カテゴリ | コマンド/ツール | 用途 | 承認理由 |
|---|---|---|---|
| GitHub CLI | `gh pr merge <PR> --squash` | PRマージ | 共有リポジトリへの変更 |
| GitHub CLI | `gh issue view --repo <repo>` | 外部リポジトリのIssue確認 | 外部APIアクセス |
| Git | `git add <file>` | ファイルステージング | コミット準備 |
| Git | `git commit` | コミット作成 | リポジトリ履歴の変更 |
| Git | `git push origin <branch>` | リモートへプッシュ | 共有リポジトリへの変更 |
| パッケージ | `pnpm format` | prettierフォーマット適用 | ファイル変更 |
| パッケージ | `pnpm lint` | eslint実行 | 初回実行時 |
| パッケージ | `pnpm build` | ビルド実行 | 初回実行時 |
| パッケージ | `pnpm update <pkg>` | 特定パッケージ更新 | lockfile変更 |
| Claude Code | `WebSearch` | エラー原因のWeb検索 | 外部通信 |
| Claude Code | `WebFetch` | WebページのFetch | 外部通信 |
| Claude Code | `Write` / `Edit` | ファイル作成・編集 | ファイル変更 |
| シェル | `rm` / `rmdir` | ファイル・ディレクトリ削除 | 破壊的操作 |
