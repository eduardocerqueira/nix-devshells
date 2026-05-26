# nix-devshells — shell shortcuts (source this file, do not execute).
#
#   source ~/git/eduardo/nix-devshells/nix-shortcut.sh
#
# Then run: nix-default | nix-latest | nix-ai | nix-devops

(return 0 2>/dev/null) || {
  echo "nix-shortcut.sh: source this file instead of running it:" >&2
  echo "  source /path/to/nix-devshells/nix-shortcut.sh" >&2
  exit 1
}

if [ -n "${BASH_VERSION:-}" ]; then
  _nix_devshells_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "${ZSH_VERSION:-}" ]; then
  _nix_devshells_root="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  echo "nix-shortcut.sh: unsupported shell; use bash or zsh" >&2
  return 1
fi

_NIX_DEVSHELLS_ROOT="${NIX_DEVSHELLS_ROOT:-$_nix_devshells_root}"
_NIX_DEVSHELLS_WORKSPACE="${NIX_DEVSHELLS_WORKSPACE:-$HOME/nix-workspace}"

_nix_devshell() {
  nix develop \
    --profile "$_NIX_DEVSHELLS_WORKSPACE/personal-$1" \
    "$_NIX_DEVSHELLS_ROOT/flakes/$2" \
    -c zsh -i
}

nix-default() { _nix_devshell default default; }
nix-latest()  { _nix_devshell latest latest; }
nix-ai()      { _nix_devshell ai ai; }
nix-devops()  { _nix_devshell devops devops; }

unset _nix_devshells_root

echo "nix-devshells shortcuts loaded from $_NIX_DEVSHELLS_ROOT"
echo "  nix-default  nix-latest  nix-ai  nix-devops"
