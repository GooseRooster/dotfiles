#!/usr/bin/env bash
# bootstrap-cli.sh — Minimal CLI + editor setup for dev environments (e.g. a
# dev container). Installs base CLI tools, sets up Neovim on top of LazyVim,
# and applies dotfiles. No gaming/multimedia/theming, no language toolchains —
# a dev container is expected to supply its own toolchain (see devtools.Brewfile).
#
# Idempotent: safe to re-run. Does NOT upgrade existing packages.
#
# Usage:
#   ./bootstrap-cli.sh [--devcontainer]
#
# --devcontainer marks this run as a dev container in chezmoi.toml, so
# 'chezmoi apply' skips desktop/GUI/optional-feature dotfiles that have no
# purpose in a container (ghostty, mpv, tinty, etc — see .chezmoiignore.tmpl).
# It does NOT install Homebrew — a dev container is expected to supply that
# itself (e.g. via a devcontainer Feature), same as it supplies its own
# language toolchains. See devcontainer-templates/ for examples.
#
# This is also called by bootstrap.sh (without --devcontainer) as its first
# step for full host setups.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEVCONTAINER=false
while [[ $# -gt 0 ]]; do
  case "$1" in
  --devcontainer)
    DEVCONTAINER=true
    ;;
  *)
    echo "ERROR: Unknown argument: $1" >&2
    exit 1
    ;;
  esac
  shift
done

# ── Preflight: brew must be available ────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "ERROR: Homebrew (brew) is not installed or not in PATH." >&2
  echo "Install Homebrew first: https://brew.sh" >&2
  exit 1
fi

# ── Step 1: Base CLI tools ────────────────────────────────────────────────────
echo "==> [1/4] Installing base CLI tools..."
grep -E "^(tap|brew|cask)" "$SCRIPT_DIR/base.Brewfile" |
  brew bundle install --file=- --no-upgrade

# ── Step 2: LazyVim starter ──────────────────────────────────────────────────
# Follows the official LazyVim installation steps: https://www.lazyvim.org/installation
echo "==> [2/4] Setting up LazyVim starter..."
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [[ -e "$NVIM_CONFIG_DIR" ]]; then
  echo "  $NVIM_CONFIG_DIR already exists, skipping LazyVim starter clone."
else
  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"
  rm -rf "$NVIM_CONFIG_DIR/.git"
  echo "  Cloned LazyVim starter into $NVIM_CONFIG_DIR."
fi

# ── Step 3: Mark this as a dev container, if requested ───────────────────────
echo "==> [3/4] Recording devcontainer_enabled in chezmoi.toml..."
if [[ "$DEVCONTAINER" == true ]]; then
  CHEZMOI_DIR="$HOME/.config/chezmoi"
  CHEZMOI_CONFIG="$CHEZMOI_DIR/chezmoi.toml"
  CHEZMOI_BASE_SRC="$SCRIPT_DIR/dot_config/chezmoi.base.toml"

  mkdir -p "$CHEZMOI_DIR"

  if [[ -f "$CHEZMOI_CONFIG" ]] && grep -q "devcontainer_enabled" "$CHEZMOI_CONFIG"; then
    echo "  chezmoi.toml already has devcontainer_enabled. Skipping."
  elif [[ -f "$CHEZMOI_CONFIG" ]] && grep -q '^\[data\]' "$CHEZMOI_CONFIG"; then
    # An existing [data] table is present (e.g. from a prior bootstrap.sh run)
    # but lacks this key. TOML doesn't allow redefining a table, so insert
    # the key into the existing table instead of appending a second [data].
    BACKUP="${CHEZMOI_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$CHEZMOI_CONFIG" "$BACKUP"
    echo "  Backed up existing config to $BACKUP"
    sed -i '/^\[data\]/a devcontainer_enabled = true' "$CHEZMOI_CONFIG"
    echo "  Set devcontainer_enabled = true in $CHEZMOI_CONFIG"
  else
    if [[ -f "$CHEZMOI_CONFIG" ]]; then
      BACKUP="${CHEZMOI_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
      cp "$CHEZMOI_CONFIG" "$BACKUP"
      echo "  Backed up existing config to $BACKUP"
    else
      cp "$CHEZMOI_BASE_SRC" "$CHEZMOI_CONFIG"
    fi
    printf '\n[data]\ndevcontainer_enabled = true\n' >>"$CHEZMOI_CONFIG"
    echo "  Set devcontainer_enabled = true in $CHEZMOI_CONFIG"
  fi
else
  echo "  --devcontainer not passed, skipping."
fi

# ── Step 4: Apply dotfiles ────────────────────────────────────────────────────
echo "==> [4/4] Running 'chezmoi apply'..."
chezmoi apply

echo ""
echo "bootstrap-cli complete."
