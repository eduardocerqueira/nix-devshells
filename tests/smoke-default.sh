#!/usr/bin/env bash
# Smoke test for the `default` shell (pinned stable channel).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
source "$SCRIPT_DIR/common.sh"

echo "==> smoke-default: shared bundle"
require_commands "${SHARED_TOOLS[@]}"

echo "==> smoke-default: shell-specific tools"
require_commands node npm pnpm python go uv pip

echo "==> smoke-default: pinned major versions"
node --version | grep -E '^v24\.'
python --version | grep -E 'Python 3\.13\.'
go version | grep -E 'go1\.26'

echo "==> smoke-default: claude actually runs (not just present on PATH)"
claude --version | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+ \(Claude Code\)'
echo "  ok: claude $(claude --version)"

echo "==> smoke-default: the lint tools this repo's CI depends on actually run"
nixfmt --version >/dev/null
deadnix --version >/dev/null
shellcheck --version >/dev/null
shfmt --version >/dev/null
just --version >/dev/null
difft --version >/dev/null
gitleaks version >/dev/null 2>&1
statix --help >/dev/null # statix has no --version, only subcommands
echo "  ok: nixfmt / statix / deadnix / shellcheck / shfmt / just / difft / gitleaks"

echo "==> smoke-default: shell closure contains exactly what it should"
# git and claude are the ones that would quietly fall through to a host copy.
assert_from_shell node git claude shellcheck nixfmt
# `default` enables neither helm nor kubectl nor maven.
assert_not_from_shell helm kubectl mvn

echo "==> smoke-default: passed"
