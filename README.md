# nix-devshells

Reproducible dev shells for macOS and Linux — flake-based, profile-persisted.

A small Nix flake library (`mkDevShell`) plus ready-to-use development environments. Designed to coexist with other Nix setups (e.g. work-specific repos) on the same machine.

## Overview

| Path | Description |
|------|-------------|
| [lib/](./lib/) | Shared `mkDevShell` function used by all flakes |
| [flakes/default/](./flakes/default/) | General-purpose shell: Node, Python, Go, modern CLI tools |
| [templates/home-manager/](./templates/home-manager/) | Optional Home Manager template with `nix-personal-*` aliases |
| [config/nix.conf](./config/nix.conf) | Minimal Nix settings (flakes enabled) |

### Architecture

```
macOS / Linux
 └─ Nix (Determinate or upstream)
     └─ dev shells via nix develop --profile ~/nix-workspace/...
     └─ optional Home Manager (standalone, flake-based)
```

This repo does **not** use nix-darwin.

## Prerequisites

- Nix with flakes enabled ([Determinate Nix](https://determinate.systems/) recommended on macOS)
- macOS: Xcode Command Line Tools for native builds (`xcode-select --install`)

## Quick start

### 1. Enable flakes (if needed)

```sh
mkdir -p ~/.config/nix
cp config/nix.conf ~/.config/nix/nix.conf
```

### 2. Create a profile workspace

```sh
mkdir -p ~/nix-workspace
```

### 3. Enter the default shell

```sh
nix develop --profile ~/nix-workspace/personal-default flakes/default -c zsh -i
```

On first run Nix builds the environment; later runs reuse the profile.

## Available shells

| Command / alias | Profile | Tools |
|-----------------|---------|-------|
| `flakes/default` | `~/nix-workspace/personal-default` | Node, pnpm, Python, Go, gh, docker, modern CLI |

Add more flakes under `flakes/` as needed.

## Optional: Home Manager aliases

Copy the template and customize the `USER CONFIGURATION` block:

```sh
mkdir -p ~/.config/home-manager
cp templates/home-manager/*.nix ~/.config/home-manager/
# edit flake.nix — username, paths, git identity
home-manager switch --flake ~/.config/home-manager#YOUR_USER
```

Then use:

```sh
nix-personal-default
```

See [templates/home-manager/README.md](./templates/home-manager/README.md) for coexistence notes with other Nix repos.

## Coexistence with other Nix repos

One Nix install serves all repos. Avoid conflicts by:

- **Separate profile names** — e.g. `personal-default` vs work profiles in `~/nix-workspace/`
- **Separate alias prefixes** — `nix-personal-*` vs work aliases
- **Git identity via `includeIf`** — don't rely on switching Home Manager for work vs personal email

## Creating a new shell

```nix
# flakes/my-project/flake.nix
{
  inputs = {
    base.url = "path:../../lib";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { base, nixpkgs }: {
    devShells.aarch64-darwin.default = base.lib.mkDevShell {
      system = "aarch64-darwin";
      node = true;
      java = true;
      title = "MY PROJECT";
      extraPackages = [ /* pkgs */ ];
    };
  };
}
```

### `mkDevShell` options

Languages and tools are **opt-in** (`false` by default):

| Option | Default | When `true` |
|--------|---------|-------------|
| `java` | `false` | Temurin 17 |
| `maven` | `false` | Maven |
| `node` | `false` | Node.js 22 |
| `pnpm` | `false` | pnpm |
| `yarn` | `false` | Yarn |
| `python` | `false` | Python 3.12 + pip + uv |
| `go` | `false` | Go + gotools |
| `helm` | `false` | Kubernetes Helm |
| `kubectl` | `false` | kubectl |

Always included: ripgrep, fd, bat, eza, fzf, delta, gh, docker, nixd, and other common CLI tools.

Pass a package instead of `true` to pin a specific version.

## Updating

```sh
cd /path/to/nix-devshells
git pull
nix flake update flakes/default   # or the flake you use
```

Re-enter the shell to pick up changes.

## License

MIT — see [LICENSE](./LICENSE).
