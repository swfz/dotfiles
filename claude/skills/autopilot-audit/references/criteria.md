# 判定基準

9本の柱 × L1〜L4。ID は `<柱>.<レベル>.<名前>` で固定し、Issue の `autopilot-id` とダッシュボードで共通に使う。

レベルの意味:

| レベル | 名前 | 状態 |
|---|---|---|
| L1 | 動く | 手動なら開発・検証できる |
| L2 | 文書化 | エージェントが手順を知り、CI で変更を検証できる |
| L3 | 標準化 | 壊したら自動で気づける。低リスク変更の自動マージを許可できる |
| L4 | 最適化 | フィードバックが速く、異常もエージェント自身が拾える。自動マージを広げられる |

「適用」列: 空欄 = 全種別 / それ以外は記載の種別のみ適用(それ以外の種別では `n/a`)。
`service` / `site` / `library` / `tool` の定義は SKILL.md Step 1。

## スコープ

基準は `repo`(リポジトリに1回)か `app`(SKILL.md Step 1 で列挙したアプリごと)のどちらかで判定する。
`app` スコープの基準の「適用」列は、リポジトリ全体ではなく **そのアプリの種別** で判断する。

| スコープ | 対象 |
|---|---|
| `app` | `style.*`、`build.L1.one-command`、`build.L2.*`、`testing.*`(`testing.L4.no-flaky` を除く)、`devenv.*`、`obs.*` |
| `repo` | 上記以外(`build.L3.*`、`build.L4.*`、`testing.L4.no-flaky`、`docs.*`、`security.*`、`task.*`、`ci.*`) |

アプリが1つだけ(ルートのみ)なら区別は不要。

## Style & Validation (`style`)

| ID | 基準 | 適用 | 判定方法 |
|---|---|---|---|
| `style.L1.linter` | linter の設定がある | | eslint/biome/deno lint/ruff/golangci-lint/rubocop 等の設定ファイル or package.json scripts |
| `style.L1.formatter` | formatter の設定がある | | prettier/biome/deno fmt/ruff format/gofmt 等 |
| `style.L2.typecheck` | 型チェックがある | 型のある言語 / TS / Python / JS | `tsc --noEmit`/`deno check`/mypy/pyright がスクリプトか CI にあり、対象ソースの **80% 以上(行数)が型チェックされている**。JS は TypeScript 化したものだけを数える(`checkJs` は数えない)。対象ソースからは、テスト・生成物・vendoring(shadcn の `components/ui/` 等)・設定ファイル・単発スクリプト(一度きりの移行・調査用など)を除く。shell のみは `n/a` |
| `style.L2.pre-commit` | コミット前フックがある | | lefthook/husky/pre-commit の設定 |
| `style.L3.strict` | 全ソースが strict で型チェックされている | 型のある言語 / TS / Python / JS | 対象ソース(`style.L2.typecheck` と同じ範囲)の **100%** が型チェックされ、tsconfig `strict: true` / mypy strict 等が有効 |
| `style.L3.zero-warnings` | lint 警告 0 | | lint を実行して warning/error が 0 |
| `style.L3.few-ignores` | 抑制コメントが少ない | | `eslint-disable`/`@ts-ignore`/`@ts-expect-error`/`# type: ignore`/`noqa`/`any` の合計が 1000 行あたり 1 未満 |

## Build (`build`)

| ID | 基準 | 適用 | 判定方法 |
|---|---|---|---|
| `build.L1.one-command` | テスト/ビルドが1コマンドで実行できる | | package.json scripts / deno.json tasks / Makefile / pyproject 等にある |
| `build.L2.lockfile` | lockfile がコミットされている | | pnpm-lock.yaml / deno.lock / uv.lock / go.sum / Cargo.lock 等 |
| `build.L2.runtime-pinned` | ランタイムのバージョン固定 | | 言語ランタイム本体(Node / Python / Go / Deno 等)のバージョンが mise.toml / .tool-versions / .node-version / `engines` / `.python-version` / `go.mod` の `go` 等で固定されていて、かつ CI の全ジョブがそのバージョン(またはファイル参照)を使っている。`packageManager` はパッケージマネージャの固定なので数えない |
| `build.L2.cooldown-pm` | cooldown のあるパッケージマネージャ | Node/Python | Node は pnpm、Python は uv(ユーザー CLAUDE.md の方針)。npm/yarn/pip/poetry なら fail |
| `build.L3.renovate` | 依存更新ボットが設定済み | | renovate.json(5) / .github/renovate.json / dependabot.yml |
| `build.L3.actions-sha-pinned` | Actions を SHA で固定 | workflow がある | `.github/workflows/*.yml` の `uses:` が全て 40 桁 SHA(ローカル action `./` は除外) |
| `build.L4.deps-automerge` | 依存更新が自動マージで回っている | | Renovate の automerge 設定があり、直近 30 日に bot PR が自動マージされている |

