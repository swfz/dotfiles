---
name: autopilot-worker
description: >
  GitHub Projects「autopilot」で Status=Approved になっている Issue を拾い、実装 → ローカル検証 → PR 作成 →
  CI 確認 → (条件を満たせば)自動マージまでを無人で進める消化スキル。autopilot-audit が起票した Issue の
  実行側を担う。日次 Routine からの起動を想定し、件数・対象リポジトリ・対象 Issue は呼び出し時に上書きできる。
  トリガー例:「autopilot-workerを回して」「approvedのIssueを消化して」「autopilotのIssueを片付けて」
  「autopilot消化」「swfz/xxx の autopilot Issue を進めて」
allowed-tools:
  - Bash(gh project item-list:*)
  - Bash(gh project field-list:*)
  - Bash(gh issue view:*)
  - Bash(gh issue list:*)
  - Bash(gh pr list:*)
  - Bash(gh pr view:*)
  - Bash(gh pr checks:*)
  - Bash(gh run view:*)
  - Bash(gh run list:*)
  - Bash(git fetch:*)
  - Bash(git switch:*)
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
---

# autopilot-worker

[autopilot-audit](../autopilot-audit/SKILL.md) が起票し、swfz が承認した Issue を消化する。

```
Project「autopilot」 Status=Approved
  ↓ 0. 準備: 止まっている Working の回収
  ↓ 1. 取得・絞り込み・優先順位付け
  ↓ 2. 着手: Status=Working + 着手コメント
  ↓ 3. 実装・ローカル検証・コミット
  ↓ 4. PR 作成(Closes #n)
  ↓ 5. CI 確認(落ちたら修正、最大 3 回)
  ↓ 6. マージ判定: 自動マージ可 → --auto / 不可 → Status=Review
  ↓    詰まったら → Status=Handoff + 理由コメント
次の Issue へ(上限まで)→ 7. 報告
```

Project の ID・フィールド・コマンドは [../autopilot-audit/references/project.md](../autopilot-audit/references/project.md)。
Status の遷移と各状態の扱いは [references/status.md](references/status.md)。

## パラメータ

呼び出し時の指示(Routine のプロンプト、ユーザーの発話)で上書きできる。指定が無ければ既定値。

| パラメータ | 既定値 | 例 |
|---|---|---|
| 最大件数 | 5 | 「3件まで」「max=10」 |
| 対象リポジトリ | 全て | 「swfz/self-dashboard だけ」 |
| 対象 Issue | 優先順で自動選択 | 「#105 と #106」(Approved であることは必須) |
| CI 修正の最大回数 | 3 | 「CI修正は1回まで」 |
| リポジトリごとの未マージ PR 上限 | 3 | 「PR上限5」 |
| ドライラン | off | 「ドライランで」→ 手順 1 の選定結果を出して終了 |

開始時に、解釈したパラメータを1行で出力してから進む。

## 絶対守ること

1. **swfz 所有リポジトリのみ**。Project に他 owner の Issue があっても触らない
2. **Status=Approved 以外には着手しない**。対象 Issue を指定されても Approved でなければスキップして報告
3. **Issue のスコープを守る**。「やること」「完了条件」の範囲だけ変更する。「範囲外」に書かれたことはしない。途中で見つけた別の問題は直さず、Issue にコメントで残す
4. **コミット前にローカルでテスト・リントを通す**(ユーザー CLAUDE.md)。バグ修正にはリグレッションテストを付ける
5. **副作用のあるコマンドを実行しない**: deploy / publish / export / 本番 DB・ストレージ操作 / 外部への送信。対象リポジトリの CLAUDE.md で禁止されているコマンドも実行しない
6. **force push、`--no-verify`、テストの削除・skip で通すこと、lint ルールの無効化で通すことをしない**。例外として、Issue の完了条件が理由付きの緩和を明示的に許している場合に限り、ルールを `warn` に下げてよい(`off` は不可)。下げたルールと理由は PR 本文に列挙する
7. **GitHub のリポジトリ設定(ブランチ保護、secrets、Actions 権限)を変更しない**。必要なら Handoff
8. **Handoff は失敗ではない**。迷ったら推測で進めず Handoff する

## 手順

### 0. 準備: 止まっている Working の回収

前回の実行が途中で落ちて Working のまま残った Issue を回収する。判定は [references/status.md](references/status.md) の「Working の回収」。

### 1. 取得・絞り込み・優先順位付け

Project から Status=Approved の Item を取得し、以下で絞り込む。

- Issue が open
- 「メタ」の「依存」欄に書かれた Issue が全てクローズ済み
  ```bash
  gh issue view <n> -R swfz/<repo> --json body --jq .body | grep -E '^\| 依存 \|' | grep -oE '#[0-9]+' | tr -d '#'
  # 出た番号それぞれ: gh issue view <dep> -R swfz/<repo> --json state --jq .state が CLOSED か
  ```
- そのリポジトリでこのスキルが作った open PR(ブランチ `autopilot/*`)が上限未満
- 対象リポジトリ・対象 Issue の指定があればそれに従う

並び順:

