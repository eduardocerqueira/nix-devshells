# AI / ML — local LLMs, Python tooling, and Hugging Face workflows.
{ pkgs, mkDevShell }:

let
  # Keep the Python env light for CI/cache: nixpkgs builds of safetensors/
  # tokenizers pull torch as a nativeBuildInput. Heavy ML belongs in project
  # venvs via `uv`. huggingface-hub ships the `hf` CLI.
  pythonAi = pkgs.python312.withPackages (ps: with ps; [ huggingface-hub ]);
in
mkDevShell {
  inherit pkgs;

  python = pythonAi;

  claudeCode = true;

  title = "NIX DEVSHELLS — AI";
  issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
  envVars = [
    "HF_HOME"
    "HF_TOKEN"
    "OLLAMA_HOST"
    "OLLAMA_MODELS"
  ];

  extraPackages = with pkgs; [
    ollama
    ffmpeg
    git-lfs
  ];

  extraVersions = [
    {
      name = "Ollama";
      package = pkgs.ollama;
    }
    {
      name = "ffmpeg";
      package = pkgs.ffmpeg;
    }
    {
      name = "git-lfs";
      package = pkgs.git-lfs;
    }
  ];

  shellHookExtra = ''
    export HF_HOME="''${HF_HOME:-$HOME/.cache/huggingface}"
    export OLLAMA_HOST="''${OLLAMA_HOST:-http://127.0.0.1:11434}"
    export OLLAMA_MODELS="''${OLLAMA_MODELS:-$HOME/.ollama/models}"

    if [ -z "''${NIX_DEVSHELL_QUIET:-}" ]; then
      if [ -f "pyproject.toml" ] || [ -f "uv.lock" ]; then
        echo ""
        echo "Python project detected — try: uv sync"
        echo ""
      fi

      if [ -f "Modelfile" ] || [ -d "$HOME/.ollama/models" ]; then
        echo ""
        echo "Ollama available — try: ollama list  |  ollama run <model>"
        echo "  API: $OLLAMA_HOST"
        echo ""
      fi

      if [ -n "''${HF_TOKEN:-}" ]; then
        echo "Hugging Face token detected (HF_TOKEN)"
      else
        echo ""
        echo "Tip: export HF_TOKEN for gated models — hf auth login"
        echo "  Heavy ML libs (torch, transformers, …): uv add transformers datasets accelerate"
        echo ""
      fi
    fi
  '';
}
