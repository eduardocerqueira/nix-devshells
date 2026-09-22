# Every optional tool at the newest *stable* version packaged in nixpkgs.
#
# Built against nixpkgs-unstable. `useLatestDefaults` walks a candidate list per
# tool and skips prereleases, so Python resolves to 3.14.x while 3.15 is an RC,
# and Yarn resolves to yarn-berry (4.x) rather than Yarn Classic 1.22.
{ pkgs, mkDevShell }:

mkDevShell {
  inherit pkgs;

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

  claudeCode = true;

  title = "NIX DEVSHELLS — LATEST";
  issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
  envVars = [
    "JAVA_HOME"
    "GOPATH"
  ];
}
