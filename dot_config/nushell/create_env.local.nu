# Per-host / per-container secrets and env (API keys, model choices, etc.).
#
# Managed by chezmoi ONLY on first apply (`create_` prefix): the file is
# materialized here from the source scaffold, then chezmoi never touches it
# again. Edit freely — your changes are safe. To reset to the scaffold,
# delete this file and re-run `chezmoi apply`.
#
# This file is sourced unconditionally at the end of env.nu. Both
# MINUET_API_KEY and MINUET_MODEL must be non-empty for minuet.nvim to
# activate. The endpoint is fixed to http://localhost:5000 (opencode-oai);
# for a local-only bridge any non-empty api key works.
#
# You can also drop any other per-host secrets or overrides here.

$env.MINUET_API_KEY = ""   # e.g. "local" for a keyless bridge, or a real token
$env.MINUET_MODEL   = ""   # e.g. "github-copilot/gpt-4o-mini"
