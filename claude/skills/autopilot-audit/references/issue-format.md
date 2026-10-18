# Issue フォーマット

改善 Issue は **消化Routineと人間の間の契約**。消化Routineが追加の判断なしに着手・完了判定できることを最優先にする。

## ラベル

ラベルは識別用の2つだけ。状態・リスク・レベル・柱は Project「autopilot」のフィールドで持つ([project.md](project.md))。

| ラベル | 色 | 用途 |
|---|---|---|
| `autopilot` | `5319e7` | このスキル由来の Issue 全て(重複チェックに使う) |
| `autopilot:dashboard` | `5319e7` | ダッシュボード Issue |

```bash
gh label create "autopilot" --color 5319e7 --description "autopilot-audit 由来の Issue" -R swfz/<repo> 2>/dev/null || true
gh label create "autopilot:dashboard" --color 5319e7 --description "Autopilot ダッシュボード" -R swfz/<repo> 2>/dev/null || true
```

## リスク区分(Project の Risk)

消化Routineの自動マージ判定に使う。ダッシュボードのレベルとの組み合わせで決まる。起票時に決め、以後は変えない。

| Risk | 対象 | 自動マージ |
|---|---|---|
| `Low` | テスト追加、ドキュメント、CI/lint 設定の追加、ラベル・テンプレート追加、依存更新 | L3 以上で CI green なら可 |
| `Medium` | リファクタ、小さなバグ修正、lint 警告の解消、ログ出力の追加 | L4 以上で CI green なら可 |
| `High` | 認証・認可、秘匿情報、データ永続化の変更、ブランチ保護など GitHub 設定の変更、デプロイ設定 | 常に人間がマージ |

GitHub のリポジトリ設定(ブランチ保護、secret scanning 等)を変える Issue はコード変更で完結しないため、Risk=`High`、Status=`Handoff` で起票する。

## タイトル

```
[autopilot] <やること(動詞で終わる)>
```

例: `[autopilot] PR で CI を実行する` / `[autopilot] logger.ts にテストを追加する`

## 本文テンプレート

`autopilot-id` マーカーの書式:

- 1基準: `testing.L2.core-logic#logger`(`#` 以降は分割時のサフィックス)
- 複数基準をまとめた場合: カンマ+スペース区切り `build.L2.cooldown-pm, build.L2.lockfile, build.L2.runtime-pinned`
- app スコープの基準: `@<アプリのパス>` を付ける `testing.L2.ci-runs-tests@src/rdpick`
- マーカーは本文に1つだけ。本文の他の箇所に `autopilot-id:` という文字列を書かない(重複チェックが誤検出する)

```markdown
<!-- autopilot-id: testing.L2.core-logic#logger -->
<!-- autopilot-audit: <精査日 YYYY-MM-DD> <精査時のデフォルトブランチ SHA 先頭7桁> -->

## 背景

<どの柱・レベルを阻んでいるか。なぜ無人運用に必要か。1〜3行>

- 基準: `testing.L2.core-logic` 主要ロジックにテストがある(複数ならすべて列挙)
- 現在レベル: L1 → この Issue は L2 到達に寄与

## 現状(根拠)

<判定の根拠。file:line、コマンドと出力の抜粋>

## やること

- <具体的な作業。ファイル名・関数名まで>

## 完了条件

- <機械的に確認できる条件。コマンドと期待結果で書く>
- <例: `pnpm test` が成功し、`src/logger.test.ts` に req.body あり/なし の両ケースがある>
- 既存のテスト・リントが全て通る

## 範囲外

- <やらないこと。スコープ肥大を防ぐ>

## メタ

柱・レベル・リスクは Project のフィールドが正。本文には書かない(二重管理でずれるため)。

| 項目 | 値 |
|---|---|
| 想定規模 | S(〜50行) / M(〜200行) / L(それ以上 → 分割を検討) |
| 依存 | #<先に片付けるべき Issue>(あれば) |
```

## 書き方の原則

- **完了条件は「入力 → 期待結果」で書く**。「〜を改善する」「適切に〜」は禁止
- **完了条件はチェックボックスにしない**(箇条書き)。満たしたかどうかの記録は worker が PR 本文のチェックリストで行う。Issue と PR の二重管理にしない
- **想定規模 L は原則作らない**。精査の段階で分割する
- **依存関係を明示**。`ci.L2.required-checks` は `ci.L1.runs-on-pr` の後、など
- 根拠にシークレットの値そのものを書かない(`file:line` とパターン名のみ)
- public リポジトリでは、未修正の脆弱性の詳細(再現手順・エクスプロイト可能な箇所)を Issue に書かない。`security.L3.code-scan` の具体的な指摘は「詳細はローカルの精査結果を参照」とし、Status=`Handoff` で起票してユーザーに報告する

## 重複チェック

```bash
gh issue list -R swfz/<repo> --label autopilot --state open --limit 200 --json number,title,body \
  --jq '.[] | {number, ids: ((.body // "") | capture("autopilot-id: (?<ids>[^\\n]+?) -->").ids | split(", "))}'
```

起票しようとしている ID のいずれかが open Issue の `ids` に含まれていれば起票しない。