## Testing (`testing`)

| ID | 基準 | 適用 | 判定方法 |
|---|---|---|---|
| `testing.L1.exists` | テストが存在する | | テストファイルが1つ以上。CI 上でしか実行できない検証(playbook 実行後の検証ステップ等)は数えない。エージェントが手元で変更を検証できることが目的のため |
| `testing.L1.runs-locally` | テストがローカルで通る | | テストコマンドを実行して成功 |
| `testing.L2.ci-runs-tests` | 全てのテストが CI で走る | | アプリ内の全テスト(言語・ランナーごと。例: vitest + Playwright + pytest)が PR トリガーの workflow で実行されている。1つでも CI 未実行のテストがあれば fail とし、根拠に列挙する |
| `testing.L2.core-logic` | 主要ロジックにテストがある | | 分岐を持つモジュール・公開 API・エントリポイントについて対応するテストがあるか全精査。未テストの主要モジュールが 0 なら pass |
| `testing.L3.coverage-gate` | カバレッジ閾値を CI で強制 | | vitest/jest/deno/pytest-cov の閾値設定があり CI で実行され、**lines の閾値が 70% 以上** |
| `testing.L3.e2e` | e2e または VRT がある | service, site | Playwright 等の e2e が CI で走る |
| `testing.L3.no-retry` | テストのリトライで失敗を隠していない | | テストランナーのリトライ設定が 0(Playwright `retries`、vitest `retry`、jest `retryTimes`、pytest-rerunfailures 等)。CI のみリトライする設定も fail |
| `testing.L4.no-flaky` | flaky なテストが 0 | | 直近 30 日のデフォルトブランチで「失敗 → 同一 SHA の rerun で成功」した run が 0。テストレポート(Playwright の flaky 集計、JUnit XML 等)が artifact にあれば、リトライ後 pass のテストも 0 であること |
| `testing.L4.coverage-high` | カバレッジ閾値が高い | | `testing.L3.coverage-gate` を満たし、**lines の閾値が 90% 以上** |

## Documentation (`docs`)

| ID | 基準 | 適用 | 判定方法 |
|---|---|---|---|
| `docs.L1.readme` | README にセットアップ手順 | | README に install/setup/起動 相当の手順がある |
| `docs.L2.agent-md` | CLAUDE.md(or AGENTS.md)にコマンド | | テスト・リント・ビルド(該当するもの)のコマンドが書かれている |
| `docs.L2.architecture` | 構成の説明がある | | CLAUDE.md/README にディレクトリ構成 or 主要モジュールの役割がある |
| `docs.L3.fresh` | CLAUDE.md のコマンドが実際に動く | | 記載コマンドを実行して全て成功(deploy 等の副作用系は存在確認のみ) |

## Security (`security`)

| ID | 基準 | 適用 | 判定方法 |
|---|---|---|---|
| `security.L1.no-hardcoded-secrets` | 秘匿情報のハードコードなし | | gitleaks があれば `gitleaks detect`、無ければトークン/キーのパターンを grep + 目視 |
| `security.L2.branch-protection` | ブランチ保護 or ruleset | | デフォルトブランチに protection か ruleset がある。API が 404 `Branch not protected` なら fail、403(プラン上利用不可。private リポジトリで起こる)なら `n/a` |
| `security.L2.secret-scanning` | secret scanning + push protection 有効 | public リポ | `security_and_analysis` の2項目が enabled。private で利用不可なら `n/a` |
| `security.L2.workflow-permissions` | Actions の permissions が最小 | workflow がある | 全 workflow にトップレベル or job 単位の `permissions:` がある、かつリポジトリのデフォルト workflow 権限が read |
| `security.L3.no-high-alerts` | Dependabot alerts の High 以上が 0 | | API で open alerts を取得。alerts 無効なら `unknown` |
| `security.L3.code-scan` | コードスキャンで High 指摘 0 | | `claude-security` or サブエージェントでの全体スキャン結果 |

