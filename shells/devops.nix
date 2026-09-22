# DevOps / SRE — multi-cloud, Kubernetes, and infrastructure tooling.
{ pkgs, mkDevShell }:

let
  kubectlBin = "${pkgs.kubectl}/bin/kubectl";
  kubecolorBin = "${pkgs.kubecolor}/bin/kubecolor";

  # Real store-path wrappers instead of scripts written into a mktemp dir on
  # every shell entry (which leaked a /tmp directory per entry and never
  # cleaned up). These are ordinary packages: they work under any shell, are
  # visible to `nix flake check`, and disappear with the shell.
  shortcut =
    name: body:
    pkgs.writeShellScriptBin name ''
      export KUBECTL_COMMAND="${kubectlBin}"
      ${body}
    '';

  shortcuts = [
    (shortcut "k" ''exec ${kubecolorBin} "$@"'')
    (shortcut "kgp" ''exec ${kubecolorBin} get pods "$@"'')
    (shortcut "kgpa" ''exec ${kubecolorBin} get pods -A "$@"'')
    (shortcut "kns" ''exec ${kubectlBin} config set-context --current --namespace "$@"'')
    (pkgs.writeShellScriptBin "terraform" ''exec ${pkgs.opentofu}/bin/tofu "$@"'')
  ];
in
mkDevShell {
  inherit pkgs;

  helm = true;
  kubectl = true;

  title = "NIX DEVSHELLS — DEVOPS";
  issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
  envVars = [
    "KUBECONFIG"
    "AWS_PROFILE"
    "CLOUDSDK_CORE_PROJECT"
    "AZURE_CONFIG_DIR"
  ];

  extraPackages =
    shortcuts
    ++ (with pkgs; [
      # Kubernetes
      k9s
      kubectx
      stern
      kubecolor
      helmfile
      fluxcd
      argocd

      # Cloud CLIs
      cloudflared
      wrangler
      awscli2
      azure-cli
      google-cloud-sdk

      # Infrastructure as Code & secrets
      opentofu
      sops
      age
      tflint
      # tfsec is end-of-life upstream ("Tfsec is now part of Trivy") — Trivy is
      # its maintained successor and also covers images, SBOMs and secrets.
      trivy
      checkov
      step-cli

      # SRE / platform utilities
      dive
      lazydocker
      grpcurl
      httpie
      yq-go
      direnv
      actionlint
      pre-commit
    ]);

  extraVersions = [
    {
      name = "OpenTofu";
      package = pkgs.opentofu;
    }
    {
      name = "Trivy";
      package = pkgs.trivy;
    }
    {
      name = "k9s";
      package = pkgs.k9s;
    }
    {
      name = "Argo CD";
      package = pkgs.argocd;
    }
    {
      name = "Flux";
      package = pkgs.fluxcd;
    }
    {
      name = "AWS CLI";
      package = pkgs.awscli2;
    }
  ];

  shellHookExtra = ''
    # krew plugins (optional, user-installed)
    if [ -d "$HOME/.krew/bin" ]; then
      export PATH="$HOME/.krew/bin:$PATH"
    fi

    if [ -z "''${KUBECONFIG:-}" ] && [ -f "$HOME/.kube/config" ]; then
      export KUBECONFIG="$HOME/.kube/config"
    fi

    if [ -z "''${NIX_DEVSHELL_QUIET:-}" ]; then
      if [ -f "wrangler.toml" ] || [ -f "wrangler.jsonc" ]; then
        echo ""
        echo "Cloudflare Workers project detected — try: wrangler dev"
        echo ""
      fi

      if compgen -G "*.tf" > /dev/null; then
        echo ""
        echo "Terraform/OpenTofu files detected — terraform runs OpenTofu (tofu) in this shell"
        echo ""
      fi
    fi
  '';
}
