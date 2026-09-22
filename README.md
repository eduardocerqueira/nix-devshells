# nix-devshells

Reproducible dev shells for macOS and Linux — flake-based, profile-persisted.

A small Nix library (`mkDevShell`) plus ready-to-use development environments, exposed from a single flake. Designed to coexist with other Nix setups (e.g. work-specific repos) on the same machine.

## Shells

One flake, four shells. Select with `#<name>`.

| Shell | Channel | What it provides |
|-------|---------|------------------|
| `default` | `nixos-26.05` (pinned) | General development — Node 24 (LTS), Python 3.13, Go 1.26, pnpm, and common CLI tools |
| `latest` | `nixpkgs-unstable` | All optional languages and tools at the newest **stable** versions packaged in nixpkgs |
| `ai` | `nixos-26.05` (pinned) | AI / ML workflows — Ollama, Python 3.12 with Hugging Face, uv, ffmpeg, git-lfs |
| `devops` | `nixos-26.05` (pinned) | DevOps / SRE — Kubernetes, multi-cloud CLIs, OpenTofu, secrets, and platform utilities |

## Layout

| Path | Description |
|------|-------------|
| [flake.nix](./flake.nix) | The flake — `devShells`, `checks`, `formatter`, and the exported `lib` |
| [lib/default.nix](./lib/default.nix) | The shared `mkDevShell` builder (plain Nix, no inputs of its own) |
| [shells/](./shells/) | One file per shell: [default](./shells/default.nix), [latest](./shells/latest.nix), [ai](./shells/ai.nix), [devops](./shells/devops.nix) |
| [tests/](./tests/) | Smoke tests, run both as flake `checks` and through `nix develop` in CI; shared assertions in [common.sh](./tests/common.sh) |
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

Supported systems: `aarch64-darwin`, `x86_64-linux`, `aarch64-linux`. `x86_64-darwin` is deliberately excluded — nixpkgs 26.05 is the last release to support it.

## Prerequisites

