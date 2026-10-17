# 自動マージ判定

リポジトリの Autopilot レベルと Issue の Risk の組み合わせで決める。

| Risk | 自動マージ |
|---|---|
| Low | レベル L3 以上 |
| Medium | レベル L4 以上 |
| High | 常に不可 |

加えて、以下を **全て** 満たすこと。1つでも欠けたら自動マージ不可(Review)。

- CI が全て green
- 変更が Issue の完了条件の範囲内(worker 自身が「範囲外として残したもの」に該当する変更を入れていない)
- `.github/workflows/` の変更を含まない(Issue の目的が CI 設定そのものでも、workflow 変更は人間がマージする)
- 依存関係の追加・メジャー更新を含まない(Risk=Low の「依存更新」は Renovate 等の bot に任せる前提)

## レベルの取得

対象リポジトリのダッシュボード Issue(ラベル `autopilot:dashboard`)本文先頭の `autopilot-state` から読む。

```bash
n=$(gh issue list -R swfz/<repo> --label autopilot:dashboard --state open --json number --jq '.[0].number')
gh issue view $n -R swfz/<repo> --json body --jq .body \
  | sed -n '/<!-- autopilot-state/,/-->/p' | sed '1d;$d' | jq .level
```

- ダッシュボードが無い・読めない → 自動マージ不可
- ダッシュボードの `audited_at` が 30 日以上前 → 自動マージ不可(レベルが実態とずれている可能性。報告で autopilot-audit の再実行を提案)

## 自動マージの実行

```bash
gh pr merge <PR> -R swfz/<repo> --auto --squash
```

`--auto` は必須チェック(ブランチ保護 / ruleset)が前提。L3 以上なら `ci.L2.required-checks` を満たしているはずだが、`--auto` が失敗したら自動マージ不可として Review にする(直接マージにはフォールバックしない)。
