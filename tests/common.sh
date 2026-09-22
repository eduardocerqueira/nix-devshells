# shellcheck shell=bash
# Shared assertions for the smoke tests. Sourced, never executed.

# Everything lib/default.nix puts in every shell, regardless of toggles.
# Kept here so the four smoke tests cannot drift apart.
# shellcheck disable=SC2034  # consumed by the scripts that source this file
SHARED_TOOLS=(
  git gh git-filter-repo lazygit difft gitleaks
  claude
  docker
  nixd nixfmt statix deadnix
  shellcheck shfmt
  direnv just
  rg fd bat eza fzf jq delta tree curl wget htop tldr dust duf
  make gpg pkg-config
)

require_commands() {
  local cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null || {
      echo "error: missing command: $cmd" >&2
      return 1
    }
    echo "  ok: $cmd"
  done
}

# True when $1 resolves inside this shell's own closure. Membership is tested
# against $nativeBuildInputs rather than "looks like a store path", because a
# Nix-installed tool on the *host* PATH is a store path too and has nothing to
# do with this shell.
provided_by_shell() {
  local target="$1" prefix entry_name target_name
  [[ "$target" == /nix/store/* ]] || return 1

  # /nix/store/HASH-shellcheck-0.11.0-bin/bin/shellcheck -> shellcheck-0.11.0-bin
  target_name="${target#/nix/store/}"
  target_name="${target_name%%/*}"
  target_name="${target_name#*-}"

  for prefix in ${nativeBuildInputs:-}; do
    [[ "$target" == "$prefix"/* ]] && return 0

    # Multi-output packages (shellcheck, for one) put $bin/bin on PATH while
    # nativeBuildInputs lists $out. Those are different store paths with
    # different hashes, so the prefix test above cannot match. Compare the
    # name-version instead, allowing a trailing output suffix.
    entry_name="${prefix#/nix/store/}"
    entry_name="${entry_name%%/*}"
    entry_name="${entry_name#*-}"
    [[ "$target_name" == "$entry_name" || "$target_name" == "$entry_name"-* ]] && return 0
  done
  return 1
}

assert_from_shell() {
  local cmd resolved
  if [ -z "${nativeBuildInputs:-}" ]; then
    echo "  skipped: nativeBuildInputs not set (not running inside the shell)"
    return 0
  fi
  for cmd in "$@"; do
    resolved="$(command -v "$cmd")" || {
      echo "error: $cmd not found" >&2
      return 1
    }
    provided_by_shell "$resolved" || {
      echo "error: $cmd is not provided by this shell: $resolved" >&2
      return 1
    }
    echo "  ok: $cmd comes from the shell"
  done
}

assert_not_from_shell() {
  local cmd resolved
  [ -n "${nativeBuildInputs:-}" ] || return 0
  for cmd in "$@"; do
    if resolved="$(command -v "$cmd" 2>/dev/null)" && provided_by_shell "$resolved"; then
      echo "error: $cmd unexpectedly provided by this shell: $resolved" >&2
      return 1
    fi
  done
  echo "  ok: not in this shell: $*"
}
