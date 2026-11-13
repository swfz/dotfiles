#!/usr/bin/env bash
set -euo pipefail

payload=$(cat)
fp=$(echo "$payload" | jq -r '.tool_input.file_path // empty')

case "$fp" in
  *.md | *.markdown) ;;
  *) exit 0 ;;
esac

fp=$(realpath "$fp" 2>/dev/null || echo "$fp")

target="work"
case "$fp" in
  "$HOME"/work/strategy/* | "$HOME"/work/gl/management-scripts/*)
    target="management"
    ;;
  "$HOME"/dotfiles/* | "$HOME"/memo/* | "$HOME"/gh/* | "$HOME"/til/*)
    target="private"
    ;;
esac

# mo --json は登録済みの全ファイルを順不同で返すため、パスで突き合わせる
# hook の stdin が渡ると mo は「redirected stdin with positional arguments」で失敗するので切り離す
url=$(mo --json --no-open "$fp" --target "$target" </dev/null 2>/dev/null |
  jq -r --arg fp "$fp" 'first(.files[] | select(.path == $fp) | .url) // empty')
[[ -n "$url" ]] || exit 0

jq -nc --arg url "$url" --arg target "$target" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: "Markdown registered to mo (\($target)): \($url)"
  }
}'