1. Level の低い順(L1 → L4)
2. Risk の低い順(Low → High)
3. Issue 作成日の古い順

上位から最大件数まで処理する。1件ずつ順番に処理し、並列にはしない(同じリポジトリへの変更が衝突するため)。

### 2. 着手

- Status を `Working` に変更
- Issue に着手コメント(先頭に `<!-- autopilot-worker:start -->` マーカー。回収判定に使う)

```
<!-- autopilot-worker:start -->
autopilot-worker が着手しました(<YYYY-MM-DD HH:MM> / ブランチ `autopilot/<n>-<slug>`)
```

### 3. 実装

1. ローカルパス解決: `~/ghq/github.com/swfz/<repo>` → `~/gh/<repo>` → 無ければ `gh repo clone` で作業ディレクトリに取得
2. 未コミットの変更があるローカル clone は使わない(別ディレクトリに clone し直す)
3. デフォルトブランチ最新から `autopilot/<issue番号>-<slug>` を切る(`git fetch origin <default>` → `git switch -c ... origin/<default>`)
4. 対象リポジトリの CLAUDE.md・`.claude/rules/` を読んでから実装する
5. Issue の「やること」を実装し、「完了条件」を1つずつ自分で確認する。確認方法がコマンドで書かれていれば実際に実行する
6. テスト・リント・フォーマッタ・型チェック(あるもの全て)をローカルで実行し、通す
7. コミット(`commit` スキルの流儀: Conventional Commits、日本語、Why を書く)

完了条件を満たせない・満たし方が複数あり判断が要る、と分かった時点で Handoff(手順 6 の Handoff 参照)。

### 4. PR 作成

- `git push -u origin autopilot/<n>-<slug>` → `gh pr create`
- タイトル: Issue タイトルから `[autopilot] ` を除いたものを Conventional Commits 形式に(例: `ci: Node のバージョンを固定し CI の全ジョブで揃える`)
- 本文:

```markdown
Closes #<n>

## 概要
<何をなぜ変えたか。2〜4行>

## 完了条件
- [x] <Issue の完了条件をそのまま転記し、確認結果を付ける>(確認: `<実行したコマンド>` → <結果>)

## テストケース
<追加・変更したテストを「入力 → 期待値」で1行ずつ>

## 範囲外として残したもの
<気づいたがやらなかったこと。無ければ「なし」>

🤖 autopilot-worker
```

PR の Project 紐づけは不要(Issue 側で管理する)。

### 5. CI 確認

- `gh pr checks <PR> --watch` で完了を待つ
- 失敗したら `gh run view --log-failed` で原因を特定して修正 → コミット → push。**最大 3 回**(パラメータで変更可)
- 3 回修正しても green にならなければ Handoff
- 原因が PR の変更と無関係(デフォルトブランチで既に落ちている、外部サービス障害)なら修正せず Handoff。理由に「既存の失敗」と明記する

### 6. マージ判定

[references/merge-policy.md](references/merge-policy.md) に従う。

- **自動マージ可**: `gh pr merge <PR> --auto --squash` → Status は Working のまま。マージで Issue がクローズされ、Project のワークフローで Done になる
- **自動マージ不可**: Status を `Review` に変更。Issue に PR へのリンクをコメント

#### Handoff

手順のどこでも、以下に当たったら Status を `Handoff` にして次の Issue に進む。

- 完了条件が曖昧、または満たし方が複数あり判断が要る
- CI を 3 回修正しても green にならない / 既存の失敗で検証できない
- 秘匿情報・権限・外部サービスの設定が必要
- 変更が「範囲外」に及ぶ、または想定規模を大きく超える(S/M 想定で 300 行超など)
- リポジトリの設定変更が必要

Issue に Handoff コメントを残す。作業途中のブランチや PR があれば残したままリンクする(消さない)。

Handoff にした Issue は Project「individual-project」にも追加する(Status=`Todo`。手順は [../autopilot-audit/references/project.md](../autopilot-audit/references/project.md) の「individual-project への連携」)。

```
<!-- autopilot-worker:handoff -->
autopilot-worker から引き継ぎます。

理由: <1〜2行>
試したこと:
- <やったこと・結果>
判断してほしいこと:
- <swfz に決めてほしいこと。決まったらコメントして Status を Approved に戻せば再開します>
作業ブランチ / PR: <あれば>
```

### 7. 報告

```
=== autopilot-worker ===
パラメータ: max=5 / repo=all / ci-fix=3
回収: #98 Working → Approved(PR なしで 26 時間経過)

処理 (4件):
  swfz/self-dashboard#105 Biome 導入        → PR #120 Review(自動マージ不可: L0)
  swfz/self-dashboard#106 .env.example      → PR #121 Review
  swfz/self-dashboard#108 Node 固定         → Handoff(CI が既存の失敗で検証不可)
  swfz/foo#12 CLAUDE.md 追記                 → PR #30 auto-merge 設定済み(L3 / Low)

スキップ: swfz/self-dashboard#111(依存 #105 が未クローズ)
残り Approved: 2件
```

Routine 実行時は最後にこの報告だけを出力する。
