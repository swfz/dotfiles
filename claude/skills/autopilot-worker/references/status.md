# Status の遷移

Project「autopilot」の Status。

```
Proposed ──(swfz 承認)──→ Approved ──(worker 着手)──→ Working ──┬─(自動マージ可)──→ --auto でマージ → Done
    │                        ↑                           │       └─(自動マージ不可)──→ Review ──(swfz マージ)──→ Done
    │                        │(回収: PR なし 24h)         │
    └─(起票時点で人間作業)──→ Handoff ←────(詰まった)──────┘
                             │(swfz が判断をコメントして Approved に戻す)
```

| Status | 意味 | worker の扱い |
|---|---|---|
| Proposed | 起票直後。承認待ち | 触らない |
| Approved | 承認済み | 着手対象 |
| Working | worker が着手中 / 自動マージ待ち | 回収判定のみ |
| Review | PR 作成済み。人間のマージ待ち | 触らない(PR への指摘対応は現状対象外) |
| Handoff | 人間に引き継ぎ | 触らない |
| Done | 完了 | 触らない |

Done への遷移は Project のビルトインワークフロー(Item closed → Done)に任せる。worker から Done にはしない。

## Working の回収

手順 0 で、Status=Working の Item ごとに判定する。着手時刻は Issue の `<!-- autopilot-worker:start -->` コメントのうち最新のものの作成日時。

| 状態 | 処理 |
|---|---|
| Issue がクローズ済み | 何もしない(ワークフローで Done になるはず。Done になっていなければ Done に変更) |
| `autopilot/<n>-*` の PR が open で auto-merge 設定あり | 何もしない(マージ待ち) |
| `autopilot/<n>-*` の PR が open で auto-merge 設定なし | Review に変更 |
| PR がマージされずクローズされている | Handoff に変更し「PR がクローズされた」とコメント |
| PR が無く、着手から 24 時間以上経過 | Approved に戻し「前回の実行が途中で止まったため差し戻し」とコメント。作業ブランチが push 済みならコメントにリンクを残す |
| PR が無く、24 時間未満 | 何もしない(別の実行が作業中の可能性) |

```bash
# 最新の着手コメント時刻
gh issue view <n> -R swfz/<repo> --json comments \
  --jq '[.comments[] | select(.body | startswith("<!-- autopilot-worker:start -->"))] | last | .createdAt'
# Issue に対応する worker の PR
gh pr list -R swfz/<repo> --state all --limit 100 --json number,state,autoMergeRequest,headRefName \
  --jq '.[] | select(.headRefName | startswith("autopilot/<n>-")) | {number, state, auto: (.autoMergeRequest != null)}'
```

## Status の変更

フィールド ID・選択肢 ID は実行のたびに取得する([../../autopilot-audit/references/project.md](../../autopilot-audit/references/project.md) の `fid` / `oid`)。

```bash
gh project item-edit --id <item-id> --project-id PVT_kwHOAD6fZs4BnbII \
  --field-id "$(fid Status)" --single-select-option-id "$(oid Status Working)"
```