- Nix with flakes enabled ([Determinate Nix](https://determinate.systems/) recommended on macOS)
- macOS: Xcode Command Line Tools for native builds (`xcode-select --install`)

## Quick start

### Without cloning

```sh
nix develop github:eduardocerqueira/nix-devshells#ai
```

Works for `#default`, `#latest`, `#ai`, and `#devops`.

### From a checkout

```sh
git clone https://github.com/eduardocerqueira/nix-devshells ~/git/nix-devshells
mkdir -p ~/.config/nix ~/nix-workspace
cp ~/git/nix-devshells/config/nix.conf ~/.config/nix/nix.conf   # if flakes aren't enabled yet
```

Enter a shell, persisting it as a profile so it survives garbage collection:

```sh
nix develop --profile ~/nix-workspace/personal-default ~/git/nix-devshells#default -c zsh -i
nix develop --profile ~/nix-workspace/personal-latest  ~/git/nix-devshells#latest  -c zsh -i
nix develop --profile ~/nix-workspace/personal-ai      ~/git/nix-devshells#ai      -c zsh -i
nix develop --profile ~/nix-workspace/personal-devops  ~/git/nix-devshells#devops  -c zsh -i
```

On first run Nix builds the environment; later runs reuse the profile. Exit with `exit`.

Re-enter an existing profile without touching the flake:

```sh
nix develop ~/nix-workspace/personal-default -c zsh -i
```

### Shell shortcuts

```sh
source ~/git/nix-devshells/nix-shortcut.sh
```

Then:

```sh
nix-default   # pinned general dev
nix-latest    # nixpkgs-unstable
nix-ai        # AI / ML
nix-devops    # DevOps / SRE
```

The script resolves the repo path automatically. Override with `NIX_DEVSHELLS_ROOT` or `NIX_DEVSHELLS_WORKSPACE`. To load shortcuts in every terminal, add the `source` line to `~/.zshrc` (or `~/.bashrc`).

### direnv

A [`.envrc`](./.envrc) is included. In any project:

```sh
echo 'use flake github:eduardocerqueira/nix-devshells#devops' > .envrc
direnv allow
```

## Available shells

### `default` — pinned

Tracks **`nixos-26.05`** (locked in `flake.lock`). Versions stay put until you update the lock.

| Tool | Version |
|------|---------|
| Node.js | 24.x — active LTS (EOL 2028-04) |
| Python | 3.13 — the channel's own `python3` |
| Go | 1.26 |
| pnpm | from nixos-26.05 |

Also includes the [shared bundle](#the-shared-bundle).

### `latest` — newest stable in nixpkgs

Tracks **`nixpkgs-unstable`** with `useLatestDefaults = true`: each tool resolves to the highest **stable** version packaged in nixpkgs. Prereleases are skipped, so while Python 3.15 is at RC the shell gives you 3.14.

| Tool | Package attr | Latest stable (approx.) |
|------|--------------|-------------------------|
| Java | `temurin-bin-26` | 26.0.x |
| Python | `python314` (skips `python315` while RC) | 3.14.x |
| Node.js | `nodejs_latest` | 26.x |
| Go | `go` | 1.26.x |
| Yarn | `yarn-berry` | 4.x — **not** Yarn Classic 1.22 |
| Helm | `kubernetes-helm` | **4.x** — note the major bump vs. the pinned shells' Helm 3 |
| Maven, pnpm, kubectl | defaults | latest stable in unstable |

**Note:** Nix only ships what is packaged in [nixpkgs](https://github.com/NixOS/nixpkgs). `latest` always prefers the newest **final** release available there — not alphas, betas, or RCs.

### `ai` — AI / ML

Tracks **`nixos-26.05`**. Python 3.12 with Hugging Face libraries; heavy ML deps (torch, transformers, …) are added per-project via `uv`.

| Tool / area | Included |
|-------------|----------|
| Local LLMs | Ollama (`OLLAMA_HOST`, `OLLAMA_MODELS` configured on enter) |
| Python | 3.12 + uv + pip; `huggingface-hub` (`hf` CLI) |
| Hugging Face | `hf` Hub CLI; set `HF_TOKEN` for gated models |
| Media & storage | ffmpeg, git-lfs |

### `devops` — DevOps / SRE

Tracks **`nixos-26.05`**. Kubernetes-first shell with multi-cloud CLIs and infrastructure tooling.

| Tool / area | Included |
|-------------|----------|
| Kubernetes | kubectl, helm, k9s, kubectx, stern, kubecolor, helmfile, fluxcd, argocd, kustomize, kubeconform, kind |
| Cloud CLIs | AWS, Azure, GCP, Cloudflare (`cloudflared`, `wrangler`) |
| IaC & secrets | OpenTofu (`terraform` wrapper), sops, age, tflint, trivy, cosign, checkov, step-cli, terraform-docs |
| SRE utilities | dive, lazydocker, grpcurl, httpie, yq, actionlint, pre-commit |

Shortcuts `k`, `kns`, `kgp`, `kgpa` and the `terraform` → `tofu` wrapper are real packages in the shell's closure, so they work under any shell and leave nothing behind in `/tmp`.

`tfsec` is **not** included: it is end-of-life upstream ("Tfsec is now part of Trivy"). Use `trivy config .` in its place.

## Environment variables

| Variable | Effect |
|----------|--------|
| `NIX_DEVSHELL_QUIET` | Set to any value to suppress the banner and project-detection hints |
| `NIX_DEVSHELLS_ROOT` | Override the repo path used by `nix-shortcut.sh` |
| `NIX_DEVSHELLS_WORKSPACE` | Override the profile directory (default `~/nix-workspace`) |

## Optional: Home Manager aliases

Prefer the [shell shortcuts](#shell-shortcuts) if you already have a Home Manager setup. Otherwise copy the template and customize the `USER CONFIGURATION` block:

```sh
mkdir -p ~/.config/home-manager
cp templates/home-manager/*.nix ~/.config/home-manager/
# edit flake.nix — username, paths, git identity
home-manager switch --flake ~/.config/home-manager#YOUR_USER
```

Then use `nix-personal-default`, `nix-personal-latest`, `nix-personal-ai`, or `nix-personal-devops`.

See [templates/home-manager/README.md](./templates/home-manager/README.md) for coexistence notes.

## Coexistence with other Nix repos

One Nix install serves all repos. Avoid conflicts by:

- **Separate profile names** — `personal-default`, `personal-latest`, … vs work profiles in `~/nix-workspace/`
- **Separate alias prefixes** — `nix-personal-*` vs work aliases
- **Git identity via `includeIf`** — don't rely on switching Home Manager for work vs personal email

## Using `mkDevShell` elsewhere

The builder is exported as a flake output, so other repos can consume it without copying anything:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nix-devshells.url = "github:eduardocerqueira/nix-devshells";
  };

  outputs = { nixpkgs, nix-devshells, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in {
      devShells.${system}.default = nix-devshells.lib.mkDevShell {
        inherit pkgs;
        node = true;
        java = true;
        title = "MY PROJECT";
        extraPackages = [ pkgs.postgresql ];
      };
    };
}
```

`mkDevShell` has **no nixpkgs input of its own** — you pass `pkgs`, so it never adds a second nixpkgs to your lock file.

### `mkDevShell` options

Languages and tools are **opt-in** (`false` by default) and resolve against the `pkgs` you pass.

| Option | Default | When `true` |
|--------|---------|-------------|
| `pkgs` | *(required)* | The package set to build against |
| `java` | `false` | Temurin (`temurin-bin`, or `temurin-bin-26` with `useLatestDefaults`) |
| `maven` | `false` | Maven |
| `node` | `false` | Node.js (`nodejs`, or `nodejs_latest` with `useLatestDefaults`) |
| `pnpm` | `false` | pnpm |
| `yarn` | `false` | Yarn Classic (or `yarn-berry` 4.x with `useLatestDefaults`) |
| `python` | `false` | Python 3 + pip + uv |
| `go` | `false` | Go + gotools |
| `helm` / `helmDocs` | `false` | Kubernetes Helm / helm-docs |
| `kubectl` | `false` | kubectl |
| `claudeCode` | `false` | Claude Code (`claude`) — **unfree**, see below |

Pass a package instead of `true` to pin a version (e.g. `node = pkgs.nodejs_22`).

| Option | Default | Effect |
|--------|---------|--------|
| `extraPackages` | `[]` | Additional packages |
| `extraVersions` | `[]` | Extra banner rows: `[ { name = "OpenTofu"; package = pkgs.opentofu; } ]` |
| `title` / `issueUrl` | — | Banner header |
| `envVars` | `[]` | Environment variables to show in the banner when set |
| `shellHookExtra` / `shellInitExtra` | `""` | Extra shell code |
| `autoVenv` | `false` | Create and activate `./.venv` when a Python project is detected |
| `useLatestDefaults` | `false` | Resolve toggles to the newest *stable* packages in `pkgs` |
| `graalvm`, `graalvmHome*` | `false` / `null` | GraalVM `GRAALVM_HOME` wiring |

### The shared bundle

Every shell gets these regardless of toggles:

| Group | Tools |
|-------|-------|
| Git | git, gh, git-filter-repo, lazygit, difftastic (`difft`), gitleaks |
| AI | Claude Code (`claude`) |
| Nix | nixd (LSP), nixfmt, statix, deadnix |
| Shell | shellcheck, shfmt |
| Workflow | direnv, just, docker |
| Search & files | ripgrep, fd, bat, eza, fzf, delta, tree, jq, curl, wget |
| System | htop, tldr, dust, duf, make, gnupg, pkg-config |

The Nix and shell groups exist so this repo's own CI lint pass is reproducible from inside any shell — `nixfmt`, `statix`, `deadnix`, `shellcheck` and `shfmt` are exactly what CI runs. They add ~800 MiB of closure across all shells.

`openssh` is deliberately **not** included: nixpkgs' ssh lacks Apple's `UseKeychain` option, so shadowing `/usr/bin/ssh` breaks macOS `~/.ssh/config` files that use it.

**`claudeCode` is off by default and on in all four shells here.** The package is unfree, and forcing its output path without `config.allowUnfree = true` throws — so enabling it unconditionally in the library would break any consumer that has not opted in. Enable it with `claudeCode = true;` and an unfree-permitting `pkgs`.

The nixpkgs wrapper sets `DISABLE_AUTOUPDATER=1`, so `claude` will **not** update itself in these shells; it moves with the channel. The pinned shells therefore lag `latest` by whatever the channel lag is (2.1.223 vs 2.1.278 at the time of writing). Run `nix flake update nixpkgs` to pick up a newer one.

**`autoVenv` is off by default.** It writes a `.venv/` into whatever directory you enter the shell from, which surprises `uv`-managed projects. Turn it on per shell if you want the old behaviour.

**The banner is generated at evaluation time** from the packages the shell actually provides, so it can never report a tool that merely happens to be on your host `PATH` — and entering a shell spawns no subprocesses to collect versions.

## Updating

```sh
cd ~/git/nix-devshells
nix flake update                    # both nixpkgs inputs
nix flake update nixpkgs-unstable   # just the `latest` shell's channel
nix flake update nixpkgs            # just the pinned channel
```

Positional arguments to `nix flake update` are **input names**, not paths. To update a flake in another directory, use `--flake`:

```sh
nix flake update --flake ~/git/nix-devshells
```

After updating, re-enter the shell so the profile picks up the new closure.

## Testing

```sh
nix flake check --all-systems     # evaluate every system + run every smoke test
nix fmt                           # format all .nix files (nixfmt)
```

`--all-systems` matters: without it, Nix only evaluates outputs for the machine you are on, so a Darwin-only error stays invisible on Linux and vice versa.

Run one smoke test against a real shell (this also exercises the `shellHook`):

```sh
nix develop .#default --command bash tests/smoke-default.sh
nix develop .#latest  --command bash tests/smoke-latest.sh
nix develop .#ai      --command bash tests/smoke-ai.sh
nix develop .#devops  --command bash tests/smoke-devops.sh
```

## CI

GitHub Actions ([`.github/workflows/ci.yml`](./.github/workflows/ci.yml)) runs on push to `main`, on pull requests, weekly on a schedule, and on demand.

| Job | What it checks |
|-----|----------------|
| **flake check** | `nix flake check --all-systems --no-build` on Linux **and** macOS |
| **smoke test** | Each of the four shells entered via `nix develop` on Linux **and** macOS |
| **shellcheck** | All scripts in `tests/` plus `nix-shortcut.sh` |

The weekly schedule exists because `latest` tracks `nixpkgs-unstable`: without it, upstream breakage would only surface the next time someone pushed.

To require CI before merge, enable branch protection on `main` and select these checks in repository settings.

## License

MIT — see [LICENSE](./LICENSE).
