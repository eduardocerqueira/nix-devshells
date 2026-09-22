#!/usr/bin/env bash
# Smoke test for the `ai` shell (local LLMs, Python, Hugging Face).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
source "$SCRIPT_DIR/common.sh"

echo "==> smoke-ai: shared bundle"
require_commands "${SHARED_TOOLS[@]}"

echo "==> smoke-ai: shell-specific tools"
require_commands ollama uv ffmpeg ffprobe hf python git-lfs

echo "==> smoke-ai: Hugging Face Python stack"
python - <<'PY'
import huggingface_hub

print("  ok: huggingface_hub", huggingface_hub.__version__)
PY

echo "==> smoke-ai: hf CLI"
hf --help >/dev/null
echo "  ok: hf"

echo "==> smoke-ai: torch is deliberately NOT in the Nix env (belongs in a uv venv)"
if python -c 'import torch' 2>/dev/null; then
  echo "error: torch leaked into the Nix Python env — CI will rebuild it" >&2
  exit 1
fi
echo "  ok: torch absent"

echo "==> smoke-ai: passed"
