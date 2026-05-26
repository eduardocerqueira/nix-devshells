# Home Manager template

Optional template for shell aliases. Copy to your machine — do not commit personal values to this repo.

```sh
mkdir -p ~/.config/home-manager
cp templates/home-manager/*.nix ~/.config/home-manager/
```

Edit the `USER CONFIGURATION` block in `flake.nix`, then:

```sh
home-manager switch --flake ~/.config/home-manager#YOUR_USER
```

## Coexistence with other Nix repos

Use separate profile names under `~/nix-workspace/` (e.g. `personal-default` vs work profiles).
For git identity, prefer conditional config with `includeIf` instead of switching Home Manager.
