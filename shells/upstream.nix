# Upstream open-source contribution — the hygiene tools maintainers run in CI
# (spelling, licensing headers, markdown/YAML/workflow lint) so a PR passes
# them before it is pushed, plus the common languages at the pinned channel's
# defaults. Project-specific toolchains belong in a dedicated shell, as with
# `kubernetes`.
{ pkgs, mkDevShell }:

let
  # Off PATH on purpose: Java 21 is `java`; 17 is only reachable through
  # JAVA17_HOME, for projects (and Maven toolchains) that still build on it.
  java17 = pkgs.temurin-bin-17;
in
mkDevShell {
  inherit pkgs;

  java = pkgs.temurin-bin-21;
  maven = true;
  node = true;
  pnpm = true;
  yarn = true; # Classic 1.22, which most yarn.lock files in the wild still are
  python = true;
  go = true;
  helm = true;
  kubectl = true;

  claudeCode = true;

  title = "NIX DEVSHELLS — UPSTREAM";
  issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
  envVars = [
    "JAVA_HOME"
    "JAVA17_HOME"
    "GOPATH"
  ];

  extraPackages = with pkgs; [
    # Contribution workflow
    pre-commit
    git-absorb # `git absorb` folds review fixes into the right commits
    gh-dash # PRs and issues across repos, in the terminal
    act # run a project's GitHub Actions locally (uses docker)

    # What upstream CI usually checks
    codespell
    typos
    markdownlint-cli2
    yamllint
    actionlint
    editorconfig-checker
    reuse # REUSE / SPDX licence headers
    commitizen # conventional-commit projects

    scc # size up an unfamiliar codebase
  ];

  extraVersions = [
    {
      name = "Java 17 (JAVA17_HOME)";
      package = java17;
    }
    {
      name = "pre-commit";
      package = pkgs.pre-commit;
    }
    {
      name = "act";
      package = pkgs.act;
    }
  ];

  shellHookExtra = ''
    export JAVA17_HOME="${java17.home or java17}"
  '';
}
