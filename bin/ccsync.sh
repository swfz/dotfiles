#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="${CCSYNC_DOTFILES_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
CLAUDE_DIR="${CCSYNC_CLAUDE_DIR:-${HOME}/.claude}"
AGENTS_DIR="${CCSYNC_AGENTS_DIR:-${HOME}/.agents}"
CODEX_DIR="${CCSYNC_CODEX_DIR:-${HOME}/.codex}"
APM_LOCK="${CCSYNC_APM_LOCK:-${HOME}/.apm/apm.lock.yaml}"
ASSET_TYPES=(skills rules agents commands)

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args]

Commands:
  add <type>/<name>      Add a Claude asset to dotfiles management
  link                   Create symlinks for all managed Claude/Codex assets
  list                   List all assets with their source
                         (dotfiles / apm / external / unmanaged) and link status
  remove <type>/<name>   Remove an asset from dotfiles management
  unmanaged              List assets in ~/.claude not managed anywhere
                         (excluding dotfiles, apm and external symlinks)

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

# symlink の状態を返す: linked / conflict (-> X) / not linked (exists) / not linked
link_status() {
  local target="$1" src="$2"
  if [[ -L "$target" ]]; then
    local current_link
    current_link="$(readlink "$target")"
    if [[ "$current_link" == "$src" ]]; then
      echo "linked"
    else
      echo "conflict (-> ${current_link})"
    fi
  elif [[ -e "$target" ]]; then
    echo "not linked (exists)"
  else
    echo "not linked"
  fi
}

# apm のロックファイルから ~/.claude 直下に配布された資産 (<type>/<name>) を列挙する
apm_deployed_assets() {
  [[ -f "$APM_LOCK" ]] || return 0
  sed -nE 's#^[[:space:]]*-[[:space:]]+\.claude/([^/[:space:]]+/[^/[:space:]]+)[[:space:]]*$#\1#p' "$APM_LOCK"
}

# ~/.claude と dotfiles の資産を出どころ付きで列挙する
# 出力: <label>\t<source>\t<detail>  (source: dotfiles / apm / external / unmanaged)
collect_assets() {
  local apm_assets
  apm_assets="$(apm_deployed_assets)"

  local types=("${ASSET_TYPES[@]}")
  local type_dir
  for type_dir in "${DOTFILES_DIR}/claude"/*/; do
    [[ -d "$type_dir" ]] || continue
    local t
    t="$(basename "$type_dir")"
    [[ " ${types[*]} " == *" ${t} "* ]] || types+=("$t")
  done

  local type
  for type in "${types[@]}"; do
    local names
    names="$(
      for path in "${CLAUDE_DIR}/${type}"/* "${DOTFILES_DIR}/claude/${type}"/*; do
        if [[ -e "$path" || -L "$path" ]]; then basename "$path"; fi
      done | sort -u
    )"
    [[ -n "$names" ]] || continue

    local name
    while IFS= read -r name; do
      local src="${DOTFILES_DIR}/claude/${type}/${name}"
      local target="${CLAUDE_DIR}/${type}/${name}"
      local source detail

      if [[ -e "$src" ]]; then
        source="dotfiles"
        detail="[$(link_status "$target" "$src")"
        if [[ "$type" == "skills" ]]; then
          detail+=", codex: $(link_status "${AGENTS_DIR}/skills/${name}" "$src")"
        fi
        detail+="]"
      elif [[ -L "$target" ]]; then
        source="external"
        detail="-> $(readlink "$target")"
        detail="${detail/#-> ${HOME}/-> ~}"
      elif grep -qxF "${type}/${name}" <<<"$apm_assets"; then
        source="apm"
        detail=""
      else
        source="unmanaged"
        detail=""
      fi

      printf '%s\t%s\t%s\n' "${type}/${name}" "$source" "$detail"
    done <<<"$names"
  done

  local dotfiles_codex="${DOTFILES_DIR}/codex"
  [[ -d "$dotfiles_codex" ]] || return 0
  for type_dir in "${dotfiles_codex}"/*/; do
    [[ -d "$type_dir" ]] || continue
    local type
    type="$(basename "$type_dir")"
    local asset_path
    for asset_path in "${type_dir}"*; do
      [[ -e "$asset_path" ]] || continue
      local name
      name="$(basename "$asset_path")"
      printf '%s\t%s\t%s\n' "Codex ${type}/${name}" "dotfiles" \
        "[$(link_status "${CODEX_DIR}/${type}/${name}" "${dotfiles_codex}/${type}/${name}")]"
    done
  done
}

print_assets() {
  local label source detail
  while IFS=$'\t' read -r label source detail; do
    if [[ -n "$detail" ]]; then
      printf "  %-34s %-10s %s\n" "$label" "$source" "$detail"
    else
      printf "  %-34s %s\n" "$label" "$source"
    fi
  done
}

cmd_list() {
  local assets
  assets="$(collect_assets)"
  if [[ -z "$assets" ]]; then
    echo "No assets found."
    return
  fi
  print_assets <<<"$assets"
}

cmd_unmanaged() {
  local assets
  assets="$(collect_assets | awk -F '\t' '$2 == "unmanaged"')"
  if [[ -z "$assets" ]]; then
    echo "All assets are managed."
    return
  fi
  print_assets <<<"$assets"
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
