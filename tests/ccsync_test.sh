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
APM_LOCK="${TMP_ROOT}/home/.apm/apm.lock.yaml"

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
    CCSYNC_APM_LOCK="${APM_LOCK}" \
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
[[ "$list_output" == *"skills/example"*"dotfiles"*"[linked, codex: linked]"* ]]
[[ "$list_output" == *"skills/conflict"*"dotfiles"*"[linked, codex: not linked (exists)]"* ]]
[[ "$list_output" == *"Codex agents/example.toml"*"dotfiles"*"[linked]"* ]]

run_ccsync remove skills/remove-me >/dev/null
[[ -d "${CLAUDE_DIR}/skills/remove-me" && ! -L "${CLAUDE_DIR}/skills/remove-me" ]]
[[ ! -e "${AGENTS_DIR}/skills/remove-me" && ! -L "${AGENTS_DIR}/skills/remove-me" ]]
[[ ! -e "${FIXTURE_DIR}/claude/skills/remove-me" ]]

mkdir -p "${CLAUDE_DIR}/skills/from-apm" "${CLAUDE_DIR}/skills/handmade" "$(dirname "$APM_LOCK")" "${TMP_ROOT}/memo/private"
ln -s "${TMP_ROOT}/memo/private" "${CLAUDE_DIR}/skills/private"
printf '%s\n' 'dependencies:' '- name: from-apm' '  deployed_files:' '  - .claude/skills/from-apm' '  - .claude/skills/from-apm/SKILL.md' >"$APM_LOCK"

list_output="$(run_ccsync list)"
[[ "$list_output" == *"skills/from-apm"*"apm"* ]]
[[ "$list_output" == *"skills/handmade"*"unmanaged"* ]]
[[ "$list_output" == *"skills/private"*"external"*"-> ${TMP_ROOT}/memo/private"* ]]

unmanaged_output="$(run_ccsync unmanaged)"
[[ "$unmanaged_output" == *"skills/handmade"*"unmanaged"* ]]
[[ "$unmanaged_output" != *"from-apm"* ]]
[[ "$unmanaged_output" != *"skills/private"* ]]
[[ "$unmanaged_output" != *"skills/example"* ]]

echo "ccsync tests passed"
