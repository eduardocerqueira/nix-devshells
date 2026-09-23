# Home Manager template

Optional template for shell aliases. Copy to your machine — do not commit personal values to this repo.

```sh
mkdir -p ~/.config/home-manager
cp templates/home-manager/*.nix ~/.config/home-manager/
```

Edit the `USER CONFIGURATION` block in `flake.nix` (username, paths, git identity), then:

```sh
home-manager switch --flake ~/.config/home-manager#YOUR_USER
```

This adds four aliases, one per shell:

```sh
nix-personal-app   nix-personal-edge   nix-personal-ai   nix-personal-devops
```

Each one is `nix develop --profile ~/nix-workspace/personal-<name> <repo>#<name> -c zsh -i`.
If you would rather not touch your Home Manager config, source
[`nix-shortcut.sh`](../../nix-shortcut.sh) instead — same shells, no rebuild.

## Coexistence with other Nix repos

Use separate profile names under `~/nix-workspace/` (e.g. `personal-app` vs work profiles).
For git identity, prefer conditional config with `includeIf` instead of switching Home Manager.
