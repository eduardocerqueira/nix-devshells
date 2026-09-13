#!/usr/bin/env bash
# Smoke test for flakes/latest (nixpkgs-unstable, latest *stable* defaults).
set -euo pipefail

echo "==> smoke-latest: checking required commands"
for cmd in java mvn node npm pnpm yarn python go helm kubectl gh docker nixd; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-latest: checking latest stable versions (no prereleases)"
node_ver="$(node --version)"
python_ver="$(python --version 2>&1)"
java_ver="$(java -version 2>&1 | head -1)"
go_ver="$(go version)"

echo "  node:   $node_ver"
echo "  python: $python_ver"
echo "  java:   $java_ver"
echo "  go:     $go_ver"

# Floors for current latest stables in nixpkgs-unstable (bump when majors move).
echo "$node_ver" | grep -E '^v(2[6-9]|[3-9][0-9])\.'
echo "$python_ver" | grep -E '^Python 3\.(1[4-9]|[2-9][0-9])\.[0-9]+$'
echo "$java_ver" | grep -E '"2[6-9]\.'
echo "$go_ver" | grep -E 'go1\.(2[6-9]|[3-9][0-9])'

# Guard against accidentally selecting RCs / alphas (e.g. Python 3.15.0rc2).
for ver in "$node_ver" "$python_ver" "$java_ver" "$go_ver"; do
  if echo "$ver" | grep -Eiq 'rc|alpha|beta|\.dev'; then
    echo "error: prerelease version selected: $ver" >&2
    exit 1
  fi
done

echo "==> smoke-latest: passed"
