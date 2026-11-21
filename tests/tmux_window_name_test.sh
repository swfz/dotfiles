#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WINDOW_NAME="${REPO_DIR}/bin/tmux-window-name"
GIT_ROOT_NAME="${REPO_DIR}/bin/tmux-git-root-name"
# macOS の /var -> /private/var のような symlink を含むパスでは、サブディレクトリから実行すると
# bin/tmux-window-name が linked worktree と誤判定するため、実パスに解決しておく
TMP_ROOT="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$TMP_ROOT"' EXIT

# 一時ディレクトリより上の git リポジトリを拾わないようにし、実行環境の git 設定にも依存させない
export GIT_CEILING_DIRECTORIES="$TMP_ROOT"
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
unset GIT_DIR GIT_WORK_TREE

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# $1: 期待値, $2: ケース名, 以降: 実行するコマンド
expect_output() {
  local expected="$1" name="$2" actual
  shift 2
  actual="$("$@")" || fail "${name}: 終了コードが 0 でない"
  [ "$actual" = "$expected" ] || fail "${name}: '${expected}' でない: '${actual}'"
}

# --- 状態の準備 ---
# plain: git 管理外 / myrepo: 通常リポジトリ(main ブランチ + サブディレクトリ)/ wt-feature: myrepo の linked worktree
mkdir -p "${TMP_ROOT}/plain" "${TMP_ROOT}/myrepo/sub/dir"
git -C "${TMP_ROOT}/myrepo" init -q -b main
git -C "${TMP_ROOT}/myrepo" commit -q --allow-empty -m init
git -C "${TMP_ROOT}/myrepo" worktree add -q -b feature "${TMP_ROOT}/wt-feature"
git -C "${TMP_ROOT}/myrepo" clone -q "${TMP_ROOT}/myrepo" "${TMP_ROOT}/detached"
git -C "${TMP_ROOT}/detached" checkout -q --detach

# --- tmux-window-name ---
# git 管理外: ディレクトリ名だけ
expect_output "plain" "管理外" sh "$WINDOW_NAME" "${TMP_ROOT}/plain"
expect_output "🐚plain" "管理外 + 絵文字" sh "$WINDOW_NAME" "${TMP_ROOT}/plain" "🐚"

# 通常リポジトリ: repo:branch。サブディレクトリからでもリポジトリ名になる
expect_output "myrepo:main" "通常リポジトリ" sh "$WINDOW_NAME" "${TMP_ROOT}/myrepo"
expect_output "myrepo:main" "通常リポジトリのサブディレクトリ" sh "$WINDOW_NAME" "${TMP_ROOT}/myrepo/sub/dir"
git -C "${TMP_ROOT}/myrepo" switch -q -c topic/x
expect_output "myrepo:topic/x" "ブランチ切り替え後" sh "$WINDOW_NAME" "${TMP_ROOT}/myrepo"
git -C "${TMP_ROOT}/myrepo" switch -q main

# detached HEAD: ブランチ名の代わりに detached
expect_output "detached:detached" "detached HEAD" sh "$WINDOW_NAME" "${TMP_ROOT}/detached"

# linked worktree: main_repo:worktree ディレクトリ名(ブランチ名ではない)
expect_output "myrepo:wt-feature" "linked worktree" sh "$WINDOW_NAME" "${TMP_ROOT}/wt-feature"

# 絵文字プレフィックス(通常リポジトリ / linked worktree)
expect_output "🚀myrepo:main" "通常リポジトリ + 絵文字" sh "$WINDOW_NAME" "${TMP_ROOT}/myrepo" "🚀"
expect_output "🚀myrepo:wt-feature" "linked worktree + 絵文字" sh "$WINDOW_NAME" "${TMP_ROOT}/wt-feature" "🚀"

# 引数なし: カレントディレクトリを対象にする
expect_output "myrepo:main" "引数なし" sh -c 'cd "$1" && sh "$2"' _ "${TMP_ROOT}/myrepo" "$WINDOW_NAME"

# 存在しないパス: 何も出さず exit 1
set +e
out="$(sh "$WINDOW_NAME" "${TMP_ROOT}/missing" 2>&1)"
code=$?
set -e
[ "$code" -eq 1 ] || fail "存在しないパス: 終了コードが 1 でない: ${code}"
[ -z "$out" ] || fail "存在しないパス: 出力が空でない: '${out}'"

# --- tmux-git-root-name ---
# git 管理下: サブディレクトリからでも git ルートの basename
expect_output "myrepo" "git ルート" sh "$GIT_ROOT_NAME" "${TMP_ROOT}/myrepo/sub/dir"
expect_output "wt-feature" "linked worktree のルート" sh "$GIT_ROOT_NAME" "${TMP_ROOT}/wt-feature"

# git 管理外: 指定ディレクトリの basename
expect_output "plain" "git 管理外" sh "$GIT_ROOT_NAME" "${TMP_ROOT}/plain"

echo "tmux-window-name tests passed"
