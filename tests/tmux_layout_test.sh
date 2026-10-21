#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

FAKE_BIN="${TMP_ROOT}/bin"
LAYOUT_DIR="${TMP_ROOT}/home/.config/tmux-layout"
mkdir -p "$FAKE_BIN" "$LAYOUT_DIR"

# 実 tmux の代わりに、呼び出し引数を FAKE_TMUX_LOG に記録して固定の応答を返す
cat >"${FAKE_BIN}/tmux" <<'EOF'
#!/bin/bash
echo "$*" >> "$FAKE_TMUX_LOG"
case "$1" in
  display-message)
    case "${!#}" in
      '#{pane_current_path}') echo /work ;;
      '#{pane_id}') echo '%0' ;;
      '#{pane_width}') echo "$FAKE_PANE_WIDTH" ;;
      '#{pane_height}') echo "$FAKE_PANE_HEIGHT" ;;
    esac
    ;;
  split-window)
    n=$(($(grep -c '^split-window' "$FAKE_TMUX_LOG")))
    echo "%${n}"
    ;;
  list-panes)
    printf '%b' "$FAKE_LIST_PANES"
    ;;
esac
EOF
chmod +x "${FAKE_BIN}/tmux"

run() {
  : >"${TMP_ROOT}/tmux.log"
  env \
    PATH="${FAKE_BIN}:${PATH}" \
    HOME="${TMP_ROOT}/home" \
    TMUX="${FAKE_TMUX_ENV-/tmp/tmux-test,1,0}" \
    FAKE_TMUX_LOG="${TMP_ROOT}/tmux.log" \
    FAKE_PANE_WIDTH="${FAKE_PANE_WIDTH:-101}" \
    FAKE_PANE_HEIGHT="${FAKE_PANE_HEIGHT:-40}" \
    FAKE_LIST_PANES="${FAKE_LIST_PANES:-}" \
    "${REPO_DIR}/bin/$1" "${@:2}"
}

# macOS の bash 3.2 は set -e でも [[ ]] の失敗で止まらないため、明示的に exit する
assert_eq() {
  if [ "$1" != "$2" ]; then
    printf 'assertion failed:\n  actual:   %s\n  expected: %s\n' "$1" "$2" >&2
    exit 1
  fi
}

assert_contains() {
  case "$1" in
    *"$2"*) ;;
    *)
      printf 'assertion failed: %s\n  does not contain: %s\n' "$1" "$2" >&2
      exit 1
      ;;
  esac
}

assert_fails() {
  if run "$@" >/dev/null 2>&1; then
    echo "expected failure: $*" >&2
    exit 1
  fi
}

tmux_log() {
  cat "${TMP_ROOT}/tmux.log"
}

layout_value() {
  yq -r "$1" "${LAYOUT_DIR}/$2.yml"
}

# --- tm ---

cat >"${LAYOUT_DIR}/two.yml" <<'EOF'
direction: horizontal
panes:
  - width: 50%
    command: vim
  - width: 50%
EOF

# 引数は 1 個まで
assert_fails tm two extra
# 設定ファイルが無い
assert_fails tm missing
# tmux の外
FAKE_TMUX_ENV='' assert_fails tm two

# 幅 101 からセパレータ 1 を除いた 100 を 50%/50% に分ける
run tm two
assert_contains "$(tmux_log)" "split-window -h -t %0 -l 50 -c /work -P -F #{pane_id}"
# command を持つペインだけに send-keys が出る
assert_eq "$(tmux_log | grep -c '^send-keys')" "1"
assert_contains "$(tmux_log)" "send-keys -t %0 vim Enter"
assert_eq "$(tmux_log | tail -n 1)" "select-pane -t %0"

# 端数は切り捨て、残りは最後のペインに寄せる(高さ 40 - 1 = 39 → 11 / 28)
cat >"${LAYOUT_DIR}/vertical.yml" <<'EOF'
direction: vertical
panes:
  - height: 30%
  - height: 70%
EOF
run tm vertical
assert_contains "$(tmux_log)" "split-window -v -t %0 -l 28 "

# 計算結果が 2 未満でも最小サイズ 2 を保証する(100 - 99 = 1 → 2)
cat >"${LAYOUT_DIR}/tiny.yml" <<'EOF'
direction: horizontal
panes:
  - size: 99%
  - size: 1%
EOF
run tm tiny
assert_contains "$(tmux_log)" "split-window -h -t %0 -l 2 "

# --- tms ---

# 引数は 1 個まで
assert_fails tms a b
# tmux の外
FAKE_TMUX_ENV='' assert_fails tms saved

# 左右に並んだ 2 ペインを 50%/50% の horizontal として保存する
FAKE_LIST_PANES='0\t0\t50\t40\n51\t0\t50\t40\n' run tms saved >/dev/null
assert_eq "$(layout_value '.direction' saved)" "horizontal"
assert_eq "$(layout_value '.panes | length' saved)" "2"
assert_eq "$(layout_value '.panes[0].width' saved)" "50%"
assert_eq "$(layout_value '.panes[1].width' saved)" "50%"

# 上下に並んだ 2 ペインは vertical になり、既存ファイルの command を引き継ぐ
printf '%s\n' 'direction: vertical' 'panes:' '  - command: htop' '  - command: ""' >"${LAYOUT_DIR}/keep.yml"
FAKE_LIST_PANES='0\t0\t100\t10\n0\t11\t100\t30\n' run tms keep >/dev/null
assert_eq "$(layout_value '.direction' keep)" "vertical"
assert_eq "$(layout_value '.panes[0].height' keep)" "25%"
assert_eq "$(layout_value '.panes[1].height' keep)" "75%"
assert_eq "$(layout_value '.panes[0].command' keep)" "htop"

# 1 ペインだけなら command だけのノードになる
FAKE_LIST_PANES='0\t0\t100\t40\n' run tms single >/dev/null
assert_eq "$(layout_value '.command' single)" ""
assert_eq "$(layout_value 'has("direction")' single)" "false"

echo "tmux layout tests passed"
