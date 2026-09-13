{
  description = "All tools on nixpkgs-unstable (latest stable versions)";

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

            # Latest *stable* packaged versions (skips RCs such as Python 3.15.0rc2).
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
