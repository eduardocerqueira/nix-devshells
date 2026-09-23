#!/usr/bin/env bash
# Smoke test for the `devops` shell (multi-cloud, k8s, infra).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
source "$SCRIPT_DIR/common.sh"

echo "==> smoke-devops: shared bundle"
require_commands "${SHARED_TOOLS[@]}"

echo "==> smoke-devops: Kubernetes"
require_commands kubectl helm k9s kubectx stern kubecolor helmfile flux argocd \
  kustomize kubeconform kind

echo "==> smoke-devops: Cloud CLIs"
require_commands cloudflared wrangler aws

echo "==> smoke-devops: Infrastructure & secrets"
require_commands tofu terraform sops age tflint trivy step terraform-docs cosign

echo "==> smoke-devops: retired / superseded scanners are not shipped"
# tfsec is end-of-life upstream ("Tfsec is now part of Trivy"); checkov was
# dropped because `trivy config` covers the same IaC misconfiguration scanning
# and checkov dragged in igraph -> arpack -> gfortran (~400 MiB).
for dead in tfsec checkov; do
  if command -v "$dead" >/dev/null 2>&1; then
    echo "error: $dead should not be shipped — use trivy" >&2
    exit 1
  fi
  echo "  ok: $dead absent"
done

echo "==> smoke-devops: the heavy tools that live only here"
require_commands shellcheck difft

echo "==> smoke-devops: SRE utilities"
require_commands dive lazydocker grpcurl http yq actionlint pre-commit

echo "==> smoke-devops: kubectl shortcuts are store-path wrappers"
assert_from_shell k kgp kgpa kns terraform

echo "==> smoke-devops: terraform wrapper points to tofu"
terraform version 2>&1 | grep -i tofu

echo "==> smoke-devops: passed"
