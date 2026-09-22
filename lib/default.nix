# mkDevShell — shared dev shell builder for nix-devshells.
#
# Imported directly by the root flake (and by any consumer via
# `nix-devshells.lib.mkDevShell`). Deliberately *not* a flake: it has no inputs
# of its own, so callers never drag a second nixpkgs into their lock file.
{
  # Required. The caller decides which nixpkgs (pinned or unstable) to use.
  pkgs,

  # Languages: false = off, true = default package, or pass a package.
  java ? false,
  maven ? false,
  node ? false,
  pnpm ? false,
  yarn ? false,
  helm ? false,
  helmDocs ? false,
  python ? false,
  go ? false,
  kubectl ? false,

  # Claude Code. Off by default because the package is unfree: forcing its
  # outPath without `config.allowUnfree = true` throws, which would break any
  # consumer of this library that has not opted in. The four shells in this
  # repo all enable it.
  claudeCode ? false,

  extraPackages ? [ ],

  # Extra rows for the banner: [ { name = "OpenTofu"; package = pkgs.opentofu; } ]
  extraVersions ? [ ],

  title ? "DEV SHELL",
  issueUrl ? "",
  envVars ? [ ],
  shellHookExtra ? "",
  shellInitExtra ? "",

  # Create and activate ./.venv when a Python project is detected. Off by
  # default: it writes into the user's working directory, and `uv` manages its
  # own virtualenv.
  autoVenv ? false,

  # When true, language toggles resolve to the newest *stable* packages in pkgs
  # (skips prereleases such as Python 3.15.0rc2).
  useLatestDefaults ? false,

  graalvm ? false,
  graalvmHome ? null,
  graalvmHomeDarwin ? null,
  graalvmHomeLinux ? null,
}:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  # Reject alpha / beta / rc / .dev versions so "latest" means latest stable.
  isPreRelease =
    version: builtins.match ".*(rc|alpha|beta|dev|[.]a[0-9]+|[.]b[0-9]+).*" version != null;

  # First existing attr whose .version is a final (non-prerelease) release.
  pickFirstStable =
    candidates: fallback:
    if candidates == [ ] then
      fallback
    else
      let
        attr = builtins.head candidates;
        rest = builtins.tail candidates;
        candidate =
          if !(builtins.hasAttr attr pkgs) then
            null
          else
            let
              pkg = pkgs.${attr};
              ver = pkg.version or "";
            in
            if ver == "" || isPreRelease ver then null else pkg;
      in
      if candidate != null then candidate else pickFirstStable rest fallback;

  standardDefaults = {
    java = pkgs.temurin-bin;
    maven = pkgs.maven;
    node = pkgs.nodejs;
    pnpm = pkgs.pnpm;
    yarn = pkgs.yarn;
    helm = pkgs.kubernetes-helm;
    helmDocs = pkgs.helm-docs;
    python = pkgs.python3;
    go = pkgs.go;
    kubectl = pkgs.kubectl;
  };

  # Highest numbered / newest attrs first; prereleases are skipped automatically.
  latestDefaults = standardDefaults // {
    java = pickFirstStable [
      "temurin-bin-27"
      "temurin-bin-26"
      "temurin-bin-25"
      "temurin-bin-21"
    ] standardDefaults.java;
    node = pickFirstStable [ "nodejs_latest" "nodejs_26" "nodejs_24" ] standardDefaults.node;
    python = pickFirstStable [
      "python316"
      "python315"
      "python314"
      "python313"
    ] standardDefaults.python;
    # yarn-berry is Yarn 4.x; pkgs.yarn is Yarn Classic 1.22 (maintenance only).
    yarn = pickFirstStable [ "yarn-berry" ] standardDefaults.yarn;
  };

  defaults = if useLatestDefaults then latestDefaults else standardDefaults;

  # false/null => off, true => the default package, anything else => that package.
  resolve =
    defaultPkg: choice:
    if choice == false || choice == null then
      null
    else if choice == true then
      defaultPkg
    else
      choice;

  resolvedJava = resolve defaults.java java;
  resolvedMaven = resolve defaults.maven maven;
  resolvedNode = resolve defaults.node node;
  resolvedPnpm = resolve defaults.pnpm pnpm;
  resolvedYarn = resolve defaults.yarn yarn;
  resolvedHelm = resolve defaults.helm helm;
  resolvedHelmDocs = resolve defaults.helmDocs helmDocs;
  resolvedPython = resolve defaults.python python;
  resolvedGo = resolve defaults.go go;
  resolvedKubectl = resolve defaults.kubectl kubectl;
  resolvedClaudeCode = resolve pkgs.claude-code claudeCode;

  pythonPackagesFor =
    py:
    let
      packagesAttr = "python${builtins.replaceStrings [ "." ] [ "" ] py.pythonVersion}Packages";
    in
    if builtins.hasAttr packagesAttr pkgs then pkgs.${packagesAttr} else pkgs.python3Packages;

  packages =
    builtins.filter (p: p != null) [
      resolvedJava
      resolvedMaven
      resolvedNode
      resolvedPnpm
      resolvedYarn
      resolvedHelm
      resolvedHelmDocs
      resolvedPython
      (if resolvedPython != null then (pythonPackagesFor resolvedPython).pip else null)
      (if resolvedPython != null then pkgs.uv else null)
      resolvedGo
      (if resolvedGo != null then pkgs.gotools else null)
      resolvedKubectl

      pkgs.gnumake
      pkgs.gnupg
      pkgs.pkg-config

      pkgs.coreutils
      pkgs.curl
      pkgs.wget
      pkgs.jq
      pkgs.tree

      pkgs.ripgrep
      pkgs.fd
      pkgs.bat
      pkgs.eza
      pkgs.fzf
      pkgs.delta
      pkgs.htop
      pkgs.tldr
      pkgs.dust
      pkgs.duf

      resolvedClaudeCode

      # git itself was missing: `delta` (a git pager), `gh` and git-filter-repo
      # were all here, but `git` fell through to whatever the host had.
      pkgs.git
      pkgs.gh
      pkgs.git-filter-repo
      pkgs.docker
      pkgs.nixd

      (if isLinux then pkgs.glibcLocales else null)
    ]
    ++ extraPackages;

  # Libraries to link against belong in buildInputs, not in packages/nativeBuildInputs.
  buildInputs = [ pkgs.zlib ];

  localeEnv =
    if isLinux then
      {
        LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
        LANG = "en_US.UTF-8";
      }
    else
      { };

  mavenEncoding = ''
    unset JAVA_TOOL_OPTIONS 2>/dev/null || true
    case "$MAVEN_OPTS" in
      *"-Dfile.encoding="*) ;;
      *) export MAVEN_OPTS="''${MAVEN_OPTS:+$MAVEN_OPTS }-Dfile.encoding=UTF-8" ;;
    esac
  '';

  localeSetup =
    pkgs.lib.optionalString isLinux ''
      export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
      export LANG="en_US.UTF-8"
      unset LC_ALL 2>/dev/null || true
    ''
    + mavenEncoding;

  venvSetup = pkgs.lib.optionalString (autoVenv && resolvedPython != null) ''
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
      if [ ! -d ".venv" ] && [ -w "." ]; then
        "${resolvedPython}/bin/python" -m venv .venv
      fi
      if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
      fi
    fi
  '';

  shellInit = ''
    ${venvSetup}

    if command -v go &> /dev/null; then
      export GOPATH=$(go env GOPATH)
      export PATH=$GOPATH/bin:$PATH
    fi

    if [[ "$(uname)" == "Darwin" ]]; then
      if xcode-select -p >/dev/null 2>&1; then
        export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
        export LDFLAGS="-L$SDKROOT/usr/lib"
        export CPPFLAGS="-I$SDKROOT/usr/include"
        export PKG_CONFIG_PATH="$SDKROOT/usr/lib/pkgconfig"
      else
        echo "Warning: Xcode CLI tools are not installed. Run: xcode-select --install"
      fi
    fi

    if command -v pkg-config &> /dev/null && pkg-config --exists zlib 2>/dev/null; then
      export LDFLAGS="$LDFLAGS $(pkg-config --libs-only-L zlib)"
      export CPPFLAGS="$CPPFLAGS $(pkg-config --cflags zlib)"
      export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$(dirname $(pkg-config --variable=libdir zlib))/pkgconfig"
    fi

    if command -v pkg-config &> /dev/null && pkg-config --exists cairo 2>/dev/null; then
      CAIRO_LIBDIR="$(pkg-config --variable=libdir cairo)"
      export DYLD_LIBRARY_PATH="''${CAIRO_LIBDIR}:''${DYLD_LIBRARY_PATH}"
      export PKG_CONFIG_PATH="''${CAIRO_LIBDIR}/pkgconfig:''${PKG_CONFIG_PATH}"
    fi

    ${shellInitExtra}
  '';

  # JAVA_HOME comes from the store path we resolved, not from `command -v java`,
  # so an unrelated JDK on the host PATH cannot hijack it.
  javaSetup = pkgs.lib.optionalString (resolvedJava != null) (
    ''
      export JAVA_HOME="${resolvedJava.home or resolvedJava}"
      [ -d "$JAVA_HOME/bin" ] && export PATH="$JAVA_HOME/bin:$PATH"
    ''
    + pkgs.lib.optionalString graalvm (
      let
        graalHomeFor =
          explicit:
          if graalvmHome != null then
            ''export GRAALVM_HOME="${graalvmHome}"''
          else if explicit != null then
            ''export GRAALVM_HOME="${explicit}"''
          else
            "";
      in
      ''
        if [[ "$(uname)" == "Darwin" ]]; then
          ${graalHomeFor graalvmHomeDarwin}
          export GRAALVM_OPTS="-H:-CheckToolchain"
        else
          ${graalHomeFor graalvmHomeLinux}
        fi
        [ -n "''${GRAALVM_HOME:-}" ] && [ -d "$GRAALVM_HOME/bin" ] && export PATH="$GRAALVM_HOME/bin:$PATH"
      ''
    )
  );

  # ---------------------------------------------------------------------------
  # Banner. Rendered at evaluation time from the packages this shell actually
  # provides, so it can never report a tool that merely happens to be on the
  # host PATH. No subprocesses, no JVM start-up on shell entry.
  # ---------------------------------------------------------------------------
  repeat =
    char: n: builtins.concatStringsSep "" (builtins.genList (_: char) (if n < 0 then 0 else n));
  pad = repeat " ";
  padTo = n: s: s + pad (n - builtins.stringLength s);

  bannerWidth = 118;
  rule = repeat "=" bannerWidth;
  thinRule = repeat "-" bannerWidth;
  centered = s: pad ((bannerWidth - builtins.stringLength s) / 2) + s;

  versionRow =
    name: pkg: if pkg == null then null else padTo 30 name + " | " + (pkg.version or "unknown");

  versionRows = builtins.filter (r: r != null) (
    [
      (versionRow "Java" resolvedJava)
      (versionRow "Maven" resolvedMaven)
      (versionRow "Node.js" resolvedNode)
      (versionRow "pnpm" resolvedPnpm)
      (versionRow "Yarn" resolvedYarn)
      (versionRow "Python" resolvedPython)
      (versionRow "Go" resolvedGo)
      (versionRow "Helm" resolvedHelm)
      (versionRow "helm-docs" resolvedHelmDocs)
      (versionRow "kubectl" resolvedKubectl)
      (versionRow "Docker CLI" pkgs.docker)
      (versionRow "git" pkgs.git)
      (versionRow "Claude Code" resolvedClaudeCode)
    ]
    ++ map (e: versionRow e.name e.package) extraVersions
  );

  bannerHead = builtins.concatStringsSep "\n" (
    [
      rule
      (centered title)
      thinRule
    ]
    ++ pkgs.lib.optional (issueUrl != "") "Report issues: ${issueUrl}"
    ++ [ rule ]
  );

  bannerTools = builtins.concatStringsSep "\n" (versionRows ++ [ rule ]);

  envVarsStr = builtins.concatStringsSep " " envVars;

  printEnvInfo = ''
    if [ -z "''${NIX_DEVSHELL_QUIET:-}" ]; then
      cat <<'__NIX_DEVSHELL_BANNER_HEAD__'
    ${bannerHead}
    __NIX_DEVSHELL_BANNER_HEAD__

      for var in ${envVarsStr}; do
        if [ -n "''${!var:-}" ]; then
          printf "%-30s | %-60s\n" "$var" "''${!var}"
        fi
      done

      cat <<'__NIX_DEVSHELL_BANNER_TOOLS__'
    ${bannerTools}
    __NIX_DEVSHELL_BANNER_TOOLS__
    fi
  '';

in
pkgs.mkShell {
  inherit packages buildInputs;

  env = localeEnv // {
    SOURCE_DATE_EPOCH = "315532802";
  };

  passthru = {
    # Consumed by the root flake's `checks` so smoke tests can run against the
    # exact package set of each shell.
    devShellPackages = packages;
  };

  shellHook = ''
    ${localeSetup}
    ${shellInit}
    ${javaSetup}
    ${shellHookExtra}
    ${printEnvInfo}
  '';
}
