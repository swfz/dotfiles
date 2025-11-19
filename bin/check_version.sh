#!/bin/bash

YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)
VARS_FILE="$HOME/dotfiles/ansible/versions_vars.yml"

check_version() {
  local name="$1"
  local cmd_str="$2"
  # 第3引数があればそれをキーに、なければデフォルト (.name_version)
  local yaml_key=".${3:-${name}_version}"

  local local_v
  local_v=$(eval "$cmd_str" 2>/dev/null)

  # 取得結果が空文字なら「未インストール」または「実行失敗」とみなす
  if [ -z "$local_v" ]; then
    echo "${YELLOW}WARN${RESET} missing: $name (not installed or command failed)"
    return
  fi

  # Ansible変数の期待値を取得
  local expect_v
  expect_v=$(yq e "$yaml_key" "$VARS_FILE")
  expect_v="${expect_v#v}"

  if [ "$local_v" != "$expect_v" ]; then
    echo "${YELLOW}WARN${RESET} missing: $name $expect_v. local: $local_v"
  fi
}

# git
# e.g) "git version 2.49.0"
check_version "git" "git --version | cut -d ' ' -f 3"

# actionlint
# e.g) 1.7.7
# installed by downloading from release page
# built with go1.23.4 compiler for linux/amd64
check_version "actionlint" "actionlint --version | head -n 1"

# reviewdog
# e.g) 0.20.3
check_version "reviewdog" "reviewdog --version"

# gh
# e.g) gh version 2.83.0 (2025-11-04)
# https://github.com/cli/cli/releases/tag/v2.83.0
check_version "gh" "gh --version | head -n 1 | cut -d ' ' -f 3"

# mise
# e.g) 2025.10.11 linux-x64 (2025-10-18)
check_version "mise" "mise --version | cut -d ' ' -f 1"

