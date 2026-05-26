{
  description = "General-purpose development environment";

  inputs = {
    base.url = "path:../../lib";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
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
      devShells = nixpkgs.lib.genAttrs supportedSystems (system: {
        default = base.lib.mkDevShell {
          inherit system;

          node = true;
          pnpm = true;
          python = true;
          go = true;

          title = "NIX DEVSHELLS — DEFAULT";
          issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
          envVars = [ "JAVA_HOME" "GOPATH" ];
        };
      });
    };
}
