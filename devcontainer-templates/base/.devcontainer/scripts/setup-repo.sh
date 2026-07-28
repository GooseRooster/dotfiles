#!/usr/bin/env bash
# Baseline repo setup — runs in every dev container (before the optional
# per-developer setup-local.sh). Put language-agnostic, always-needed steps here.
set -euo pipefail

# Restore /tmp to sticky world-writable (1777). Some devcontainer Feature build
# steps leave /tmp as 0755 root-owned; under rootless-podman keep-id (non-root
# user) that makes /tmp unwritable and breaks any tool that creates temp dirs
# there. Features run after the Dockerfile, so fix it here. The user has
# passwordless sudo (common-utils).
sudo chmod 1777 /tmp

# ⟨toolchain⟩ Add your language's dependency restore / tool install here
# (e.g. `dotnet restore`, `npm ci`, `uv sync`). See the dotnet template for a
# worked example (restore, dev-cert export, etc.).
