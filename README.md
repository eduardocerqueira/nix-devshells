# nix-devshells

Reproducible dev shells for macOS and Linux — flake-based, profile-persisted.

A small Nix flake library (`mkDevShell`) plus ready-to-use development environments. Designed to coexist with other Nix setups (e.g. work-specific repos) on the same machine.

## Flakes

| Flake | Channel | What it provides |
|-------|---------|------------------|
| [`default`](./flakes/default/) | `nixos-24.11` (pinned) | General development — Node 20, Python 3.12, Go 1.23, pnpm, and common CLI tools |
| [`latest`](./flakes/latest/) | `nixpkgs-unstable` | All optional languages and tools at the newest versions packaged in nixpkgs |
| [`ai`](./flakes/ai/) | `nixos-24.11` (pinned) | AI / ML workflows — Ollama, Python 3.12 with Hugging Face libs, uv, ffmpeg, git-lfs |
| [`devops`](./flakes/devops/) | `nixos-24.11` (pinned) | DevOps / SRE — Kubernetes, multi-cloud CLIs, OpenTofu, secrets, and platform utilities |

## Overview

| Path | Description |
|------|-------------|
| [lib/](./lib/) | Shared `mkDevShell` function used by all flakes |
| [flakes/default/](./flakes/default/) | **Pinned** shell on `nixos-24.11` (Node 20, Python 3.12, Go 1.23) |
| [flakes/latest/](./flakes/latest/) | **Latest** shell on `nixpkgs-unstable` (all tools enabled) |
| [flakes/ai/](./flakes/ai/) | **AI / ML** shell on `nixos-24.11` (Ollama, Hugging Face, Python) |
| [flakes/devops/](./flakes/devops/) | **DevOps / SRE** shell on `nixos-24.11` (k8s, cloud CLIs, IaC) |
| [nix-shortcut.sh](./nix-shortcut.sh) | Sourceable shell shortcuts (`nix-ai`, `nix-latest`, …) — no Home Manager changes |
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

### 3. Enter a shell

**Pinned (stable, reproducible):**

```sh
nix develop --profile ~/nix-workspace/personal-default /Users/eduardo/git/eduardo/nix-devshells/flakes/default -c zsh -i
```

**Latest (nixpkgs-unstable, all tools):**

```sh
nix develop --profile ~/nix-workspace/personal-latest /Users/eduardo/git/eduardo/nix-devshells/flakes/latest -c zsh -i
```

**AI / ML (Ollama, Hugging Face, Python):**

```sh
nix develop --profile ~/nix-workspace/personal-ai /Users/eduardo/git/eduardo/nix-devshells/flakes/ai -c zsh -i
```

**DevOps / SRE (Kubernetes, cloud CLIs, IaC):**

```sh
nix develop --profile ~/nix-workspace/personal-devops /Users/eduardo/git/eduardo/nix-devshells/flakes/devops -c zsh -i
```

On first run Nix builds the environment; later runs reuse the profile. Exit with `exit`.

### 4. Shell shortcuts (optional)

If you already manage aliases in Home Manager and want to avoid editing `~/.config/home-manager/home.nix`, source the repo shortcuts in your current shell:

```sh
source ~/git/eduardo/nix-devshells/nix-shortcut.sh
```

Then enter any shell with a short command:

```sh
nix-default   # pinned general dev
nix-latest    # nixpkgs-unstable
nix-ai        # AI / ML
nix-devops    # DevOps / SRE
```

The script resolves the repo path automatically. Override with `NIX_DEVSHELLS_ROOT` or `NIX_DEVSHELLS_WORKSPACE` if needed.

To load shortcuts in every new terminal, add the `source` line to your `~/.zshrc` (or `~/.bashrc`).

## Usage

