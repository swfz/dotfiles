---
name: autopilot-audit
description: >
  リポジトリを「人間の手無しで運用できる状態(Autopilot)」の観点で全精査し、
  9本の柱 × L1〜L4 の基準で自律度レベルを判定、次のレベルを阻んでいる項目を
  消化Routineがそのまま着手できる粒度のIssueとして起票するスキル。
  判定結果はリポジトリごとのダッシュボードIssueに保存する。修正やPR作成は行わない
  (Issueの消化は別Routineの責務)。
  トリガー例:「autopilot-auditして」「autopilotの判定をして」「このリポジトリの自律度を判定して」「Agent Readinessを測って」
  「人間の手無しで回せるか精査して」「改善点をIssue化して」「土台整備のIssueを切って」
allowed-tools:
  - Bash(gh repo view:*)
  - Bash(gh repo clone:*)
  - Bash(gh api:*)
  - Bash(gh run list:*)
  - Bash(gh run view:*)
  - Bash(gh issue list:*)
  - Bash(gh issue view:*)
  - Bash(gh label list:*)
  - Bash(git log:*)
  - Bash(git ls-files:*)
  - Bash(git fetch:*)
---

# autopilot-audit

リポジトリが **AIエージェントだけで安全に改善・運用できる状態** にどれだけ近いかを判定し、
足りないものを Issue 化する。Factory.ai の Agent Readiness モデルを swfz 配下向けに調整したもの。

全体の運用像:

```
[autopilot-audit] (このスキル / 手動 or 低頻度Routine)
  全精査 → レベル判定 → ダッシュボードIssue更新 → 改善Issueを autopilot:proposed で起票
                                                       ↓ swfz が承認して autopilot:approved に付け替え
[消化Routine] (別スキル / このスキルの範囲外)
  autopilot:approved を拾う → autopilot:working → 実装・PR作成
  自動マージ可否はダッシュボードのレベルと Issue の autopilot:risk-* ラベルで決める
```

## 絶対守ること

1. **swfz 所有以外のリポジトリには Issue を作らない**。`gh repo view --json owner` で owner が `swfz` でなければ、判定結果を会話に出すだけで終了する
2. **このスキルではコードを変更しない・PRを作らない**。成果物はダッシュボードIssueと改善Issueのみ
3. **1回の起票は最大10件**。溢れた分はダッシュボードの「未起票」に載せる
4. **重複起票しない**。Issue 本文の `autopilot-id` マーカーで既存 Issue(open)と突き合わせる
5. **根拠のない判定をしない**。各基準の pass/fail には、確認したコマンド出力か `file:line` を根拠として残す。判定できなかったものは `unknown` とし、fail 扱いにしない

## ワークフロー

### Step 0: 対象リポジトリの確定

- 引数でリポジトリ(`owner/repo` or 名前)が指定されていればそれ、無ければカレントディレクトリの git リポジトリ
- ローカルパス解決: カレント → `~/ghq/github.com/swfz/<repo>` → 無ければ `gh repo clone` で scratchpad に取得
- `git fetch` してデフォルトブランチの最新を見る(作業ブランチではなくデフォルトブランチを判定対象にする)
- owner チェック(絶対守ること 1)

### Step 1: リポジトリ種別の判定

基準の適用範囲を決めるため、種別を1つ決める。判定根拠も記録する。

| 種別 | 例 | 判定の手がかり |
|---|---|---|
| `service` | Webアプリ、API、Bot、常駐ワーカー | デプロイ設定(wrangler.toml, deno deploy, Dockerfile, vercel.json 等)、サーバ起動コード |
| `site` | 静的サイト、ブログ | SSG 設定(gatsby, astro, next export 等)、Pages へのデプロイ workflow |
| `library` | パッケージ、Action | package.json の `main`/`exports`、`action.yml`、公開設定 |
| `tool` | CLI、スクリプト集、dotfiles | bin/、スクリプト中心、デプロイ先なし |

迷ったらユーザーに確認する(Routine 実行時は最も近いものを選び、ダッシュボードに「種別: 推定」と残す)。

#### アプリの列挙

リポジトリ内に独立したアプリ(サブプロジェクト)があれば列挙する。ルート以外で `go.mod` / `package.json` / `deno.json` / `pyproject.toml` / `Cargo.toml` / `Gemfile` を持つディレクトリが対象(`node_modules` 等の依存ディレクトリ、テスト用 fixture は除く)。

- アプリごとにも種別を決める(例: dotfiles 全体は `tool`、`src/rdpick` は `tool`)
- ルート自体にコードや設定があればルートも1つのアプリ(`@.`)として扱う
- criteria.md の「スコープ」が `app` の基準はアプリごとに判定する。判定結果は `<ID>@<パス>` で表す(`testing.L2.ci-runs-tests@src/rdpick`)

### Step 2: 基準の判定

[references/criteria.md](references/criteria.md) の全基準を判定する。各基準は `pass` / `fail` / `n/a` / `unknown` のいずれか。

- GitHub 側の設定(ブランチ保護、secret scanning、CI 履歴、ラベル等)は `gh` で取得する。コマンドは [references/commands.md](references/commands.md)
- **ローカルに無いツール**(gitleaks、yamllint、ansible-lint 等)が判定に必要な場合:
  - 対話実行: ツール名・実行方法(`uvx` / `mise x` / `pnpm dlx` / `go run` 等の一時実行)・用途を示して **都度ユーザーに確認** してから実行する。グローバルインストールはしない。一度許可されたツールでも、別の実行ではまた確認する
  - Routine 実行: 実行せず該当基準を `unknown` にし、報告とダッシュボードに「未導入ツール」として列挙する
