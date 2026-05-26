#!/usr/bin/env bash
# Smoke test for flakes/default (pinned nixos-24.11).
set -euo pipefail

echo "==> smoke-default: checking required commands"
for cmd in node npm pnpm python go gh docker nixd rg fd bat eza fzf; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-default: checking pinned major versions"
node --version | grep -E '^v20\.'
python --version | grep -E 'Python 3\.12\.'
go version | grep -E 'go1\.23'

echo "==> smoke-default: passed"
