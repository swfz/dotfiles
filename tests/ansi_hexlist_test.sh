#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

run() {
  COLUMNS=240 TERM=xterm-256color bash "$REPO_DIR/bin/ansi_hexlist" "$@" \
    | sed $'s/\033\\[[0-9;]*m//g'
}

assert_contains() {
  case "$1" in
    *"$2"*) ;;
    *)
      printf 'assertion failed: output does not contain %s\n' "$2" >&2
      exit 1
      ;;
  esac
}

single_output="$(run '#1a1a00')"
assert_contains "$single_output" '#1a1a00 (r=26, g=26, b=0)'

multiple_output="$(run '#000000' '#ffffff')"
test "$(printf '%s\n' "$multiple_output" | grep -c '(r=')" = 2

edge_output="$(run -n '#fffffe' -s 5 -w 3)"
if printf '%s\n' "$edge_output" | grep -Eq '^[[:space:]]+[RGB]:.*(^|[[:space:]])(-[0-9]+|256)([[:space:]]|$)'; then
  echo 'neighborhood contains an RGB value outside 0..255' >&2
  exit 1
fi
assert_contains "$edge_output" 'R: 240 245 250 255'
assert_contains "$edge_output" 'B: 239 244 249 254 255'

usage_output="$(run -s 255 -w invalid)"
assert_contains "$usage_output" 'Usage: ansi_hexlist'

echo 'ansi_hexlist tests passed'
