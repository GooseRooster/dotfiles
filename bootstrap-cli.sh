#!/usr/bin/env bash
# bootstrap-cli.sh — Minimal CLI + editor setup for dev environments (e.g. a
# dev container). Installs base CLI tools, sets up Neovim on top of LazyVim,
# and applies dotfiles. No gaming/multimedia/theming, no language toolchains —
# a dev container is expected to supply its own toolchain (see devtools.Brewfile).
#
# Idempotent: safe to re-run. Does NOT upgrade existing packages.
#
# Usage:
#   ./bootstrap-cli.sh
#
# This is also called by bootstrap.sh as its first step for full host setups.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Preflight: brew must be available ────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "ERROR: Homebrew (brew) is not installed or not in PATH." >&2
  echo "Install Homebrew first: https://brew.sh" >&2
  exit 1
fi

# ── Step 1: Base CLI tools ────────────────────────────────────────────────────
echo "==> [1/3] Installing base CLI tools..."
grep -E "^(tap|brew|cask)" "$SCRIPT_DIR/base.Brewfile" |
  brew bundle install --file=- --no-upgrade

# ── Step 2: LazyVim starter ──────────────────────────────────────────────────
# Follows the official LazyVim installation steps: https://www.lazyvim.org/installation
echo "==> [2/3] Setting up LazyVim starter..."
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [[ -e "$NVIM_CONFIG_DIR" ]]; then
  echo "  $NVIM_CONFIG_DIR already exists, skipping LazyVim starter clone."
else
  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"
  rm -rf "$NVIM_CONFIG_DIR/.git"
  echo "  Cloned LazyVim starter into $NVIM_CONFIG_DIR."
fi

# ── Step 3: Apply dotfiles ────────────────────────────────────────────────────
echo "==> [3/3] Running 'chezmoi apply'..."
chezmoi apply

echo ""
echo "bootstrap-cli complete."
