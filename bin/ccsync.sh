#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="${CCSYNC_DOTFILES_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
CLAUDE_DIR="${CCSYNC_CLAUDE_DIR:-${HOME}/.claude}"
AGENTS_DIR="${CCSYNC_AGENTS_DIR:-${HOME}/.agents}"
CODEX_DIR="${CCSYNC_CODEX_DIR:-${HOME}/.codex}"
ASSET_TYPES=(skills rules agents commands)

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args]

Commands:
  add <type>/<name>      Add a Claude asset to dotfiles management
  link                   Create symlinks for all managed Claude/Codex assets
  list                   List managed assets and their status
  remove <type>/<name>   Remove an asset from dotfiles management
  unmanaged              List assets in ~/.claude not managed by dotfiles

Examples:
  $(basename "$0") add skills/commit
  $(basename "$0") add agents/foo.md
  $(basename "$0") link
  $(basename "$0") list
  $(basename "$0") remove skills/commit
  $(basename "$0") unmanaged
EOF
  exit 1
}

cmd_add() {
  local target="$1"
  local type="${target%%/*}"
  local name="${target#*/}"

  if [[ -z "$type" || -z "$name" || "$type" == "$name" ]]; then
    echo "Error: Invalid format. Use <type>/<name> (e.g., skills/commit, agents/foo.md)" >&2
    exit 1
  fi

  local src="${CLAUDE_DIR}/${type}/${name}"
  local dest="${DOTFILES_DIR}/claude/${type}/${name}"

  if [[ -L "$src" ]]; then
    echo "Error: ${src} is already a symlink" >&2
    exit 1
  fi

  if [[ ! -e "$src" ]]; then
    echo "Error: Source does not exist: ${src}" >&2
    exit 1
  fi

  if [[ -e "$dest" ]]; then
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
  local dotfiles_codex="${DOTFILES_DIR}/codex"
  local linked=0
  local skipped=0
  local warned=0

  for type_dir in "${dotfiles_claude}"/*/; do
    [[ -d "$type_dir" ]] || continue
    local type
    type="$(basename "$type_dir")"

    for asset_path in "${type_dir}"*; do
      [[ -e "$asset_path" ]] || continue
      local name
      name="$(basename "$asset_path")"
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

      if [[ -e "$target" ]]; then
        echo "Warning: ${target} already exists (skipping)" >&2
        warned=$((warned + 1))
        continue
      fi

      mkdir -p "$(dirname "$target")"
      ln -s "$src" "$target"
      echo "Linked (Claude): ${type}/${name}"
      linked=$((linked + 1))
    done
  done

  # Skills use the same open Agent Skills format in Claude Code and Codex.
  # Link each managed skill individually so locally installed Codex skills can
  # coexist in ~/.agents/skills.
  local skills_dir="${dotfiles_claude}/skills"
  if [[ -d "$skills_dir" ]]; then
    for skill_path in "${skills_dir}"/*; do
      [[ -e "$skill_path" ]] || continue
      local name
      name="$(basename "$skill_path")"
      local target="${AGENTS_DIR}/skills/${name}"
      local src="${skills_dir}/${name}"

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

      if [[ -e "$target" ]]; then
        echo "Warning: ${target} already exists (skipping)" >&2
        warned=$((warned + 1))
        continue
      fi

      mkdir -p "$(dirname "$target")"
      ln -s "$src" "$target"
      echo "Linked (Codex skill): ${name}"
      linked=$((linked + 1))
    done
  fi

  # Codex agents use TOML and cannot share Claude Code's Markdown files
  # directly. Link Codex-native wrappers/configuration from dotfiles instead.
  if [[ -d "$dotfiles_codex" ]]; then
    for type_dir in "${dotfiles_codex}"/*/; do
      [[ -d "$type_dir" ]] || continue
      local type
      type="$(basename "$type_dir")"

      for asset_path in "${type_dir}"*; do
        [[ -e "$asset_path" ]] || continue
        local name
        name="$(basename "$asset_path")"
        local target="${CODEX_DIR}/${type}/${name}"
        local src="${dotfiles_codex}/${type}/${name}"

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

        if [[ -e "$target" ]]; then
          echo "Warning: ${target} already exists (skipping)" >&2
          warned=$((warned + 1))
          continue
        fi

        mkdir -p "$(dirname "$target")"
        ln -s "$src" "$target"
        echo "Linked (Codex): ${type}/${name}"
        linked=$((linked + 1))
      done
    done
  fi

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

    for asset_path in "${type_dir}"*; do
      [[ -e "$asset_path" ]] || continue
      local name
      name="$(basename "$asset_path")"
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
      elif [[ -e "$target" ]]; then
        status="not linked (exists)"
      else
        status="not linked"
      fi

      printf "  %-30s %s\n" "${type}/${name}" "[${status}]"

      if [[ "$type" == "skills" ]]; then
        local codex_target="${AGENTS_DIR}/skills/${name}"
        local codex_status
        if [[ -L "$codex_target" ]]; then
          local codex_link
          codex_link="$(readlink "$codex_target")"
          if [[ "$codex_link" == "$src" ]]; then
            codex_status="linked"
          else
            codex_status="conflict (-> ${codex_link})"
          fi
        elif [[ -e "$codex_target" ]]; then
          codex_status="not linked (exists)"
        else
          codex_status="not linked"
        fi
        printf "  %-30s %s\n" "Codex skill ${name}" "[${codex_status}]"
      fi
      found=$((found + 1))
    done
  done

  local dotfiles_codex="${DOTFILES_DIR}/codex"
  if [[ -d "$dotfiles_codex" ]]; then
    for type_dir in "${dotfiles_codex}"/*/; do
      [[ -d "$type_dir" ]] || continue
      local type
      type="$(basename "$type_dir")"
      for asset_path in "${type_dir}"*; do
        [[ -e "$asset_path" ]] || continue
        local name
        name="$(basename "$asset_path")"
        local src="${dotfiles_codex}/${type}/${name}"
        local target="${CODEX_DIR}/${type}/${name}"
        local status
        if [[ -L "$target" ]]; then
          local current_link
          current_link="$(readlink "$target")"
          if [[ "$current_link" == "$src" ]]; then
            status="linked"
          else
            status="conflict (-> ${current_link})"
          fi
        elif [[ -e "$target" ]]; then
          status="not linked (exists)"
        else
          status="not linked"
        fi
        printf "  %-30s %s\n" "Codex ${type}/${name}" "[${status}]"
        found=$((found + 1))
      done
    done
  fi

  if [[ "$found" -eq 0 ]]; then
    echo "No managed assets found."
  fi
}

cmd_unmanaged() {
  local found=0

  for type in "${ASSET_TYPES[@]}"; do
    local claude_type_dir="${CLAUDE_DIR}/${type}"
    [[ -d "$claude_type_dir" ]] || continue

    for asset_path in "${claude_type_dir}"/*; do
      [[ -e "$asset_path" || -L "$asset_path" ]] || continue
      local name
      name="$(basename "$asset_path")"
      local expected_src="${DOTFILES_DIR}/claude/${type}/${name}"
      local status

      if [[ -L "$asset_path" ]]; then
        local link_target
        link_target="$(readlink "$asset_path")"
        if [[ "$link_target" == "$expected_src" ]]; then
          continue
        fi
        status="external -> ${link_target}"
      else
        status="unmanaged"
      fi

      printf "  %-30s %s\n" "${type}/${name}" "[${status}]"
      found=$((found + 1))
    done
  done

  if [[ "$found" -eq 0 ]]; then
    echo "All assets are managed."
  fi
}

cmd_remove() {
  local target="$1"
  local type="${target%%/*}"
  local name="${target#*/}"

  if [[ -z "$type" || -z "$name" || "$type" == "$name" ]]; then
    echo "Error: Invalid format. Use <type>/<name> (e.g., skills/commit, agents/foo.md)" >&2
    exit 1
  fi

  local dotfiles_path="${DOTFILES_DIR}/claude/${type}/${name}"
  local claude_path="${CLAUDE_DIR}/${type}/${name}"
  local codex_skill_path="${AGENTS_DIR}/skills/${name}"

  if [[ ! -e "$dotfiles_path" ]]; then
    echo "Error: Not managed: ${target}" >&2
    exit 1
  fi

  if [[ -L "$claude_path" ]]; then
    rm "$claude_path"
  fi

  if [[ "$type" == "skills" && -L "$codex_skill_path" ]]; then
    local codex_link
    codex_link="$(readlink "$codex_skill_path")"
    if [[ "$codex_link" == "$dotfiles_path" ]]; then
      rm "$codex_skill_path"
    fi
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
  unmanaged)
    cmd_unmanaged
    ;;
  *)
    echo "Error: Unknown command: ${command}" >&2
    usage
    ;;
esac
