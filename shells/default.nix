# General-purpose development shell on the pinned stable channel.
#
# Versions track the pinned channel's *current* recommendations: Node's active
# LTS, the channel's default Python, and the newest packaged Go.
{ pkgs, mkDevShell }:

mkDevShell {
  inherit pkgs;

  node = pkgs.nodejs_24; # active LTS (EOL 2028-04)
  pnpm = true;
  python = pkgs.python313; # the channel's own python3
  go = pkgs.go_1_26;

  claudeCode = true;

  title = "NIX DEVSHELLS — DEFAULT";
  issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
  envVars = [ "GOPATH" ];
}
