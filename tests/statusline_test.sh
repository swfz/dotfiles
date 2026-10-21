#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

# git リポジトリでない作業ディレクトリ。上位に辿って実リポジトリを拾わないよう止める
WORK_DIR="${TMP_ROOT}/work"
mkdir -p "$WORK_DIR" "${TMP_ROOT}/home"
export GIT_CEILING_DIRECTORIES="$TMP_ROOT"

run_statusline() {
  (cd "$WORK_DIR" && HOME="${TMP_ROOT}/home" bash "${REPO_DIR}/claude/statusline.sh")
}

strip_ansi() {
  sed -E $'s/\033\\[[0-9;]*m//g'
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# --- 全フィールドあり ---
full_input=$(
  cat <<JSON
{
  "workspace": {"current_dir": "${WORK_DIR}"},
  "model": {"display_name": "Opus Test"},
  "cost": {"total_cost_usd": 1.23456},
  "context_window": {
    "used_percentage": 42,
    "current_usage": {"cache_read_input_tokens": 9000, "cache_creation_input_tokens": 1000, "input_tokens": 1500, "output_tokens": 250}
  },
  "rate_limits": {
    "five_hour": {"used_percentage": 30, "resets_at": $(($(date +%s) + 7200))},
    "seven_day": {"used_percentage": 70, "resets_at": $(($(date +%s) + 86400 * 2))}
  }
}
JSON
)
full_raw="$(printf '%s' "$full_input" | run_statusline)"
full="$(printf '%s' "$full_raw" | strip_ansi)"

[[ "$full" == *"Opus Test"* ]] || fail "モデル名が出力されない: $full"
[[ "$full" == *"\$1.2346"* ]] || fail "コストが小数 4 桁で出力されない: $full"
[[ "$full" == *"ctx "*" 42%"* ]] || fail "コンテキスト使用率が出力されない: $full"
[[ "$full" == *"cache: 90% (9K hit)"* ]] || fail "キャッシュ効率が出力されない: $full"
[[ "$full" == *"in:2K out:250"* ]] || fail "トークン数が出力されない: $full"
[[ "$full" == *"5h "*" 30%"* ]] || fail "5h のレート制限が出力されない: $full"
[[ "$full" == *"7d "*" 70%"*"(1d23h"* || "$full" == *"7d "*" 70%"*"(2d0h"* ]] || fail "7d のレート制限と残り時間が出力されない: $full"
[[ "$(printf '%s\n' "$full_raw" | wc -l | tr -d ' ')" == "2" ]] || fail "rate_limits があるのに 2 行にならない: $full"

# --- フィールド欠落 ---
empty="$(printf '{}' | run_statusline | strip_ansi)"
[[ "$empty" != *"ctx"* ]] || fail "used_percentage が無いのに ctx が出る: $empty"
[[ "$empty" != *"5h"* && "$empty" != *"7d"* ]] || fail "rate_limits が無いのにレート制限が出る: $empty"
[[ "$empty" != *"\$"* ]] || fail "cost が無いのにコストが出る: $empty"

no_rate="$(printf '{"model":{"display_name":"Sonnet Test"},"context_window":{"used_percentage":10}}' | run_statusline | strip_ansi)"
[[ "$no_rate" == *"Sonnet Test"* ]] || fail "rate_limits 無しでモデル名が出ない: $no_rate"
[[ "$no_rate" == *"ctx "*" 10%"* ]] || fail "rate_limits 無しで ctx が出ない: $no_rate"
[[ "$no_rate" != *"5h"* && "$no_rate" != *"7d"* ]] || fail "rate_limits 無しでレート制限が出る: $no_rate"

# --- 使用率の境界で _gradient の色が切り替わる ---
ctx_color() {
  printf '{"context_window":{"used_percentage":%s}}' "$1" | run_statusline
}
[[ "$(ctx_color 49)" == *$'\033[38;2;249;200;80m'* ]] || fail "49% が緑〜黄の系統(R=249)にならない"
[[ "$(ctx_color 50)" == *$'\033[38;2;255;200;60m'* ]] || fail "50% で赤系統(R=255, G=200)に切り替わらない"
[[ "$(ctx_color 100)" == *$'\033[38;2;255;0;60m'* ]] || fail "100% が赤(G=0)にならない"
[[ "$(ctx_color 100 | strip_ansi)" == *"██████████ 100%"* ]] || fail "100% でバーが全て埋まらない"

echo "statusline tests passed"
