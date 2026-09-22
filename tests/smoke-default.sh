#!/usr/bin/env bash
# Smoke test for the `default` shell (pinned stable channel).
set -euo pipefail

echo "==> smoke-default: checking required commands"
for cmd in node npm pnpm python go git gh claude docker nixd rg fd bat eza fzf jq delta; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-default: checking pinned major versions"
node --version | grep -E '^v24\.'
python --version | grep -E 'Python 3\.13\.'
go version | grep -E 'go1\.26'

echo "==> smoke-default: claude actually runs (not just present on PATH)"
claude --version | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+ \(Claude Code\)'
echo "  ok: claude $(claude --version)"

echo "==> smoke-default: shell closure contains exactly what it should"
# Guards the banner/PATH-leak class of bug. Membership is tested against
# $nativeBuildInputs -- the shell's own closure -- not against "looks like a
# store path", because a Nix-installed tool on the *host* PATH is a store path
# too and has nothing to do with this shell.
provided_by_shell() {
  local target="$1" prefix
  for prefix in ${nativeBuildInputs:-}; do
    [[ "$target" == "$prefix"/* ]] && return 0
  done
  return 1
}

if [ -z "${nativeBuildInputs:-}" ]; then
  echo "  skipped: nativeBuildInputs not set (not running inside the shell)"
else
  # Positive control: without this, a broken closure check would pass silently.
  # git and claude are the ones that would quietly fall through to a host copy.
  for cmd in node git claude; do
    resolved="$(command -v "$cmd")"
    provided_by_shell "$resolved" || {
      echo "error: $cmd is not provided by this shell: $resolved" >&2
      exit 1
    }
    echo "  ok: $cmd comes from the shell"
  done

  # `default` enables neither helm nor kubectl nor maven.
  for cmd in helm kubectl mvn; do
    if resolved="$(command -v "$cmd" 2>/dev/null)" && provided_by_shell "$resolved"; then
      echo "error: $cmd unexpectedly provided by the shell: $resolved" >&2
      exit 1
    fi
  done
  echo "  ok: helm/kubectl/mvn are not in this shell"
fi

echo "==> smoke-default: passed"
