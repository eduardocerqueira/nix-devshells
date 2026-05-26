{
  description = "DevOps / SRE — multi-cloud, Kubernetes, and infrastructure tooling";

  inputs = {
    base.url = "path:../../lib";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
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

            helm = true;
            kubectl = true;

            title = "NIX DEVSHELLS — DEVOPS";
            issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
            envVars = [ "KUBECONFIG" "AWS_PROFILE" "CLOUDSDK_CORE_PROJECT" "AZURE_CONFIG_DIR" ];

            extraPackages = with pkgs; [
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
              tfsec
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
            ];

            shellHookExtra = ''
              # krew plugins (optional, user-installed)
              if [ -d "$HOME/.krew/bin" ]; then
                export PATH="$HOME/.krew/bin:$PATH"
              fi

              # Shell-agnostic kubectl/helm shortcuts (work in zsh via -c zsh)
              _devops_bin=$(mktemp -d /tmp/nix-devops-bin.XXXXXX)
              _kubectl_bin=$(command -v kubecolor 2>/dev/null || command -v kubectl)

              cat > "$_devops_bin/k" <<EOF
              #!/bin/sh
              exec $_kubectl_bin "\$@"
              EOF
              cat > "$_devops_bin/kns" <<'EOF'
              #!/bin/sh
              exec kubectl config set-context --current --namespace "$@"
              EOF
              cat > "$_devops_bin/kgp" <<'EOF'
              #!/bin/sh
              exec kubectl get pods "$@"
              EOF
              cat > "$_devops_bin/kgpa" <<'EOF'
              #!/bin/sh
              exec kubectl get pods -A "$@"
              EOF
              cat > "$_devops_bin/terraform" <<'EOF'
              #!/bin/sh
              exec tofu "$@"
              EOF

              chmod +x "$_devops_bin"/*
              export PATH="$_devops_bin:$PATH"

              if [ -z "''${KUBECONFIG:-}" ] && [ -f "$HOME/.kube/config" ]; then
                export KUBECONFIG="$HOME/.kube/config"
              fi

              if [ -f "wrangler.toml" ] || [ -f "wrangler.jsonc" ]; then
                echo ""
                echo "Cloudflare Workers project detected — try: wrangler dev"
                echo ""
              fi

              if [ -f "main.tf" ] || [ -f "versions.tf" ] || compgen -G "*.tf" > /dev/null; then
                echo ""
                echo "Terraform/OpenTofu files detected — terraform runs OpenTofu (tofu) in this shell"
                echo ""
              fi
            '';
          };
        });
    };
}
