{
  description = "All tools on nixpkgs-unstable (latest versions)";

  inputs = {
    base.url = "path:../../lib";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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

            useLatestDefaults = true;

            java = true;
            maven = true;
            node = true;
            pnpm = true;
            yarn = true;
            helm = true;
            helmDocs = true;
            python = true;
            go = true;
            kubectl = true;

            title = "NIX DEVSHELLS — LATEST";
            issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
            envVars = [ "JAVA_HOME" "GOPATH" ];
          };
        });
    };
}
