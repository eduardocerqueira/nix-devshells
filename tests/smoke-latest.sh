#!/usr/bin/env bash
# Smoke test for flakes/latest (nixpkgs-unstable, useLatestDefaults).
set -euo pipefail

echo "==> smoke-latest: checking required commands"
for cmd in java mvn node npm pnpm yarn python go helm kubectl gh docker nixd; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-latest: checking newest nixpkgs attrs resolve"
node --version | grep -E '^v(2[4-9]|[3-9][0-9])\.'
python --version | grep -E 'Python 3\.1[4-9]'
java -version 2>&1 | head -1 | grep -E '"2[0-9]\.'

echo "==> smoke-latest: passed"
