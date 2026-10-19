#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

FIXTURE_DIR="${TMP_ROOT}/dotfiles"
CLAUDE_DIR="${TMP_ROOT}/home/.claude"
AGENTS_DIR="${TMP_ROOT}/home/.agents"
CODEX_DIR="${TMP_ROOT}/home/.codex"

mkdir -p "${FIXTURE_DIR}/claude/skills/example" "${FIXTURE_DIR}/claude/rules"
mkdir -p "${FIXTURE_DIR}/claude/skills/remove-me"
mkdir -p "${FIXTURE_DIR}/codex/agents" "${AGENTS_DIR}/skills/conflict"
printf '%s\n' '---' 'name: example' 'description: test skill' '---' >"${FIXTURE_DIR}/claude/skills/example/SKILL.md"
printf '%s\n' '---' 'name: remove-me' 'description: removal test' '---' >"${FIXTURE_DIR}/claude/skills/remove-me/SKILL.md"
printf '%s\n' '# shell rules' >"${FIXTURE_DIR}/claude/rules/shell.md"
printf '%s\n' 'name = "example"' 'description = "test"' 'developer_instructions = "test"' >"${FIXTURE_DIR}/codex/agents/example.toml"
mkdir -p "${FIXTURE_DIR}/claude/skills/conflict"
printf '%s\n' 'keep me' >"${AGENTS_DIR}/skills/conflict/existing.txt"

run_ccsync() {
  env \
    CCSYNC_DOTFILES_DIR="${FIXTURE_DIR}" \
    CCSYNC_CLAUDE_DIR="${CLAUDE_DIR}" \
    CCSYNC_AGENTS_DIR="${AGENTS_DIR}" \
    CCSYNC_CODEX_DIR="${CODEX_DIR}" \
    "${REPO_DIR}/bin/ccsync.sh" "$@"
}

output="$(run_ccsync link 2>&1)"

[[ "$(readlink "${CLAUDE_DIR}/skills/example")" == "${FIXTURE_DIR}/claude/skills/example" ]]
[[ "$(readlink "${AGENTS_DIR}/skills/example")" == "${FIXTURE_DIR}/claude/skills/example" ]]
[[ "$(readlink "${CLAUDE_DIR}/rules/shell.md")" == "${FIXTURE_DIR}/claude/rules/shell.md" ]]
[[ "$(readlink "${CODEX_DIR}/agents/example.toml")" == "${FIXTURE_DIR}/codex/agents/example.toml" ]]
[[ -f "${AGENTS_DIR}/skills/conflict/existing.txt" ]]
[[ "$output" == *"already exists (skipping)"* ]]

second_output="$(run_ccsync link 2>&1)"
[[ "$second_output" == *"0 linked"* ]]

list_output="$(run_ccsync list)"
[[ "$list_output" == *"Codex skill example"*"[linked]"* ]]
[[ "$list_output" == *"Codex agents/example.toml"*"[linked]"* ]]

run_ccsync remove skills/remove-me >/dev/null
[[ -d "${CLAUDE_DIR}/skills/remove-me" && ! -L "${CLAUDE_DIR}/skills/remove-me" ]]
[[ ! -e "${AGENTS_DIR}/skills/remove-me" && ! -L "${AGENTS_DIR}/skills/remove-me" ]]
[[ ! -e "${FIXTURE_DIR}/claude/skills/remove-me" ]]

echo "ccsync tests passed"
