#!/usr/bin/env bash
# Smoke test for flakes/ai (local LLMs, Python, Hugging Face).
set -euo pipefail

echo "==> smoke-ai: core tools"
for cmd in ollama uv ffmpeg hf python; do
  command -v "$cmd" >/dev/null
  echo "  ok: $cmd"
done

echo "==> smoke-ai: Hugging Face Python stack"
python - <<'PY'
import huggingface_hub
import safetensors
import tokenizers

print("  ok: huggingface_hub", huggingface_hub.__version__)
print("  ok: tokenizers", tokenizers.__version__)
PY

echo "==> smoke-ai: media & model storage"
command -v ffprobe >/dev/null && echo "  ok: ffprobe"
command -v git-lfs >/dev/null && echo "  ok: git-lfs"

echo "==> smoke-ai: passed"
