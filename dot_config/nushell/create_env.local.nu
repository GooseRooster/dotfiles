# Per-host / per-container secrets and env (API keys, model choices, etc.).
#
# Managed by chezmoi ONLY on first apply (`create_` prefix): the file is
# materialized here from the source scaffold, then chezmoi never touches it
# again. Edit freely — your changes are safe. To reset to the scaffold,
# delete this file and re-run `chezmoi apply`.
#
# This file is sourced unconditionally at the end of env.nu. Set
# RAMALAMA_FIM_URL to the base URL of a running ramalama (llama.cpp-backed)
# OpenAI-FIM-compatible server to activate minuet.nvim inside Neovim. When
# empty, the plugin is not loaded. RAMALAMA_FIM_MODEL overrides the served
# model name.
#
# You can also drop any other per-host secrets or overrides here.

$env.RAMALAMA_FIM_URL   = ""                  # e.g. "http://localhost:8000"
$env.RAMALAMA_FIM_MODEL = "qwen2.5-coder:7b"  # served model identifier
