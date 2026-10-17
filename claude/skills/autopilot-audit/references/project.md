# Project「autopilot」

autopilot Issue の状態・リスク・レベル・柱を管理する GitHub Projects(swfz ユーザー所有)。swfz 配下の全リポジトリの autopilot Issue をここに集める。

- URL: https://github.com/users/swfz/projects/6
- number: `6` / node ID: `PVT_kwHOAD6fZs4BnbII`
- ダッシュボード Issue は追加しない(改善 Issue のみ)

## フィールド

| フィールド | 値 | 設定する主体 |
|---|---|---|
| Status | `Proposed` / `Approved` / `Working` / `Review` / `Handoff` / `Done` | 起票時は autopilot-audit。`Approved` は swfz、`Working` / `Review` / `Handoff` は autopilot-worker、`Done` はクローズ時に Project のビルトインワークフロー |
| Risk | `Low` / `Medium` / `High` | autopilot-audit(起票時に決めて固定。基準は issue-format.md) |
| Level | `L1` / `L2` / `L3` / `L4` | autopilot-audit。その Issue が到達に寄与するレベル(複数基準なら最も低いもの) |
| Pillar | `Style` / `Build` / `Testing` / `Docs` / `Security` / `Task` / `CI` / `DevEnv` / `Obs` | autopilot-audit。複数の柱にまたがる場合は主たるもの1つ |

Status の遷移と各状態の扱いは [../../autopilot-worker/references/status.md](../../autopilot-worker/references/status.md)。

**注意**: 単一選択フィールドの選択肢を API(`updateProjectV2Field`)で変更すると、全 Item のそのフィールドの値が消える。選択肢の追加・変更は GitHub の画面で行う。

`Handoff` は swfz が直接対応してクローズするか、判断をコメントして `Approved` に戻す。

## コマンド

フィールド ID・選択肢 ID は変わりうるので、実行のたびに取得する(ハードコードしない)。

```bash
P=6; OWNER=swfz; PID=PVT_kwHOAD6fZs4BnbII
F=$(gh project field-list $P --owner $OWNER --format json)
fid() { echo "$F" | jq -r --arg n "$1" '.fields[] | select(.name==$n) | .id'; }
oid() { echo "$F" | jq -r --arg n "$1" --arg o "$2" '.fields[] | select(.name==$n) | .options[] | select(.name==$o) | .id'; }

# Issue を追加してフィールドを設定
item=$(gh project item-add $P --owner $OWNER --url https://github.com/swfz/<repo>/issues/<n> --format json --jq .id)
for kv in Status:Proposed Risk:Low Level:L2 Pillar:Testing; do
  k=${kv%%:*}; v=${kv#*:}
  gh project item-edit --id "$item" --project-id $PID --field-id "$(fid $k)" --single-select-option-id "$(oid $k $v)"
done

# リポジトリ単位の一覧(Status / Risk 付き)
gh project item-list $P --owner $OWNER --limit 500 --format json \
  --jq '.items[] | select(.content.repository == "swfz/<repo>") | {n: .content.number, status, risk, level, pillar}'
```

`gh project item-add` は既に追加済みの Issue に対しても既存の item ID を返すので、再実行しても重複しない。

## 承認(当面の運用)

自動承認は入れていない。Project のボード/テーブルで Status を `Approved` に変更する。
