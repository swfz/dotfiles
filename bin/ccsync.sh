#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLAUDE_DIR="${HOME}/.claude"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args]

Commands:
  add <type>/<name>      Add a Claude asset to dotfiles management
  link                   Create symlinks for all managed assets
  list                   List managed assets and their status
  remove <type>/<name>   Remove an asset from dotfiles management

Examples:
  $(basename "$0") add skills/commit
  $(basename "$0") link
  $(basename "$0") list
  $(basename "$0") remove skills/commit
EOF
  exit 1
}

cmd_add() {
  local target="$1"
  local type="${target%%/*}"
  local name="${target#*/}"

  if [[ -z "$type" || -z "$name" || "$type" == "$name" ]]; then
    echo "Error: Invalid format. Use <type>/<name> (e.g., skills/commit)" >&2
    exit 1
  fi

  local src="${CLAUDE_DIR}/${type}/${name}"
  local dest="${DOTFILES_DIR}/claude/${type}/${name}"

  if [[ ! -d "$src" ]]; then
    echo "Error: Source directory does not exist: ${src}" >&2
    exit 1
  fi

  if [[ -L "$src" ]]; then
    echo "Error: ${src} is already a symlink" >&2
    exit 1
  fi

  if [[ -d "$dest" ]]; then
    echo "Error: Destination already exists: ${dest}" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dest")"
  cp -R "$src" "$dest"
  rm -rf "$src"
  ln -s "$dest" "$src"

  echo "Added: ${target}"
  echo "  Copied: ${src} -> ${dest}"
  echo "  Symlinked: ${src} -> ${dest}"
}

cmd_link() {
  local dotfiles_claude="${DOTFILES_DIR}/claude"
  local linked=0
  local skipped=0
  local warned=0

  for type_dir in "${dotfiles_claude}"/*/; do
    [[ -d "$type_dir" ]] || continue
    local type
    type="$(basename "$type_dir")"

    for asset_dir in "${type_dir}"/*/; do
      [[ -d "$asset_dir" ]] || continue
      local name
      name="$(basename "$asset_dir")"
      local target="${CLAUDE_DIR}/${type}/${name}"
      local src="${dotfiles_claude}/${type}/${name}"

      if [[ -L "$target" ]]; then
        local current_link
        current_link="$(readlink "$target")"
        if [[ "$current_link" == "$src" ]]; then
          skipped=$((skipped + 1))
          continue
        fi
        echo "Warning: ${target} is a symlink to different location: ${current_link}" >&2
        warned=$((warned + 1))
        continue
      fi

      if [[ -d "$target" ]]; then
        echo "Warning: ${target} exists as a regular directory (skipping)" >&2
        warned=$((warned + 1))
        continue
      fi

      mkdir -p "$(dirname "$target")"
      ln -s "$src" "$target"
      echo "Linked: ${type}/${name}"
      linked=$((linked + 1))
    done
  done

  echo ""
  echo "Done: ${linked} linked, ${skipped} skipped, ${warned} warnings"
}

cmd_list() {
  local dotfiles_claude="${DOTFILES_DIR}/claude"
  local found=0

  for type_dir in "${dotfiles_claude}"/*/; do
    [[ -d "$type_dir" ]] || continue
    local type
    type="$(basename "$type_dir")"

    for asset_dir in "${type_dir}"/*/; do
      [[ -d "$asset_dir" ]] || continue
      local name
      name="$(basename "$asset_dir")"
      local target="${CLAUDE_DIR}/${type}/${name}"
      local src="${dotfiles_claude}/${type}/${name}"
      local status

      if [[ -L "$target" ]]; then
        local current_link
        current_link="$(readlink "$target")"
        if [[ "$current_link" == "$src" ]]; then
          status="linked"
        else
          status="conflict (-> ${current_link})"
        fi
      elif [[ -d "$target" ]]; then
        status="not linked (directory exists)"
      else
        status="not linked"
      fi

      printf "  %-30s %s\n" "${type}/${name}" "[${status}]"
      found=$((found + 1))
    done
  done

  if [[ "$found" -eq 0 ]]; then
    echo "No managed assets found."
  fi
}

cmd_remove() {
  local target="$1"
  local type="${target%%/*}"
  local name="${target#*/}"

  if [[ -z "$type" || -z "$name" || "$type" == "$name" ]]; then
    echo "Error: Invalid format. Use <type>/<name> (e.g., skills/commit)" >&2
    exit 1
  fi

  local dotfiles_path="${DOTFILES_DIR}/claude/${type}/${name}"
  local claude_path="${CLAUDE_DIR}/${type}/${name}"

  if [[ ! -d "$dotfiles_path" ]]; then
    echo "Error: Not managed: ${target}" >&2
    exit 1
  fi

  if [[ -L "$claude_path" ]]; then
    rm "$claude_path"
  fi

  cp -R "$dotfiles_path" "$claude_path"
  rm -rf "$dotfiles_path"

  echo "Removed: ${target}"
  echo "  Restored: ${claude_path}"
  echo "  Deleted: ${dotfiles_path}"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift

case "$command" in
  add)
    [[ $# -lt 1 ]] && usage
    cmd_add "$1"
    ;;
  link)
    cmd_link
    ;;
  list)
    cmd_list
    ;;
  remove)
    [[ $# -lt 1 ]] && usage
    cmd_remove "$1"
    ;;
  *)
    echo "Error: Unknown command: ${command}" >&2
    usage
    ;;
esac
