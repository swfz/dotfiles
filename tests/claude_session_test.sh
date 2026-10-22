#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

PROJECTS_DIR="${TMP_ROOT}/projects"
export HOME="${TMP_ROOT}/home"
mkdir -p "$HOME" "${PROJECTS_DIR}/-work-alpha" "${PROJECTS_DIR}/-work-beta" "${PROJECTS_DIR}/memory"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# --- claude-session-list 用の偽セッション ---
# 古い: 最初の user 発言がタイトルになる(タブ・改行は空白、80 文字で切る)
long_text="$(printf 'x%.0s' {1..100})"
cat >"${PROJECTS_DIR}/-work-alpha/old.jsonl" <<JSONL
{"type":"system","cwd":"/work/alpha"}
{"type":"user","message":{"content":"first\tline\nsecond ${long_text}"}}
JSONL
touch -t 202601010000 "${PROJECTS_DIR}/-work-alpha/old.jsonl"

# 新しい: custom-title が最初の user 発言より優先される
cat >"${PROJECTS_DIR}/-work-alpha/new.jsonl" <<'JSONL'
{"type":"user","cwd":"/work/alpha","message":{"content":[{"type":"text","text":"original title"}]}}
{"type":"custom-title","customTitle":"renamed title"}
JSONL
touch -t 202603010000 "${PROJECTS_DIR}/-work-alpha/new.jsonl"

# user 発言が無い → (no title)、壊れた JSON 行を含む
cat >"${PROJECTS_DIR}/-work-beta/notitle.jsonl" <<'JSONL'
{"type":"system","cwd":"/work/beta"}
{"type":"assistant","message":{"content":"hello"}}
JSONL
touch -t 202602010000 "${PROJECTS_DIR}/-work-beta/notitle.jsonl"

cat >"${PROJECTS_DIR}/-work-beta/broken.jsonl" <<'JSONL'
{"type":"user","cwd":"/work/beta","message":{"content":"before broken"}}
{this is not json
JSONL
touch -t 202602150000 "${PROJECTS_DIR}/-work-beta/broken.jsonl"

# memory ディレクトリは対象外
printf '{"type":"user","message":{"content":"memory"}}\n' >"${PROJECTS_DIR}/memory/skip.jsonl"

list_output="$(python3 "${REPO_DIR}/bin/claude-session-list" "$PROJECTS_DIR")"

# ① 日付降順
dates="$(printf '%s\n' "$list_output" | cut -f1 | tr '\n' ' ')"
[[ "$dates" == "2026-03-01 2026-02-15 2026-02-01 2026-01-01 " ]] || fail "日付降順で並ばない: $dates"

line_of() {
  printf '%s\n' "$list_output" | grep -F "${PROJECTS_DIR}/$1" | cut -f2
}

# ② 最初の user 発言がタイトルになり、タブ・改行が空白になり、80 文字で切られる
old_title="$(line_of '-work-alpha/old.jsonl')"
[[ "$old_title" == "[alpha] first line second x"* ]] || fail "タイトルが最初の user 発言にならない: $old_title"
old_body="${old_title#\[alpha\] }"
[[ "${#old_body}" -eq 80 ]] || fail "タイトルが 80 文字で切られない(${#old_body} 文字)"

# ③ custom-title が優先
[[ "$(line_of '-work-alpha/new.jsonl')" == "[alpha] renamed title" ]] || fail "custom-title が優先されない: $(line_of '-work-alpha/new.jsonl')"

# ④ user 発言が無いと (no title)、プロジェクト名は cwd の basename
[[ "$(line_of '-work-beta/notitle.jsonl')" == "[beta] (no title)" ]] || fail "(no title) にならない: $(line_of '-work-beta/notitle.jsonl')"

# ⑤ 壊れた JSON 行があっても落ちず、壊れる前の行からタイトルが取れる
[[ "$(line_of '-work-beta/broken.jsonl')" == "[beta] before broken" ]] || fail "壊れた行を含むセッションが正しく出ない: $(line_of '-work-beta/broken.jsonl')"

[[ "$list_output" != *"/memory/"* ]] || fail "memory ディレクトリが一覧に含まれる"

# --- claude-session-preview ---
preview_file="${TMP_ROOT}/preview.jsonl"
cat >"$preview_file" <<'JSONL'
{"type":"user","timestamp":"2026-04-01T10:00:00Z","gitBranch":"feature/x","message":{"content":"<system-reminder>hidden</system-reminder>please fix the bug"}}
not json at all
{"type":"assistant","timestamp":"2026-04-02T10:00:00Z","message":{"content":[{"type":"text","text":"I will fix it"},{"type":"tool_use","name":"Read","input":{"file_path":"/repo/src/main.go"}},{"type":"tool_use","name":"Bash","input":{"command":"go test ./..."}}]}}
JSONL

preview_output="$(python3 "${REPO_DIR}/bin/claude-session-preview" "$preview_file")"

# user / assistant の発言が整形されて出る(タグは除去)
expected_user="$(printf '%s\n' '--- User ---' 'please fix the bug')"
[[ "$preview_output" == *"$expected_user"* ]] || fail "user 発言が整形されない: $preview_output"
expected_assistant="$(printf '%s\n' '--- Assistant ---' 'I will fix it')"
[[ "$preview_output" == *"$expected_assistant"* ]] || fail "assistant 発言が整形されない: $preview_output"
[[ "$preview_output" == *"[Read main.go, Bash go test ./...]"* ]] || fail "ツール呼び出しが要約されない: $preview_output"
[[ "$preview_output" != *"hidden"* ]] || fail "system-reminder のタグ内が除去されない"

# 壊れた行を読み飛ばし、集計が最後まで出る
[[ "$preview_output" == *"Branch: feature/x  Period: 2026-04-01 ~ 2026-04-02  User messages: 1"* ]] || fail "壊れた行の後の集計が正しくない: $preview_output"

echo "claude-session tests passed"
