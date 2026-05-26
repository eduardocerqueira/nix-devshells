{
  description = "AI / ML — local LLMs, Python tooling, and Hugging Face workflows";

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
          pythonAi = pkgs.python312.withPackages (ps: with ps; [
            huggingface-hub
            tokenizers
            safetensors
          ]);
        in {
          default = base.lib.mkDevShell {
            inherit system pkgs;

            python = pythonAi;

            title = "NIX DEVSHELLS — AI";
            issueUrl = "https://github.com/eduardocerqueira/nix-devshells/issues";
            envVars = [ "HF_HOME" "HF_TOKEN" "OLLAMA_HOST" "OLLAMA_MODELS" ];

            extraPackages = with pkgs; [
              ollama
              ffmpeg
              git-lfs
            ];

            shellHookExtra = ''
              export HF_HOME="''${HF_HOME:-$HOME/.cache/huggingface}"
              export OLLAMA_HOST="''${OLLAMA_HOST:-http://127.0.0.1:11434}"
              export OLLAMA_MODELS="''${OLLAMA_MODELS:-$HOME/.ollama/models}"

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
                echo "Tip: export HF_TOKEN for gated models — huggingface-cli login"
                echo "  Heavy ML libs (torch, transformers, …): uv add transformers datasets accelerate"
                echo ""
              fi
            '';
          };
        });
    };
}
