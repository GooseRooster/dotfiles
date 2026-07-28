#!/usr/bin/env bash
# Baseline repo setup for the ci-compose dev container — runs before setup-local.sh.
# The runtime/toolchain comes from your CI image; this only layers dev conveniences.
set -euo pipefail

# Restore /tmp to sticky world-writable (1777) if a Feature or the CI base left it
# 0755. Under keep-id (non-root user) that would make /tmp unwritable and break
# tools that create temp dirs there. Needs (passwordless) sudo — soft-failed here
# since CI images vary; if your image lacks sudo and /tmp is already 1777, ignore.
sudo chmod 1777 /tmp || echo "WARN: could not chmod /tmp (no sudo?) — skipping" >&2

# ⟨toolchain⟩ Add any repo-level restore / tool install the dev workflow needs
# (the CI image already provides the language runtime itself).
