# shellcheck shell=bash
# nix-devshells — shell shortcuts (source this file, do not execute).
#
#   source ~/git/nix-devshells/nix-shortcut.sh
#
# Then run: nix-app | nix-edge | nix-ai | nix-devops

(return 0 2>/dev/null) || {
  echo "nix-shortcut.sh: source this file instead of running it:" >&2
  echo "  source /path/to/nix-devshells/nix-shortcut.sh" >&2
  exit 1
}

if [ -n "${BASH_VERSION:-}" ]; then
  _nix_devshells_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "${ZSH_VERSION:-}" ]; then
  # shellcheck disable=SC2296  # zsh-only expansion, guarded by the branch above
  _nix_devshells_root="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  echo "nix-shortcut.sh: unsupported shell; use bash or zsh" >&2
  return 1
fi

_NIX_DEVSHELLS_ROOT="${NIX_DEVSHELLS_ROOT:-$_nix_devshells_root}"
_NIX_DEVSHELLS_WORKSPACE="${NIX_DEVSHELLS_WORKSPACE:-$HOME/nix-workspace}"

_nix_devshell() {
  mkdir -p "$_NIX_DEVSHELLS_WORKSPACE"
  nix develop \
    --profile "$_NIX_DEVSHELLS_WORKSPACE/personal-$1" \
    "$_NIX_DEVSHELLS_ROOT#$1" \
    -c zsh -i
}

nix-app()    { _nix_devshell app; }
nix-edge()   { _nix_devshell edge; }
nix-ai()     { _nix_devshell ai; }
nix-devops() { _nix_devshell devops; }

unset _nix_devshells_root

echo "nix-devshells shortcuts loaded from $_NIX_DEVSHELLS_ROOT"
echo "  nix-app  nix-edge  nix-ai  nix-devops"
