#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET="${REPO_DIR}/bin/gh-open-prs"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

# 実際の GitHub に接続しないよう、PATH の先頭に gh のスタブを置く。
# スタブは GH_STUB_RESPONSE の GraphQL レスポンスに --jq の式をかけて返し、受け取った引数を記録する
STUB_BIN="${TMP_ROOT}/bin"
mkdir -p "$STUB_BIN"
cat >"${STUB_BIN}/gh" <<'STUB'
#!/bin/bash
printf '%s\n' "$@" >"$GH_STUB_ARGS"
filter=.
while [ $# -gt 0 ]; do
  if [ "$1" = "--jq" ]; then
    filter="$2"
    shift
  fi
  shift
done
jq -c "$filter" <"$GH_STUB_RESPONSE"
STUB
chmod +x "${STUB_BIN}/gh"

export GH_STUB_ARGS="${TMP_ROOT}/gh-args"
export GH_STUB_RESPONSE="${TMP_ROOT}/response.json"

run_target() {
  PATH="${STUB_BIN}:${PATH}" bash "$TARGET" "$@"
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# pr <repo> <number> <createdAt の日付> <statusCheckRollup.state | null>
pr() {
  local rollup="null"
  [ "$4" = "null" ] || rollup="{\"state\": \"$4\"}"
  cat <<JSON
{
  "number": $2, "title": "PR $2", "url": "https://github.com/$1/pull/$2",
  "createdAt": "$3T00:00:00Z", "updatedAt": "$3T12:00:00Z",
  "author": {"login": "swfz"}, "repository": {"nameWithOwner": "$1"},
  "commits": {"nodes": [{"commit": {"statusCheckRollup": $rollup}}]}
}
JSON
}

# --- 引数なし・不正なサブコマンド: usage を出して終了コード 1 ---
for args in "" "unknown"; do
  set +e
  # shellcheck disable=SC2086 # 引数なしのケースを作るため意図的に分割する
  out="$(run_target $args 2>&1)"
  status=$?
  set -e
  [ "$status" -eq 1 ] || fail "引数 '${args}' で終了コードが 1 でない: ${status}"
  [[ "$out" == *"Usage: gh-open-prs <summary|json> [username]"* ]] || fail "引数 '${args}' で usage が出ない: ${out}"
done

# --- PR 0 件: メッセージを出して終了コード 0 ---
echo '{"data": {"search": {"nodes": []}}}' >"$GH_STUB_RESPONSE"
out="$(run_target json someone)"
[ "$out" = "No open PRs found for user: someone" ] || fail "0 件のメッセージが違う: ${out}"
grep -qx 'q=is:open is:pr user:someone archived:false' "$GH_STUB_ARGS" || fail "検索クエリに username が入らない: $(cat "$GH_STUB_ARGS")"

# --- json: CI 状態の分類、件数、リポジトリの並び順 ---
cat >"$GH_STUB_RESPONSE" <<JSON
{"data": {"search": {"nodes": [
  $(pr swfz/small 1 2026-10-01 SUCCESS),
  $(pr swfz/large 10 2026-10-02 SUCCESS),
  $(pr swfz/large 11 2026-10-05 FAILURE),
  $(pr swfz/large 12 2026-10-03 ERROR),
  $(pr swfz/large 13 2026-10-04 PENDING),
  $(pr swfz/medium 20 2026-10-06 null),
  $(pr swfz/medium 21 2026-10-07 EXPECTED)
]}}}
JSON

json="$(run_target json)"
grep -qx 'q=is:open is:pr user:swfz archived:false' "$GH_STUB_ARGS" || fail "username の既定値が swfz でない: $(cat "$GH_STUB_ARGS")"

expect_json() {
  local actual
  actual="$(printf '%s' "$json" | jq -c "$1")"
  [ "$actual" = "$2" ] || fail "json の $1 が $2 でない: ${actual}"
}
expect_json '.total' '7'
expect_json '.repo_count' '3'
# SUCCESS → success、FAILURE と ERROR → fail、それ以外の state → pending、null → none
expect_json '.ci' '{"success":2,"fail":2,"pending":2,"none":1}'
expect_json '[.repositories[] | .repo]' '["swfz/large","swfz/medium","swfz/small"]'
expect_json '[.repositories[] | .count]' '[4,2,1]'
expect_json '.repositories[0].ci' '{"success":1,"fail":2,"pending":1,"none":0}'
expect_json '[.repositories[0].prs[] | {number, ci}]' '[{"number":11,"ci":"Fail"},{"number":13,"ci":"Pending"},{"number":12,"ci":"Fail"},{"number":10,"ci":"Success"}]'
expect_json '.repositories[1].prs | map(.ci)' '["Pending","-"]'
expect_json '.repositories[0].prs[0] | {created_at, updated_at, user, url}' '{"created_at":"2026-10-05","updated_at":"2026-10-05","user":"swfz","url":"https://github.com/swfz/large/pull/11"}'

# --- summary: 合計行と CI 集計行、リポジトリごとの行 ---
summary="$(run_target summary)"
[[ "$summary" == *"Total: 7 PRs across 3 repositories"* ]] || fail "summary の合計行が違う: ${summary}"
[[ "$summary" == *"CI: Success 2 / Fail 2 / Pending 2 / - 1"* ]] || fail "summary の CI 行が違う: ${summary}"
printf '%s\n' "$summary" | grep -qE '^ *swfz/large +4 +1 +2 +1 +0$' || fail "summary に swfz/large の行が無い: ${summary}"
first_repo="$(printf '%s\n' "$summary" | awk '/^ *swfz\//{print $1; exit}')"
[ "$first_repo" = "swfz/large" ] || fail "summary の先頭が PR 件数の最も多いリポジトリでない: ${first_repo}"

echo "gh-open-prs tests passed"
