#!/usr/bin/env bash
# Smoke test for the `devops` shell (multi-cloud, k8s, infra).
set -euo pipefail

echo "==> smoke-devops: Kubernetes"
for cmd in kubectl helm k9s kubectx stern kubecolor helmfile flux argocd; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-devops: Cloud CLIs"
for cmd in cloudflared wrangler aws az gcloud; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-devops: Infrastructure & secrets"
for cmd in tofu sops age terraform tflint trivy checkov step; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-devops: tfsec is retired in favour of trivy"
if command -v tfsec >/dev/null 2>&1; then
  echo "error: tfsec is end-of-life upstream and should not be shipped" >&2
  exit 1
fi
echo "  ok: tfsec absent"

echo "==> smoke-devops: SRE utilities"
for cmd in dive lazydocker grpcurl http yq direnv actionlint pre-commit git claude; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-devops: kubectl shortcuts are store-path wrappers"
for cmd in k kgp kgpa kns; do
  resolved="$(command -v "$cmd")"
  [[ "$resolved" == /nix/store/* ]] || {
    echo "error: $cmd is not a store wrapper: $resolved" >&2
    exit 1
  }
  echo "  ok: $cmd -> $resolved"
done

echo "==> smoke-devops: terraform wrapper points to tofu"
terraform version 2>&1 | grep -i tofu

echo "==> smoke-devops: passed"