- コードの中身を読む必要がある基準(主要ロジックのテスト有無、エラー握りつぶし、秘匿情報など)は**全精査**する。規模が大きければ柱ごとにサブエージェント(`Explore` / `general-purpose`)へ並列に投げ、根拠付きで返させる
- Security の L3 は `claude-security` プラグインがあれば Scan codebase(medium)を使う。無ければ `general-purpose` にセキュリティ観点の全体スキャンを依頼する
- 実行が必要な基準(テストがローカルで通る、CLAUDE.md のコマンドが動く)は実際に実行する。破壊的・外部送信を伴うコマンド(deploy, publish, 本番DB操作)は実行しない

### Step 3: レベル算出

- 各レベルの **適用可能な基準**(`n/a` を除く)のうち **80% 以上が pass** ならそのレベルを満たす
- スコープ `app` の基準はアプリごとに1件として数える(アプリ2つなら `testing.L1.exists@.` と `testing.L1.exists@src/rdpick` の2件)
- `unknown` は分母に含め、pass には数えない(判定できないこと自体が無人運用の阻害要因のため)
- レベルは下から順に判定し、満たせなかった最初のレベルの1つ手前が現在レベル(L1 未達なら `L0`)
- 柱ごとのレベルも同じルールで算出し、ダッシュボードに表示する(参考値。自動マージ判定には全体レベルを使う)

### Step 4: 起票候補の優先順位付け

fail の基準を以下の順で並べ、上位 10 件を起票対象にする。

1. **次のレベル**(現在レベル+1)の fail 基準。80% 到達に必要な分を最優先
2. 同じレベル内では **他の基準の前提になるもの** を先に(例: `ci.L1.runs-on-pr` → `testing.L2.ci-runs-tests` → `ci.L2.required-checks`)
3. それ以外は低いレベルから順に
4. 既に open な Issue の `autopilot-id` に含まれている ID は起票せずスキップ(件数にも数えない)。分割 ID(`#サフィックス` 付き)は、同じサフィックスの Issue があればスキップ。サフィックス違いの open Issue がある場合は、未カバーの部分だけを新しいサフィックスで起票する

Issue の粒度は **1 Issue = 1 PR** に合わせる。基準と Issue は1対1とは限らない。

- **分割**: 1つの基準が大きい場合(例: `testing.L2.core-logic` で未テストのモジュールが5つ)は分割し、同じ ID に `#<サフィックス>` を付けて区別する(`testing.L2.core-logic#logger`)
- **統合**: 同じ変更で複数の基準が直る場合は1つの Issue にまとめ、`autopilot-id` に全ての ID を列挙する。統合した Issue も上限 10 件の中では1件と数える
  - 例: `build.L2.cooldown-pm` + `build.L2.lockfile` + `build.L2.runtime-pinned` →「CI の ansible を uv + lock で固定する」
  - 例: `docs.L2.agent-md` + `docs.L2.architecture` →「CLAUDE.md を作成する」
  - 統合するのは、触るファイルと完了条件の確認方法が共通するものだけ。関心事が違うもの(permissions と lockfile 等)は統合しない

### Step 5: ラベル準備と起票

- 必要なラベルが無ければ作成する([references/issue-format.md](references/issue-format.md) のラベル一覧)
- Issue 本文は [references/issue-format.md](references/issue-format.md) のテンプレートに従う。**完了条件は消化Routineが機械的に確認できる形で書く**
- **依存先から順に起票する**。後続 Issue の「依存」欄には、先に起票した Issue の実番号を入れる
- 全件に `autopilot` + 状態ラベル(通常 `autopilot:proposed`、GitHub 設定変更など人間作業のものは `autopilot:handoff`)+ `autopilot:risk-*` を付ける。`autopilot:approved` は付けない(承認制)

### Step 6: 既存 Issue の整理

- open な autopilot Issue のうち、`autopilot-id` に列挙された基準が全て `pass` になったもの → 「精査で達成を確認」とコメントしてクローズ(一部だけ pass なら、どれが達成済みかをコメントするだけで open のまま)
- 基準そのものが `n/a` になったもの → 理由をコメントしてクローズ(`not planned`)

### Step 7: ダッシュボード更新

[references/dashboard.md](references/dashboard.md) の形式でダッシュボード Issue を作成または本文を上書きし、前回からの差分をコメントで残す。

### Step 8: 報告

```
=== autopilot-audit: swfz/<repo> ===
種別: service
レベル: L1 → L2 (L3 まで 7/12 pass, 80% には残り 3)
柱別: Style L2 / Build L2 / Testing L1 / Docs L2 / Security L1 / Task L1 / CI L2 / DevEnv L1 / Obs L0

起票 (autopilot:proposed, 6件):
  #45 [ci.L2.required-checks] 必須チェックを設定する  autopilot:risk-low
  #46 [testing.L2.core-logic#logger] logger.ts にテストを追加  autopilot:risk-low
  ...
クローズ (達成済み, 2件): #31, #33
未起票 (上限超過, 4件): ダッシュボード参照
unknown (判定不能, 1件): obs.L3.alerting — Sentry の有無をリポジトリから判断できず
未導入ツール: yamllint, ansible-lint (確認の上で実行 / Routine では unknown)

ダッシュボード: https://github.com/swfz/<repo>/issues/<n>
次の一手: 起票した Issue を確認し、着手してよいものに autopilot:approved を付ける
```

## 避けること

- 基準を満たすためだけの形骸化した Issue(例: 中身のない CLAUDE.md を置くだけ)。完了条件に「中身」を書く
- 種別に合わない基準の押し付け(`tool` に外形監視を要求する等)。迷ったら `n/a` にして理由を残す
- 同じ精査で `autopilot-id` の命名を揺らすこと。基準 ID は criteria.md の表記をそのまま使う
