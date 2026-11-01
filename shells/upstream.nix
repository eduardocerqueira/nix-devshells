# Upstream open-source contribution — the hygiene tools maintainers run in CI
# (spelling, licensing headers, markdown/YAML/workflow lint) so a PR passes
# them before it is pushed, plus the common languages at the pinned channel's
# defaults. Project-specific toolchains belong in a dedicated shell, as with
# `kubernetes`.
{ pkgs, mkDevShell }:

mkDevShell {
  inherit pkgs;

  node = true;
  python = true;
  go = true;

  claudeCode = true;

  title = "NIX DEVSHELLS — UPSTREAM";
  issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
  envVars = [ "GOPATH" ];

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
      name = "pre-commit";
      package = pkgs.pre-commit;
    }
    {
      name = "act";
      package = pkgs.act;
    }
  ];
}
