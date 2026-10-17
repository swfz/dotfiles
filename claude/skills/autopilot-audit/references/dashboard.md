# ダッシュボード Issue

リポジトリごとに1つ。判定結果の保存先であり、消化Routineが自動マージ可否を決めるときの参照先。

- タイトル: `[autopilot] Autopilot Dashboard`
- ラベル: `autopilot`, `autopilot:dashboard`
- 常に open のまま。本文は精査のたびに **上書き**、前回との差分は **コメント** で残す
- 検索: `gh issue list -R swfz/<repo> --label autopilot:dashboard --state open --json number`

## 本文

先頭の `autopilot-state` コメントは機械可読部分。消化Routineはここだけを読む。人間向けの表は後続に置く。

```markdown
<!-- autopilot-state
{
  "level": 2,
  "kind": "service",
  "kind_inferred": false,
  "apps": {".": "service", "packages/worker": "service"},
  "audited_at": "2026-10-16",
  "sha": "abc1234",
  "pillars": {"style": 2, "build": 2, "testing": 1, "docs": 2, "security": 1, "task": 1, "ci": 2, "devenv": 1, "obs": 0},
  "next_level": {"level": 3, "pass": 7, "applicable": 12, "required": 10}
}
-->

# Autopilot: **L2** (文書化)

精査日: 2026-10-16 / 対象: `master` @ abc1234 / 種別: service

L3 まで: 7 / 12 pass(80% には残り 3)

自動マージ: autopilot:risk-low 不可(L3 未満)/ autopilot:risk-medium 不可(L4 未満)

## 柱別

| 柱 | レベル | L1 | L2 | L3 | L4 |
|---|---|---|---|---|---|
| Style & Validation | L2 | 2/2 | 2/2 | 1/3 | – |
| Build | L2 | 1/1 | 3/3 | 1/2 | 0/1 |
| ... | | | | | |

## 基準別

| ID | 結果 | 根拠 | Issue |
|---|---|---|---|
| `style.L1.linter` | ✅ pass | biome.json | |
| `testing.L2.core-logic` | ❌ fail | logger.ts, contributions.ts に対応テストなし | #46, #47 |
| `security.L2.secret-scanning` | ➖ n/a | private リポジトリ | |
| `obs.L3.alerting` | ❓ unknown | Sentry 設定をリポジトリから確認できず | |
| `testing.L2.ci-runs-tests@packages/worker` | ❌ fail | CI で packages/worker のテストが実行されていない | #48 |

app スコープの基準は `<ID>@<パス>` で行を分ける(アプリがルートのみなら `@.` は省略)。

## 未導入ツール

判定に必要だがローカルに無く、実行しなかったツール。該当基準は unknown。

- yamllint, ansible-lint → `style.L3.zero-warnings`

## 未起票(上限超過)

- `ci.L4.fast` CI 中央値 14 分
- ...
```

## 差分コメント

```markdown
精査 2026-10-16 (abc1234)

レベル: L1 → **L2**
新たに pass: `ci.L2.required-checks`, `docs.L2.agent-md`
新たに fail: `style.L3.zero-warnings`(lint 警告 3 件)
起票: #45, #46 / クローズ: #31, #33
```

初回はコメントせず本文のみ作成する。