| Shell | Profile | Shortcut | Enter command |
|-------|---------|----------|---------------|
| Pinned default | `~/nix-workspace/personal-default` | `nix-default` | `nix develop --profile ~/nix-workspace/personal-default /Users/eduardo/git/eduardo/nix-devshells/flakes/default -c zsh -i` |
| Latest | `~/nix-workspace/personal-latest` | `nix-latest` | `nix develop --profile ~/nix-workspace/personal-latest /Users/eduardo/git/eduardo/nix-devshells/flakes/latest -c zsh -i` |
| AI / ML | `~/nix-workspace/personal-ai` | `nix-ai` | `nix develop --profile ~/nix-workspace/personal-ai /Users/eduardo/git/eduardo/nix-devshells/flakes/ai -c zsh -i` |
| DevOps / SRE | `~/nix-workspace/personal-devops` | `nix-devops` | `nix develop --profile ~/nix-workspace/personal-devops /Users/eduardo/git/eduardo/nix-devshells/flakes/devops -c zsh -i` |
| Re-enter pinned profile | `~/nix-workspace/personal-default` | — | `nix develop ~/nix-workspace/personal-default -c zsh -i` |
| Re-enter latest profile | `~/nix-workspace/personal-latest` | — | `nix develop ~/nix-workspace/personal-latest -c zsh -i` |
| Re-enter AI profile | `~/nix-workspace/personal-ai` | — | `nix develop ~/nix-workspace/personal-ai -c zsh -i` |
| Re-enter DevOps profile | `~/nix-workspace/personal-devops` | — | `nix develop ~/nix-workspace/personal-devops -c zsh -i` |
| HM alias (pinned) | — | `nix-personal-default` | requires Home Manager template |
| HM alias (latest) | — | `nix-personal-latest` | requires Home Manager template |
| HM alias (devops) | — | `nix-personal-devops` | requires Home Manager template |

## Available shells

### `flakes/default` — pinned

Tracks **`nixos-24.11`** (locked in `flake.lock`). Tool versions stay stable until you choose to update the lock file.

| Tool | Version (approx.) |
|------|-------------------|
| Node.js | 20.x |
| Python | 3.12 |
| Go | 1.23 |
| pnpm | from nixos-24.11 |

Also includes: gh, docker, ripgrep, fd, bat, eza, fzf, delta, nixd, and other common CLI tools.

### `flakes/latest` — newest in nixpkgs

Tracks **`nixpkgs-unstable`** with `useLatestDefaults = true`: each tool resolves to the highest version **packaged in nixpkgs** (not necessarily the same day as upstream releases).

| Tool | Package attr | Typical version |
|------|--------------|-----------------|
| Java | `temurin-bin-25` | 25.x (Java 26 not yet in nixpkgs) |
| Python | `python314` | 3.14.x |
| Node.js | `nodejs_latest` | 26.x |
| Go | `go` | latest in unstable |
| Maven, pnpm, Helm, kubectl | defaults | latest in unstable |

All optional tools enabled: Java, Maven, Node, pnpm, Yarn, Python, Go, Helm, kubectl, and the shared CLI bundle.

Refresh packages:

```sh
nix flake update --flake /Users/eduardo/git/eduardo/nix-devshells/flakes/latest
```

After updating the flake, rebuild the profile (otherwise an old profile may keep previous versions):

```sh
nix develop --profile ~/nix-workspace/personal-latest /Users/eduardo/git/eduardo/nix-devshells/flakes/latest -c zsh -i
```

