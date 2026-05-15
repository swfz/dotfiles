#!/usr/bin/env bash
set -euo pipefail

payload=$(cat)
fp=$(echo "$payload" | jq -r '.tool_input.file_path // empty')

case "$fp" in
  *.md|*.markdown) ;;
  *) exit 0 ;;
esac

fp=$(realpath "$fp" 2>/dev/null || echo "$fp")

target="work"
case "$fp" in
  "$HOME"/work/strategy/*|"$HOME"/work/gl/management-scripts/*)
    target="management" ;;
  "$HOME"/dotfiles/*|"$HOME"/memo/*|"$HOME"/gh/*|"$HOME"/til/*)
    target="private" ;;
esac

url=$(mo --json --no-open "$fp" --target "$target" 2>/dev/null | jq -r '.files[-1].url')

jq -nc --arg url "$url" --arg target "$target" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: "Markdown registered to mo (\($target)): \($url)"
  }
}'