## Task Discovery (`task`)

| ID | 基準 | 適用 | 判定方法 |
|---|---|---|---|
| `task.L1.labels` | 自動化用ラベルが揃っている | | `autopilot` / `autopilot:dashboard` が存在 |
| `task.L2.issue-template` | 自動化向け Issue テンプレート | | `.github/ISSUE_TEMPLATE/` に「完了条件」欄が必須のテンプレートがある |
| `task.L2.pr-template` | PR テンプレート | | `.github/pull_request_template.md` 等 |

`task.L1.labels` はこのスキルが Step 5 で作成するため、2回目以降の精査では通常 pass になる。

## CI 健全性 (`ci`)

| ID | 基準 | 適用 | 判定方法 |
|---|---|---|---|
| `ci.L1.runs-on-pr` | 全ての変更が PR で検証される | | `pull_request` トリガーの workflow がある。かつ `paths` / `paths-ignore` で絞っている場合、それらの和集合でドキュメント(`*.md` 等)以外の追跡ファイルが全てカバーされている。カバーされないディレクトリがあれば fail とし、根拠に列挙する |
| `ci.L2.default-green` | デフォルトブランチが green | | workflow ごとの最新 completed run が全て success(直近 10 run で判定) |
| `ci.L2.required-checks` | 必須チェック設定済み | | branch protection / ruleset の required status checks が1つ以上。`security.L2.branch-protection` が `n/a` なら同じく `n/a` |
| `ci.L3.zero-annotations` | 警告 annotation 0 | | デフォルトブランチ最新 run の check-runs annotations に warning/failure が 0 |
| `ci.L3.no-rerun` | rerun で通るジョブがない | | 直近 30 日に `run_attempt > 1` で success になった run が 0 |
| `ci.L4.fast` | CI が 10 分以内 | | 直近 10 run の PR CI 所要時間の中央値が 10 分以内 |

## Dev Environment (`devenv`)

| ID | 基準 | 適用 | 判定方法 |
|---|---|---|---|
| `devenv.L1.env-example` | 必要な環境変数が列挙されている | | コード中で参照される環境変数が `.env.example` 等に全て載っている。環境変数を使わなければ pass |
| `devenv.L2.one-command-start` | 1コマンドで起動 or セットアップ | | service/site: `dev`/`start`/`serve` 相当のスクリプト。library/tool: セットアップ・インストール相当(`setup.sh`、`make install`、`pnpm install && pnpm build` 等)が1コマンド |
| `devenv.L2.documented` | 起動・セットアップ手順が CLAUDE.md にある | | CLAUDE.md に上記コマンドと前提(必要なツール、環境変数)がある |
| `devenv.L3.local-deps` | 外部依存をローカルで代替できる | service, site | DB/KV/外部 API について エミュレータ・docker compose・モックのいずれかがある。外部依存が無ければ pass |
| `devenv.L4.non-interactive` | 起動〜テストが非対話で完結 | service, site | ログイン・手入力・ローカル固有の秘匿ファイルなしで、クリーンな環境(クラウド Routine 想定)でテストまで通る |

## Observability (`obs`)

| ID | 基準 | 適用 | 判定方法 |
|---|---|---|---|
| `obs.L1.errors-surface` | 本番エラーが出力される | service | エラーを握りつぶす catch(空 catch、ログなしで握る)が無い。全精査 |
| `obs.L2.structured-logs` | 構造化ログ | service | JSON 等のレベル付きログ出力を使っている |
| `obs.L2.documented` | ログの見方が書かれている | service | CLAUDE.md にログ/エラーの確認方法がある |
| `obs.L3.alerting` | 異常を検知できる | service, site | Sentry 等のエラー通知、ヘルスチェック、外形監視のいずれか |
| `obs.L4.agent-readable` | エージェントがログ・エラーを読める | service, site | CLI/API でログ・エラーを取得する手順と認証の前提が CLAUDE.md にあり、非対話で実行できる |
