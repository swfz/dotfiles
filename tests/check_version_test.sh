#!/bin/bash

set -euo pipefail

command -v yq >/dev/null || {
  echo "mikefarah yq is required" >&2
  exit 1
}
yq --version 2>&1 | grep -qi mikefarah || {
  echo "mikefarah yq is required" >&2
  exit 1
}
YQ_BIN="$(command -v yq)"
if command -v mise >/dev/null && mise which yq >/dev/null 2>&1; then
  YQ_BIN="$(mise which yq)"
fi

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
mkdir -p "$TMP_ROOT/home/dotfiles/ansible" "$TMP_ROOT/bin"
ln -s "$YQ_BIN" "$TMP_ROOT/bin/yq"

cat >"$TMP_ROOT/home/dotfiles/ansible/versions_vars.yml" <<'EOF'
git_version: 2.49.0
actionlint_version: v1.2.3
reviewdog_version: 0.20.3
gh_version: 2.83.0
mise_version: 2025.10.11
EOF

for name in git actionlint reviewdog gh mise; do
  cat >"$TMP_ROOT/bin/$name" <<'EOF'
#!/bin/bash
case "$(basename "$0")" in
  git) echo "git version ${FAKE_GIT_VERSION:-2.49.0}" ;;
  actionlint) echo "${FAKE_ACTIONLINT_VERSION:-1.2.3}" ;;
  reviewdog) printf '%s' "${FAKE_REVIEWDOG_VERSION-0.20.3}" ;;
  gh) echo "gh version ${FAKE_GH_VERSION:-2.83.0} (test)" ;;
  mise) echo "${FAKE_MISE_VERSION:-2025.10.11} test" ;;
esac
EOF
  chmod +x "$TMP_ROOT/bin/$name"
done

run() {
  env HOME="$TMP_ROOT/home" PATH="$TMP_ROOT/bin:$PATH" TERM=dumb "$@" \
    bash "$REPO_DIR/bin/check_version.sh"
}

test -z "$(run env)"
test -z "$(FAKE_ACTIONLINT_VERSION=1.2.3 run env)"
test "$(FAKE_GIT_VERSION=2.48.0 run env)" = "WARN missing: git 2.49.0. local: 2.48.0"
test "$(FAKE_REVIEWDOG_VERSION='' run env)" = "WARN missing: reviewdog (not installed or command failed)"

echo "check_version tests passed"
