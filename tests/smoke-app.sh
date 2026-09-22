#!/usr/bin/env bash
# Smoke test for the `app` shell (pinned stable channel).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
source "$SCRIPT_DIR/common.sh"

echo "==> smoke-app: shared bundle"
require_commands "${SHARED_TOOLS[@]}"

echo "==> smoke-app: shell-specific tools"
require_commands node npm pnpm python go uv pip

echo "==> smoke-app: pinned major versions"
node --version | grep -E '^v24\.'
python --version | grep -E 'Python 3\.13\.'
go version | grep -E 'go1\.26'

echo "==> smoke-app: claude actually runs (not just present on PATH)"
claude --version | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+ \(Claude Code\)'
echo "  ok: claude $(claude --version)"

echo "==> smoke-app: the lint tools actually run"
nixfmt --version >/dev/null
deadnix --version >/dev/null
shfmt --version >/dev/null
just --version >/dev/null
gitleaks version >/dev/null 2>&1
statix --help >/dev/null # statix has no --version, only subcommands
echo "  ok: nixfmt / statix / deadnix / shfmt / just / gitleaks"

echo "==> smoke-app: heavy tools stay out of the everyday shells"
# These live in the devops shell only: ShellCheck brings a Haskell runtime
# and difftastic is ~120 MiB. gotools is opt-in via the goTools flag.
assert_not_from_shell shellcheck difft goimports

echo "==> smoke-app: shell closure contains exactly what it should"
# git and claude are the ones that would quietly fall through to a host copy.
assert_from_shell node git claude nixfmt
# `app` enables neither helm nor kubectl nor maven.
assert_not_from_shell helm kubectl mvn

echo "==> smoke-app: passed"
