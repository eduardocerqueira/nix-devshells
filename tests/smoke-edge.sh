#!/usr/bin/env bash
# Smoke test for the `edge` shell (nixpkgs-unstable, latest *stable* defaults).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
source "$SCRIPT_DIR/common.sh"

echo "==> smoke-edge: shared bundle"
require_commands "${SHARED_TOOLS[@]}"

echo "==> smoke-edge: shell-specific tools"
require_commands java mvn node npm pnpm yarn python go helm kubectl helm-docs

echo "==> smoke-edge: reported versions"
node_ver="$(node --version)"
python_ver="$(python --version 2>&1)"
java_ver="$(java -version 2>&1 | head -1)"
go_ver="$(go version)"
yarn_ver="$(yarn --version)"

echo "  node:   $node_ver"
echo "  python: $python_ver"
echo "  java:   $java_ver"
echo "  go:     $go_ver"
echo "  yarn:   $yarn_ver"

# Floors, not exact pins: they assert `useLatestDefaults` is still picking up
# current majors. Raise them when a major moves; the patterns already allow any
# higher major, so they do not break on routine upstream bumps.
echo "$node_ver" | grep -E '^v(2[6-9]|[3-9][0-9])\.'
echo "$python_ver" | grep -E '^Python 3\.(1[4-9]|[2-9][0-9])\.[0-9]+$'
echo "$java_ver" | grep -E '"(2[6-9]|[3-9][0-9])\.'
echo "$go_ver" | grep -E 'go1\.(2[6-9]|[3-9][0-9])'

echo "==> smoke-edge: yarn resolves to Yarn Berry, not Yarn Classic 1.22"
echo "$yarn_ver" | grep -E '^([4-9]|[1-9][0-9])\.' || {
  echo "error: yarn is $yarn_ver — expected Yarn 4+ (yarn-berry)" >&2
  exit 1
}

echo "==> smoke-edge: no prereleases selected"
# Guards against accidentally selecting RCs / alphas (e.g. Python 3.15.0rc2).
for ver in "$node_ver" "$python_ver" "$java_ver" "$go_ver" "$yarn_ver"; do
  if echo "$ver" | grep -Eiq '(^|[^a-z])(rc|alpha|beta)[0-9.-]|\.dev'; then
    echo "error: prerelease version selected: $ver" >&2
    exit 1
  fi
done

echo "==> smoke-edge: passed"
