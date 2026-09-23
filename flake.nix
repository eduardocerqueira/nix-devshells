{
  description = "Reproducible dev shells for macOS and Linux — flake-based, profile-persisted";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
    }:
    let
      # x86_64-darwin is intentionally absent: nixpkgs 26.05 is the last release
      # to support it.
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkDevShell = import ./lib;

      pkgsFrom =
        input: system:
        import input {
          inherit system;
          config.allowUnfree = true;
        };

      # Which nixpkgs each shell is built against.
      shellsFor =
        system:
        let
          stable = pkgsFrom nixpkgs system;
          unstable = pkgsFrom nixpkgs-unstable system;
          load = file: pkgs: import file { inherit pkgs mkDevShell; };
        in
        rec {
          app = load ./shells/app.nix stable;
          edge = load ./shells/edge.nix unstable;
          ai = load ./shells/ai.nix stable;
          devops = load ./shells/devops.nix stable;

          # `devShells.<system>.default` is what a bare `nix develop` (and
          # `nix develop github:eduardocerqueira/nix-devshells`) resolves to.
          # Same derivation as `app`, just reachable without an attribute.
          default = app;
        };

      # The whole directory, not individual files: the smoke tests source
      # tests/common.sh, which has to land in the store beside them.
      testsDir = ./tests;
    in
    {
      # Consumers: inputs.nix-devshells.lib.mkDevShell { pkgs = ...; node = true; }
      lib = { inherit mkDevShell; };

      devShells = forAllSystems shellsFor;

      # Each smoke test also runs as a real derivation, so `nix flake check`
      # exercises the tools instead of only evaluating the shells. CI still runs
      # the same scripts through `nix develop`, which additionally covers the
      # shellHook.
      checks = forAllSystems (
        system:
        let
          shells = shellsFor system;
          stable = pkgsFrom nixpkgs system;
          unstable = pkgsFrom nixpkgs-unstable system;

          smoke =
            pkgs: name:
            pkgs.runCommand "smoke-${name}"
              {
                nativeBuildInputs = shells.${name}.devShellPackages;
              }
              ''
                export HOME="$TMPDIR/home"
                mkdir -p "$HOME"
                export CHECKPOINT_DISABLE=1
                export DO_NOT_TRACK=1
                bash ${testsDir}/smoke-${name}.sh
                touch "$out"
              '';
        in
        {
          # No smoke-default: `default` is an alias of `app`, so it would
          # rebuild the identical derivation under a second name.
          smoke-app = smoke stable "app";
          smoke-edge = smoke unstable "edge";
          smoke-ai = smoke stable "ai";
          smoke-devops = smoke stable "devops";

          # shellcheck is not in the shells any more (Haskell runtime), so the
          # repo lints itself here instead: `nix flake check` covers it.
          shellcheck =
            stable.runCommand "check-shellcheck"
              {
                nativeBuildInputs = [ stable.shellcheck ];
              }
              ''
                shellcheck -x ${testsDir}/*.sh ${self}/nix-shortcut.sh
                touch "$out"
              '';

          format =
            stable.runCommand "check-nixfmt"
              {
                nativeBuildInputs = [ stable.nixfmt ];
              }
              ''
                # Covers every .nix file in the repo, including new ones.
                find ${self} -name '*.nix' -print0 | sort -z | xargs -0 nixfmt --check
                touch "$out"
              '';
        }
      );

      formatter = forAllSystems (system: (pkgsFrom nixpkgs system).nixfmt);
    };
}
