{
  description = "General-purpose development environment (pinned nixos-26.05)";

  inputs = {
    base.url = "path:../../lib";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = { self, base, nixpkgs }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
    in {
      devShells = nixpkgs.lib.genAttrs supportedSystems (system:
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        in {
          default = base.lib.mkDevShell {
            inherit system pkgs;

            node = pkgs.nodejs_22;
            pnpm = true;
            python = pkgs.python312;
            go = pkgs.go_1_25;

            title = "NIX DEVSHELLS — DEFAULT";
            issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
            envVars = [ "GOPATH" ];
          };
        });
    };
}
