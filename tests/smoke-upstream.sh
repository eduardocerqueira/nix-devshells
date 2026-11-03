#!/usr/bin/env bash
# Smoke test for the `upstream` shell (generic open-source contribution).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
source "$SCRIPT_DIR/common.sh"

echo "==> smoke-upstream: shared bundle"
require_commands "${SHARED_TOOLS[@]}"

echo "==> smoke-upstream: languages"
require_commands java javac mvn node npm pnpm yarn python uv pip go

echo "==> smoke-upstream: pinned major versions"
java -version 2>&1 | grep -E 'version "21\.'
yarn --version | grep -E '^1\.'

echo "==> smoke-upstream: JAVA17_HOME points at a Java 17"
# Set by the shellHook, so only under `nix develop`; the flake check runs the
# package set alone.
if [ -n "${JAVA17_HOME:-}" ]; then
  "$JAVA17_HOME/bin/java" -version 2>&1 | grep -E 'version "17\.'
  echo "  ok: $JAVA17_HOME"
else
  echo "  skipped: JAVA17_HOME not set (not running inside the shell)"
fi

echo "==> smoke-upstream: Kubernetes clients"
require_commands helm kubectl

echo "==> smoke-upstream: contribution tools"
require_commands pre-commit git-absorb gh-dash act codespell typos \
  markdownlint-cli2 yamllint actionlint editorconfig-checker reuse cz scc

echo "==> smoke-upstream: shell closure contains exactly what it should"
assert_from_shell claude pre-commit java mvn helm kubectl
assert_not_from_shell shellcheck difft

echo "==> smoke-upstream: passed"
