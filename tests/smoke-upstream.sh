#!/usr/bin/env bash
# Smoke test for the `upstream` shell (generic open-source contribution).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
source "$SCRIPT_DIR/common.sh"

echo "==> smoke-upstream: shared bundle"
require_commands "${SHARED_TOOLS[@]}"

echo "==> smoke-upstream: languages"
require_commands node npm python uv pip go

echo "==> smoke-upstream: contribution tools"
require_commands pre-commit git-absorb gh-dash act codespell typos \
  markdownlint-cli2 yamllint actionlint editorconfig-checker reuse cz scc

echo "==> smoke-upstream: shell closure contains exactly what it should"
assert_from_shell claude pre-commit
assert_not_from_shell shellcheck difft helm kubectl

echo "==> smoke-upstream: passed"
