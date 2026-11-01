#!/usr/bin/env bash
# Smoke test for the `kubernetes` shell (kubernetes, minikube, website).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
source "$SCRIPT_DIR/common.sh"

echo "==> smoke-kubernetes: shared bundle"
require_commands "${SHARED_TOOLS[@]}"

echo "==> smoke-kubernetes: toolchains"
require_commands go gopls dlv node npm python uv kubectl kind etcd hugo pagefind
go version | grep -E 'go1\.27'
node --version | grep -E '^v24\.'

echo "==> smoke-kubernetes: Hugo is the extended build kubernetes/website pins"
hugo version | grep -E 'v0\.144\.2\+extended'

echo "==> smoke-kubernetes: GNU userland for kubernetes/hack"
sed --version | grep -q GNU
tar --version | grep -q GNU
grep --version | grep -q GNU
awk --version | grep -q GNU
# shellcheck disable=SC2185  # GNU find accepts --version without a path
find --version | grep -q GNU
echo "  ok: sed / tar / grep / awk / find are GNU"
bash -c '[ "${BASH_VERSINFO[0]}" -ge 5 ]'
echo "  ok: bash $(bash -c 'echo $BASH_VERSION')"

echo "==> smoke-kubernetes: shell closure contains exactly what it should"
assert_from_shell go hugo sed claude
assert_not_from_shell shellcheck difft

echo "==> smoke-kubernetes: passed"
