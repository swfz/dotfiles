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

## individual-project への連携

人の手が入る作業は、swfz の作業実績を記録している Project「individual-project」(https://github.com/users/swfz/projects/2)にも入れる。autopilot の Status 管理はそのまま autopilot 側で続ける。

| 対象 | 入れるもの | Status |
|---|---|---|
| Handoff にした Issue(起票時の Handoff を含む) | Issue | `Todo` |
| Handoff から人が対応して作った PR、会話の中で直接作った派生 PR | PR | open なら `Review`、マージ済みなら `Done` |

worker が無人で作って自動マージ・Review になった PR は入れない(人の作業ではないため)。

individual-project は 1000 件超あるので `gh project item-list 2` で全件取らない(GraphQL のレート制限に当たる)。追加結果の確認は Issue / PR 側の `projectItems` を引く。

フィールド: Point(数値。小さいもの 1、想定規模 M 相当 2、それ以上 3/5)、Month(その月の 1 日)、Iteration(`YYYY-MM`)。

```bash
P2=PVT_kwHOAD6fZs0elg
F2=$(gh project field-list 2 --owner swfz --format json)
fid2() { echo "$F2" | jq -r --arg n "$1" '.fields[] | select(.name==$n) | .id'; }
oid2() { echo "$F2" | jq -r --arg n "$1" --arg o "$2" '.fields[] | select(.name==$n) | .options[] | select(.name==$o) | .id'; }
# Iteration の ID(今月分)
iter=$(gh api graphql -f query='query{user(login:"swfz"){projectV2(number:2){field(name:"Iteration"){... on ProjectV2IterationField{configuration{iterations{id title}}}}}}}' \
  | jq -r --arg t "$(date +%Y-%m)" '.data.user.projectV2.field.configuration.iterations[] | select(.title==$t) | .id')

item=$(gh project item-add 2 --owner swfz --url <Issue/PR の URL> --format json --jq .id)
gh project item-edit --id "$item" --project-id $P2 --field-id "$(fid2 Status)" --single-select-option-id "$(oid2 Status Todo)"
gh project item-edit --id "$item" --project-id $P2 --field-id "$(fid2 Point)" --number 1
gh project item-edit --id "$item" --project-id $P2 --field-id "$(fid2 Month)" --date "$(date +%Y-%m-01)"
gh project item-edit --id "$item" --project-id $P2 --field-id "$(fid2 Iteration)" --iteration-id "$iter"
```

## 承認(当面の運用)

自動承認は入れていない。Project のボード/テーブルで Status を `Approved` に変更する。
