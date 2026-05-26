#!/usr/bin/env bash
# Smoke test for flakes/devops (multi-cloud, k8s, infra).
set -euo pipefail

echo "==> smoke-devops: Kubernetes"
for cmd in kubectl helm k9s kubectx stern kubecolor helmfile; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-devops: Cloud CLIs"
for cmd in cloudflared wrangler aws az gcloud; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-devops: Infrastructure & secrets"
for cmd in tofu sops age terraform tflint tfsec; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-devops: SRE utilities"
for cmd in dive lazydocker grpcurl http yq direnv actionlint; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-devops: terraform wrapper points to tofu"
terraform version 2>&1 | grep -i tofu

echo "==> smoke-devops: passed"
