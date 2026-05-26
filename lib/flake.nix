{
  description = "Reusable mkDevShell library for flake-based development environments";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }: {
    lib = rec {
      mkDevShell = {
        system,
        pkgs ? import nixpkgs { inherit system; config.allowUnfree = true; },

        # Languages: false = off, true = default package, or pass a package
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

        extraPackages ? [],

        title ? "DEV SHELL",
        issueUrl ? "",
        envVars ? [],
        shellHookExtra ? "",
        shellInitExtra ? "",

        # When true, `java = true` etc. resolve to the newest package attrs in pkgs
        useLatestDefaults ? false,

        graalvm ? false,
        graalvmHome ? null,
        graalvmHomeDarwin ? null,
        graalvmHomeLinux ? null,
      }:
      let
        isLinux = builtins.match ".*-linux" system != null;

        tryPkg = attr: fallback:
          if builtins.hasAttr attr pkgs then pkgs.${attr} else fallback;

        standardDefaults = {
          java = pkgs.temurin-bin;
          maven = pkgs.maven;
          node = pkgs.nodejs;
          pnpm = pkgs.pnpm;
          helm = pkgs.kubernetes-helm;
          helmDocs = pkgs.helm-docs;
          python = pkgs.python3;
          go = pkgs.go;
          kubectl = pkgs.kubectl;
        };

        latestDefaults = {
          java = tryPkg "temurin-bin-25" (tryPkg "temurin-bin-21" standardDefaults.java);
          maven = standardDefaults.maven;
          node = tryPkg "nodejs_latest" (tryPkg "nodejs_26" standardDefaults.node);
          pnpm = standardDefaults.pnpm;
          helm = standardDefaults.helm;
          helmDocs = standardDefaults.helmDocs;
          python = tryPkg "python314" (tryPkg "python313" standardDefaults.python);
          go = standardDefaults.go;
          kubectl = standardDefaults.kubectl;
        };

        defaults = if useLatestDefaults then latestDefaults else standardDefaults;

        resolve = enabled: defaultPkg: package:
          if package != false && package != null then
            if package == true then defaultPkg else package
          else
            null;

        resolvedJava = resolve java defaults.java java;
        resolvedMaven = resolve maven defaults.maven maven;
        resolvedNode = resolve node defaults.node node;
        resolvedPnpm = resolve pnpm defaults.pnpm pnpm;
        resolvedHelm = resolve helm defaults.helm helm;
        resolvedHelmDocs = resolve helmDocs defaults.helmDocs helmDocs;
        resolvedPython = resolve python defaults.python python;
        resolvedGo = resolve go defaults.go go;
        resolvedKubectl = resolve kubectl defaults.kubectl kubectl;

        pythonPackagesFor = py:
          let
            packagesAttr = "python${builtins.replaceStrings ["."] [""] py.pythonVersion}Packages";
          in
            if builtins.hasAttr packagesAttr pkgs then pkgs.${packagesAttr} else pkgs.python3Packages;

        packages = builtins.filter (p: p != null) [
          resolvedJava
          resolvedMaven
          resolvedNode
          resolvedPnpm
          (if yarn == true then pkgs.yarn else if yarn != false && yarn != null then yarn else null)
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
          pkgs.zlib
          pkgs.zlib.dev
          pkgs.zlib.out

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

          pkgs.gh
          pkgs.git-filter-repo
          pkgs.docker
          pkgs.nixd

          (if isLinux then pkgs.glibcLocales else null)
        ] ++ extraPackages;

        localeEnv = if isLinux then {
          LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
          LANG = "en_US.UTF-8";
        } else {};

        localeSetup = if isLinux then ''
          export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
          export LANG="en_US.UTF-8"
          unset LC_ALL 2>/dev/null || true
          unset JAVA_TOOL_OPTIONS 2>/dev/null || true
          case "$MAVEN_OPTS" in
            *"-Dfile.encoding="*) ;;
            *) export MAVEN_OPTS="''${MAVEN_OPTS:+$MAVEN_OPTS }-Dfile.encoding=UTF-8" ;;
          esac
        '' else ''
          unset JAVA_TOOL_OPTIONS 2>/dev/null || true
          case "$MAVEN_OPTS" in
            *"-Dfile.encoding="*) ;;
            *) export MAVEN_OPTS="''${MAVEN_OPTS:+$MAVEN_OPTS }-Dfile.encoding=UTF-8" ;;
          esac
        '';

        shellInit = ''
          if command -v python &> /dev/null; then
            if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
              if [ ! -d ".venv" ] && [ -w "." ]; then
                python -m venv .venv
              fi
              if [ -f ".venv/bin/activate" ]; then
                source .venv/bin/activate
              fi
            fi
          fi

          if command -v go &> /dev/null; then
            export GOPATH=$(go env GOPATH)
            export PATH=$GOPATH/bin:$PATH
          fi

          if [[ "$(uname)" == "Darwin" ]]; then
            export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
            export LDFLAGS="-L$SDKROOT/usr/lib"
            export CPPFLAGS="-I$SDKROOT/usr/include"
            export PKG_CONFIG_PATH="$SDKROOT/usr/lib/pkgconfig"

            if ! xcode-select -p >/dev/null 2>&1; then
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

        graalvmSetup =
          if graalvm && resolvedJava != null then ''
            if [[ "$(uname)" == "Darwin" ]]; then
              export JAVA_HOME="$(dirname "$(dirname "$(realpath "$(command -v java)")")")"
              ${if graalvmHome != null
                then "export GRAALVM_HOME=\"${graalvmHome}\""
                else if graalvmHomeDarwin != null
                  then "export GRAALVM_HOME=\"${graalvmHomeDarwin}\""
                  else ""}
              export GRAALVM_OPTS="-H:-CheckToolchain"
            else
              export JAVA_HOME="$(dirname "$(dirname "$(realpath "$(command -v java)")")")"
              ${if graalvmHomeLinux != null then "export GRAALVM_HOME=\"${graalvmHomeLinux}\"" else ""}
            fi

            [ -n "$JAVA_HOME" ] && [ -d "$JAVA_HOME/bin" ] && export PATH="$JAVA_HOME/bin:$PATH"
            [ -n "$GRAALVM_HOME" ] && [ -d "$GRAALVM_HOME/bin" ] && export PATH="$GRAALVM_HOME/bin:$PATH"
          '' else if resolvedJava != null then ''
            if [[ "$(uname)" == "Darwin" ]]; then
              export JAVA_HOME="$(dirname "$(dirname "$(realpath "$(command -v java)")")")"
            else
              export JAVA_HOME="$(dirname "$(dirname "$(realpath "$(command -v java)")")")"
            fi
            [ -n "$JAVA_HOME" ] && [ -d "$JAVA_HOME/bin" ] && export PATH="$JAVA_HOME/bin:$PATH"
          '' else "";

        envVarsStr = builtins.concatStringsSep " " envVars;

        printEnvInfo = ''
          print_tool_version() {
            local name="$1"
            local version="$2"
            printf "%-30s | %-60s\n" "$name" "$version"
          }

          echo "======================================================================================================================"
          printf "%*s%s\n" $(( (117 - ''${#title}) / 2 )) "" "${title}"
          echo "----------------------------------------------------------------------------------------------------------------------"
          ${if issueUrl != "" then ''echo "Report issues: ${issueUrl}"'' else ""}
          echo "======================================================================================================================"

          for var in ${envVarsStr}; do
            if [ -n "''${!var}" ]; then
              print_tool_version "$var" "''${!var}"
            fi
          done

          command -v java &>/dev/null && print_tool_version "Java version" "$(java -version 2>&1 | head -n 1)"
          command -v mvn &>/dev/null && print_tool_version "Maven version" "$(mvn --version 2>/dev/null | head -n 1)"
          command -v node &>/dev/null && print_tool_version "Node.js version" "$(node --version 2>/dev/null)"
          command -v npm &>/dev/null && print_tool_version "NPM version" "$(npm --version 2>/dev/null)"
          command -v pnpm &>/dev/null && print_tool_version "PNPM version" "$(pnpm --version 2>/dev/null)"
          command -v yarn &>/dev/null && print_tool_version "Yarn version" "$(yarn --version 2>/dev/null)"
          command -v python &>/dev/null && print_tool_version "Python version" "$(python --version 2>/dev/null)"
          command -v go &>/dev/null && print_tool_version "Go version" "$(go version 2>/dev/null | cut -d' ' -f3-4)"
          command -v docker &>/dev/null && print_tool_version "Docker version" "$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')"
          command -v helm &>/dev/null && print_tool_version "Helm version" "$(helm version --short 2>/dev/null)"
          command -v kubectl &>/dev/null && print_tool_version "kubectl version" "$(kubectl version --client 2>/dev/null | head -1)"

          echo "======================================================================================================================"
        '';

      in pkgs.mkShell {
        inherit packages;
        env = localeEnv // {
          SOURCE_DATE_EPOCH = "315532802";
        };

        shellHook = ''
          ${localeSetup}
          ${shellInit}
          ${graalvmSetup}
          ${shellHookExtra}

          title="${title}"
          ${printEnvInfo}
        '';
      };
    };
  };
}
