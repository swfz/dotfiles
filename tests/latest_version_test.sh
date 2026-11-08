#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BIN_DIR="${REPO_DIR}/.github/workflows/bin"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

# ネットワークに出ないよう curl をスタブにする。
# スタブは最後の引数(URL)を CURL_LOG に書き、CURL_FIXTURE の内容をそのまま返す
STUB_BIN="${TMP_ROOT}/bin"
mkdir -p "$STUB_BIN"
cat >"${STUB_BIN}/curl" <<'STUB'
#!/bin/bash
echo "${!#}" >"$CURL_LOG"
cat "$CURL_FIXTURE"
STUB
chmod +x "${STUB_BIN}/curl"

export CURL_LOG="${TMP_ROOT}/curl.log"
export CURL_FIXTURE="${TMP_ROOT}/fixture.json"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# $1: スクリプトの種類 $2: リポジトリ $3: 返す JSON $4: 期待する出力 $5: 期待する URL $6: ケース名
expect_latest() {
  local actual url
  printf '%s' "$3" >"$CURL_FIXTURE"
  rm -f "$CURL_LOG"
  actual="$(PATH="${STUB_BIN}:${PATH}" bash "${BIN_DIR}/latest-version-$1.sh" "$2")"
  [ "$actual" = "$4" ] || fail "$6: '$4' でない: '${actual}'"
  url="$(cat "$CURL_LOG")"
  [ "$url" = "$5" ] || fail "$6: URL が '$5' でない: '${url}'"
  echo "ok: $6"
}

releases() {
  printf 'https://api.github.com/repos/%s/releases' "$1"
}

tags() {
  printf 'https://api.github.com/repos/%s/tags' "$1"
}

# normal: 先頭の name から v を除く
expect_latest normal peco/peco '[{"name":"v0.5.11"},{"name":"v0.5.10"}]' '0.5.11' "$(releases peco/peco)" 'normal: 先頭の v を除く'
expect_latest normal foo/bar '[{"name":"1.2.3"},{"name":"v1.2.2"}]' '1.2.3' "$(releases foo/bar)" 'normal: v が無ければそのまま'

# prefix: 接頭辞を除き、数字のみのバージョンの先頭を返す
expect_latest prefix tmux/tmux '[{"name":"tmux 3.8-rc"},{"name":"tmux 3.7c"},{"name":"tmux 3.7"}]' '3.7' "$(releases tmux/tmux)" 'prefix: rc と英字付きを除く'
expect_latest prefix jqlang/jq '[{"name":"jq 1.8.1"},{"name":"jq 1.8.0"}]' '1.8.1' "$(releases jqlang/jq)" 'prefix: jq の接頭辞を除く'
expect_latest prefix jpmens/jo '[{"name":"Release v1.9"},{"name":"Jo 1.8"}]' '1.9' "$(releases jpmens/jo)" 'prefix: Release v の接頭辞を除く'
expect_latest prefix jpmens/jo '[{"name":"Jo 1.8"}]' '1.8' "$(releases jpmens/jo)" 'prefix: Jo の接頭辞を除く'

# beta-rc: rc / beta を含む name を除く
expect_latest beta-rc foo/bar '[{"name":"v2.0.0-rc1"},{"name":"v2.0.0-beta"},{"name":"v1.9.0"}]' 'v1.9.0' "$(releases foo/bar)" 'beta-rc: rc と beta を除く'
expect_latest beta-rc foo/bar '[{"name":"v1.9.1"},{"name":"v1.9.0"}]' 'v1.9.1' "$(releases foo/bar)" 'beta-rc: 正式版はそのまま先頭'

# from-tag: rc / test / real を含む tag を除き、v と zsh- を除く
expect_latest from-tag zsh-users/zsh '[{"name":"zsh-5.9.1-test-2"},{"name":"zsh-5.9.1-rc"},{"name":"zsh-5.9-real"},{"name":"zsh-5.9"}]' '5.9' "$(tags zsh-users/zsh)" 'from-tag: test / rc / real を除き zsh- を除く'
expect_latest from-tag foo/bar '[{"name":"v1.4.0"},{"name":"v1.3.0"}]' '1.4.0' "$(tags foo/bar)" 'from-tag: v を除く'

echo "latest-version tests passed"
