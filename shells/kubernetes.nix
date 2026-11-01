# Kubernetes contributor shell — kubernetes/kubernetes, kubernetes/minikube and
# kubernetes/website from one environment.
#
# Go follows minikube's go.mod (1.27); kubernetes/kubernetes pins its exact
# toolchain in .go-version and fetches it through GOTOOLCHAIN when it differs.
{ pkgs, mkDevShell }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  # kubernetes/website pins Hugo in netlify.toml (HUGO_VERSION) and its
  # Makefile builds the container image from the same value. Newer Hugo
  # releases change rendering and break the docsy theme, so this must match
  # exactly — bump it together with website/netlify.toml.
  #
  # minikube's site pins its own (newer) Hugo, but `make site` there builds
  # that one into out/hugo from source, so it never uses this binary.
  hugoWebsite = pkgs.hugo.overrideAttrs (_: rec {
    version = "0.144.2";
    src = pkgs.fetchFromGitHub {
      owner = "gohugoio";
      repo = "hugo";
      tag = "v${version}";
      hash = "sha256-LQfNiuzD36uwdLsqw4dNf9hwfMNOSfH83bbo+Huk7v0=";
    };
    vendorHash = "sha256-3IY8yYwFS9lYqjjxEwBwLMn6ZVm4DlX1F9OItSmJYNs=";
    # The channel's skip list targets the channel's Hugo; this release's test
    # suite reaches the network in other places.
    doCheck = false;
  });
in
mkDevShell {
  inherit pkgs;

  go = pkgs.go_1_27;
  # website: postcss/autoprefixer through npm; minikube's site asks for 24.
  # Node 20 (website's netlify.toml) is end-of-life and marked insecure.
  node = pkgs.nodejs_24;
  # website/scripts and kubernetes/hack/boilerplate are Python.
  python = true;
  kubectl = true;

  claudeCode = true;

  title = "NIX DEVSHELLS — KUBERNETES";
  issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
  envVars = [
    "GOPATH"
    "KUBECONFIG"
    "MINIKUBE_HOME"
  ];

  extraPackages =
    (with pkgs; [
      hugoWebsite
      pagefind # website's Netlify build indexes the site with it

      gopls
      delve

      # kubernetes/kubernetes' hack/ scripts expect GNU userland and bash >= 4;
      # macOS ships BSD tools and bash 3.2. coreutils is in the shared bundle.
      bashInteractive
      gnused
      gnutar
      gnugrep
      gawk
      findutils
      diffutils
      rsync

      etcd_3_6 # integration tests (hack/install-etcd.sh otherwise downloads it)
      kind # e2e clusters
    ])
    # minikube's native macOS driver. On Linux the kvm2 driver is built with
    # the libvirt_dlopen tag, so it needs no libvirt headers here.
    ++ pkgs.lib.optionals isDarwin [ pkgs.vfkit ];

  extraVersions = [
    {
      name = "Hugo (website)";
      package = hugoWebsite;
    }
    {
      name = "etcd";
      package = pkgs.etcd_3_6;
    }
    {
      name = "kind";
      package = pkgs.kind;
    }
  ];

  shellHookExtra = ''
    if [ -z "''${KUBECONFIG:-}" ] && [ -f "$HOME/.kube/config" ]; then
      export KUBECONFIG="$HOME/.kube/config"
    fi

    if [ -z "''${NIX_DEVSHELL_QUIET:-}" ] && [ -f "netlify.toml" ]; then
      _want="$(grep -E '^HUGO_VERSION' netlify.toml | tail -n 1 | cut -d '"' -f 2)"
      _want="''${_want#v}"
      if [ -n "$_want" ] && [ "$_want" != "${hugoWebsite.version}" ]; then
        echo ""
        echo "netlify.toml asks for Hugo $_want; this shell provides ${hugoWebsite.version}"
        echo ""
      fi
      unset _want
    fi
  '';
}
