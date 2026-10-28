#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET="${REPO_DIR}/bin/notify"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

# 実際の通知を出さないよう、uname / osascript / powershell.exe をスタブにする。
# uname は UNAME_STUB の値を返し、通知側のスタブは受け取った引数を 1 行ずつ CALL_LOG に書く。
# bin/notify は /tmp/notify-log.txt に追記するが、内容は検証せず削除もしない
STUB_BIN="${TMP_ROOT}/bin"
mkdir -p "$STUB_BIN"
cat >"${STUB_BIN}/uname" <<'STUB'
#!/bin/bash
echo "$UNAME_STUB"
STUB
cat >"${STUB_BIN}/osascript" <<'STUB'
#!/bin/bash
printf '%s\n' "$@" >"$CALL_LOG"
STUB
cp "${STUB_BIN}/osascript" "${TMP_ROOT}/powershell.exe"
chmod +x "${STUB_BIN}/uname" "${STUB_BIN}/osascript" "${TMP_ROOT}/powershell.exe"

export CALL_LOG="${TMP_ROOT}/call.log"
POWERSHELL_STUB="${TMP_ROOT}/powershell.exe"
NOTIFY_PS1_PATH='C:\notify.ps1'

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# パイプ入力のないケースは stdin を /dev/null にし、実行環境の stdin がパイプでも結果が変わらないようにする
run_linux() {
  rm -f "$CALL_LOG"
  PATH="${STUB_BIN}:${PATH}" UNAME_STUB=Linux POWERSHELL_EXE="$POWERSHELL_STUB" NOTIFY_PS1="$NOTIFY_PS1_PATH" \
    bash "$TARGET" "$@"
}

run_darwin() {
  rm -f "$CALL_LOG"
  PATH="${STUB_BIN}:${PATH}" UNAME_STUB=Darwin bash "$TARGET" "$@"
}

# powershell.exe に渡った -Title / -Prompt の値を返す
ps_arg() {
  grep -A1 -xF -- "$1" "$CALL_LOG" | tail -n 1
}

expect_ps() {
  local title prompt
  title="$(ps_arg -Title)"
  prompt="$(ps_arg -Prompt)"
  [ "$title" = "$1" ] || fail "$3: title が '$1' でない: '${title}'"
  [ "$prompt" = "$2" ] || fail "$3: message が '$2' でない: '${prompt}'"
}

# --- Linux で必要な環境変数が未設定: 不足した変数名を出して終了コード 1、通知は呼ばない ---
for missing in POWERSHELL_EXE NOTIFY_PS1; do
  rm -f "$CALL_LOG"
  set +e
  out="$(PATH="${STUB_BIN}:${PATH}" UNAME_STUB=Linux POWERSHELL_EXE="$POWERSHELL_STUB" NOTIFY_PS1="$NOTIFY_PS1_PATH" \
    env -u "$missing" bash "$TARGET" title message </dev/null 2>&1)"
  status=$?
  set -e
  [ "$status" -eq 1 ] || fail "${missing} 未設定で終了コードが 1 でない: ${status}"
  [[ "$out" == *"require environment variable ${missing}"* ]] || fail "${missing} 未設定のメッセージが無い: ${out}"
  [[ "$out" == *"usage:"* ]] || fail "${missing} 未設定で usage が出ない: ${out}"
  [ ! -e "$CALL_LOG" ] || fail "${missing} 未設定なのに通知が呼ばれた"
done

# --- 未対応プラットフォーム: 終了コード 1 ---
rm -f "$CALL_LOG"
set +e
out="$(PATH="${STUB_BIN}:${PATH}" UNAME_STUB=FreeBSD bash "$TARGET" title message </dev/null 2>&1)"
status=$?
set -e
[ "$status" -eq 1 ] || fail "未対応プラットフォームで終了コードが 1 でない: ${status}"
[ "$out" = "unsupported platform: FreeBSD" ] || fail "未対応プラットフォームのメッセージが違う: ${out}"
[ ! -e "$CALL_LOG" ] || fail "未対応プラットフォームなのに通知が呼ばれた"

# --- 引数とパイプ入力の組み合わせ(Linux) ---
# message は echo の改行も空白に変わるため、末尾に空白が 1 つ付く
run_linux </dev/null
expect_ps "WSL Notification" "Task Completed " "引数なし"
grep -qxF -- "$NOTIFY_PS1_PATH" "$CALL_LOG" || fail "NOTIFY_PS1 が -File に渡らない: $(cat "$CALL_LOG")"

run_linux "only message" </dev/null
expect_ps "WSL Notification" "only message " "引数 1 つ"

run_linux "my title" "my message" </dev/null
expect_ps "my title" "my message " "引数 2 つ"

echo "from pipe" | run_linux "pipe title"
expect_ps "pipe title" "from pipe " "パイプ入力 + タイトル"

echo "from pipe" | run_linux
expect_ps "WSL Notification" "from pipe " "パイプ入力のみ"

# --- クォートのエスケープと改行の置換 ---
printf 'line1\nsay "hi"' | run_linux 'a "quoted" title'
expect_ps 'a \"quoted\" title' 'line1 say \"hi\" ' "エスケープ"

# --- macOS: 既定タイトルと osascript に渡るスクリプト ---
run_darwin </dev/null
[ "$(cat "$CALL_LOG")" = $'-e\ndisplay notification "Task Completed " with title "Notification" sound name "default"' ] \
  || fail "macOS の既定値で osascript の引数が違う: $(cat "$CALL_LOG")"

run_darwin 'mac "title"' "mac message" </dev/null
[ "$(sed -n 2p "$CALL_LOG")" = 'display notification "mac message " with title "mac \"title\"" sound name "default"' ] \
  || fail "macOS で osascript の引数が違う: $(cat "$CALL_LOG")"

echo "notify tests passed"