**Note:** Nix only ships what is packaged in [nixpkgs](https://github.com/NixOS/nixpkgs). If upstream has Java 26 or Python 3.14.5 but nixpkgs has not merged those yet, the shell uses the newest available nixpkgs version (e.g. Temurin 25, Python 3.14.4).

### `flakes/ai` — AI / ML

Tracks **`nixos-24.11`**. Python 3.12 with Hugging Face libraries pre-installed; heavy ML deps (torch, transformers, etc.) are added per-project via `uv`.

| Tool / area | Included |
|-------------|----------|
| Local LLMs | Ollama (`OLLAMA_HOST`, `OLLAMA_MODELS` configured on enter) |
| Python | 3.12 + uv + pip; `huggingface-hub`, `tokenizers`, `safetensors` |
| Hugging Face | `hf` Hub CLI (`huggingface-hub` 1.x); set `HF_TOKEN` for gated models |
| Media & storage | ffmpeg, git-lfs |

Also includes the shared CLI bundle (gh, ripgrep, fd, bat, etc.).

### `flakes/devops` — DevOps / SRE

Tracks **`nixos-24.11`**. Kubernetes-first shell with multi-cloud CLIs and infrastructure tooling.

| Tool / area | Included |
|-------------|----------|
| Kubernetes | kubectl, helm, k9s, kubectx, stern, kubecolor, helmfile, fluxcd, argocd |
| Cloud CLIs | AWS, Azure, GCP, Cloudflare (`cloudflared`, `wrangler`) |
| IaC & secrets | OpenTofu (`terraform` alias), sops, age, tflint, tfsec, checkov, step-cli |
| SRE utilities | dive, lazydocker, grpcurl, httpie, yq, direnv, actionlint, pre-commit |

Shell shortcuts: `k`, `kns`, `kgp`, `kgpa`. Respects `KUBECONFIG`, `AWS_PROFILE`, and other cloud env vars.

## Optional: Home Manager aliases

Prefer [shell shortcuts](#4-shell-shortcuts-optional) if you already have a Home Manager setup and want to avoid merging alias changes into `~/.config/home-manager/home.nix`.

Alternatively, copy the template and customize the `USER CONFIGURATION` block:

```sh
mkdir -p ~/.config/home-manager
cp templates/home-manager/*.nix ~/.config/home-manager/
# edit flake.nix — username, paths, git identity
home-manager switch --flake ~/.config/home-manager#YOUR_USER
```

Then use:

```sh
nix-personal-default   # pinned
nix-personal-latest    # latest
nix-personal-devops    # devops / sre
```

See [templates/home-manager/README.md](./templates/home-manager/README.md) for coexistence notes with other Nix repos.

## Coexistence with other Nix repos

One Nix install serves all repos. Avoid conflicts by:

- **Separate profile names** — e.g. `personal-default`, `personal-latest`, `personal-ai`, `personal-devops` vs work profiles in `~/nix-workspace/`
- **Separate alias prefixes** — `nix-personal-*` vs work aliases
- **Git identity via `includeIf`** — don't rely on switching Home Manager for work vs personal email

## Creating a new shell

```nix
# flakes/my-project/flake.nix
{
  inputs = {
    base.url = "path:../../lib";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11"; # or nixpkgs-unstable
  };

  outputs = { base, nixpkgs }: {
    devShells.aarch64-darwin.default =
      let pkgs = import nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; };
      in base.lib.mkDevShell {
        system = "aarch64-darwin";
        inherit pkgs;
        node = true;
        java = true;
        title = "MY PROJECT";
        extraPackages = [ /* pkgs */ ];
      };
  };
}
```

### `mkDevShell` options

Languages and tools are **opt-in** (`false` by default). Defaults resolve against the flake's `pkgs` (pinned or unstable):

| Option | Default | When `true` |
|--------|---------|-------------|
| `java` | `false` | Temurin (`temurin-bin`, or `temurin-bin-25` with `useLatestDefaults`) |
| `maven` | `false` | Maven |
| `node` | `false` | Node.js (`nodejs`, or `nodejs_latest` with `useLatestDefaults`) |
| `pnpm` | `false` | pnpm |
| `yarn` | `false` | Yarn |
| `python` | `false` | Python 3 + pip + uv (`python3`, or `python314` with `useLatestDefaults`) |
| `go` | `false` | Go + gotools |
| `helm` | `false` | Kubernetes Helm |
| `kubectl` | `false` | kubectl |

Always included: ripgrep, fd, bat, eza, fzf, delta, gh, docker, nixd, and other common CLI tools.

Pass a package instead of `true` to pin a specific version (e.g. `node = pkgs.nodejs_20`).

## Updating

**Pinned shell** — update only when you want new stable versions:

```sh
cd /Users/eduardo/git/eduardo/nix-devshells
nix flake update flakes/default
```

**Latest shell** — update to pull newest nixpkgs packages:

```sh
cd /Users/eduardo/git/eduardo/nix-devshells
nix flake update --flake flakes/latest
```

Re-enter the shell to pick up changes.

## Testing

Run locally before opening a PR:

```sh
nix flake check ./lib
nix flake check ./flakes/default
nix flake check ./flakes/latest
nix flake check ./flakes/ai
nix flake check ./flakes/devops
nix develop ./flakes/default --command bash tests/smoke-default.sh
nix develop ./flakes/latest --command bash tests/smoke-latest.sh
nix develop ./flakes/ai --command bash tests/smoke-ai.sh
nix develop ./flakes/devops --command bash tests/smoke-devops.sh
```

## CI

GitHub Actions runs on every push to `main` and on pull requests ([`.github/workflows/ci.yml`](./.github/workflows/ci.yml)):

| Job | What it checks |
|-----|----------------|
| **flake check** | Evaluates `lib`, `flakes/default`, `flakes/latest`, `flakes/ai`, and `flakes/devops` |
| **smoke test** | Builds each dev shell on Linux and verifies required tools and version constraints |

To require CI before merge, enable branch protection on `main` and select the **flake check** and **smoke test** checks in GitHub repository settings.

## License

MIT — see [LICENSE](./LICENSE).
