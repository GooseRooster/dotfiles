#!/usr/bin/env bash
# bootstrap-cli.sh — Minimal CLI + editor setup for dev environments (e.g. a
# dev container). Installs base CLI tools, sets up Neovim on top of LazyVim,
# and applies dotfiles. No gaming/multimedia/theming, no language toolchains —
# a dev container is expected to supply its own toolchain (see devtools.Brewfile).
#
# Idempotent: safe to re-run. Does NOT upgrade existing packages.
#
# Usage:
#   ./bootstrap-cli.sh [--devcontainer | --wsl]
#
# --devcontainer marks this run as a dev container in chezmoi.toml, so
# 'chezmoi apply' skips desktop/GUI/optional-feature dotfiles that have no
# purpose in a container (ghostty, mpv, tinty, etc — see .chezmoiignore.tmpl).
# It does NOT install Homebrew — a dev container is expected to supply that
# itself (e.g. via a devcontainer Feature), same as it supplies its own
# language toolchains. See devcontainer-templates/ for examples.
#
# --wsl targets an Ubuntu WSL host that drives dev containers. Like the base
# run it skips language toolchains, but additionally installs wsl.Brewfile
# (dev container CLI, Claude Code, fastfetch), records wsl_enabled in
# chezmoi.toml (skips GUI dotfiles but keeps devcontainer-init) and forces
# podman_alias_enabled on (DOCKER_HOST + docker->podman, see podman-alias.nu),
# sets up a bash login shell that greets with fastfetch and drops into nushell,
# and installs Docker + Podman via setup-docker-wsl.sh. --wsl and --devcontainer
# are mutually exclusive.
#
# This is also called by bootstrap.sh (without flags) as its first
# step for full host setups.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEVCONTAINER=false
WSL=false
while [[ $# -gt 0 ]]; do
  case "$1" in
  --devcontainer)
    DEVCONTAINER=true
    ;;
  --wsl)
    WSL=true
    ;;
  *)
    echo "ERROR: Unknown argument: $1" >&2
    exit 1
    ;;
  esac
  shift
done

if [[ "$DEVCONTAINER" == true && "$WSL" == true ]]; then
  echo "ERROR: --devcontainer and --wsl are mutually exclusive." >&2
  exit 1
fi

# ── Preflight: brew must be available ────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "ERROR: Homebrew (brew) is not installed or not in PATH." >&2
  echo "Install Homebrew first: https://brew.sh" >&2
  exit 1
fi

# ── Step 1: Base CLI tools ────────────────────────────────────────────────────
echo "==> [1/5] Installing base CLI tools..."
grep -E "^(tap|brew|cask)" "$SCRIPT_DIR/base.Brewfile" |
  brew bundle install --file=- --no-upgrade

# ── WSL extras (dev container CLI, Claude Code, fastfetch) ────────────────────
if [[ "$WSL" == true ]]; then
  echo "==> [WSL] Installing WSL extras from wsl.Brewfile..."
  grep -E "^(tap|brew|cask)" "$SCRIPT_DIR/wsl.Brewfile" |
    brew bundle install --file=- --no-upgrade
fi

# ── Step 2: LazyVim starter ──────────────────────────────────────────────────
# Follows the official LazyVim installation steps: https://www.lazyvim.org/installation
echo "==> [2/5] Setting up LazyVim starter..."
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [[ -e "$NVIM_CONFIG_DIR" ]]; then
  echo "  $NVIM_CONFIG_DIR already exists, skipping LazyVim starter clone."
else
  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"
  rm -rf "$NVIM_CONFIG_DIR/.git"
  echo "  Cloned LazyVim starter into $NVIM_CONFIG_DIR."
fi

# ── Step 3: Record the environment flag in chezmoi.toml, if requested ────────
# Sets "<key> = true" in the [data] table of ~/.config/chezmoi/chezmoi.toml,
# creating the config from the base template if it doesn't exist yet.
_set_chezmoi_flag() {
  local key="$1"
  local CHEZMOI_DIR="$HOME/.config/chezmoi"
  local CHEZMOI_CONFIG="$CHEZMOI_DIR/chezmoi.toml"
  local CHEZMOI_BASE_SRC="$SCRIPT_DIR/dot_config/chezmoi.base.toml"
  local BACKUP

  mkdir -p "$CHEZMOI_DIR"

  if [[ -f "$CHEZMOI_CONFIG" ]] && grep -q "$key" "$CHEZMOI_CONFIG"; then
    echo "  chezmoi.toml already has $key. Skipping."
  elif [[ -f "$CHEZMOI_CONFIG" ]] && grep -q '^\[data\]' "$CHEZMOI_CONFIG"; then
    # An existing [data] table is present (e.g. from a prior bootstrap.sh run)
    # but lacks this key. TOML doesn't allow redefining a table, so insert
    # the key into the existing table instead of appending a second [data].
    BACKUP="${CHEZMOI_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$CHEZMOI_CONFIG" "$BACKUP"
    echo "  Backed up existing config to $BACKUP"
    sed -i "/^\[data\]/a $key = true" "$CHEZMOI_CONFIG"
    echo "  Set $key = true in $CHEZMOI_CONFIG"
  else
    if [[ -f "$CHEZMOI_CONFIG" ]]; then
      BACKUP="${CHEZMOI_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
      cp "$CHEZMOI_CONFIG" "$BACKUP"
      echo "  Backed up existing config to $BACKUP"
    else
      cp "$CHEZMOI_BASE_SRC" "$CHEZMOI_CONFIG"
    fi
    printf '\n[data]\n%s = true\n' "$key" >>"$CHEZMOI_CONFIG"
    echo "  Set $key = true in $CHEZMOI_CONFIG"
  fi
}

echo "==> [3/5] Recording environment flag in chezmoi.toml..."
if [[ "$DEVCONTAINER" == true ]]; then
  _set_chezmoi_flag devcontainer_enabled
elif [[ "$WSL" == true ]]; then
  _set_chezmoi_flag wsl_enabled
  # WSL always uses podman as the docker engine — enforce the alias flag on.
  _set_chezmoi_flag podman_alias_enabled
else
  echo "  No environment flag requested, skipping."
fi

# ── Step 4: Apply dotfiles ────────────────────────────────────────────────────
echo "==> [4/5] Running 'chezmoi apply'..."
chezmoi apply

# ── Step 5: Yazi plugins + tool data refresh ──────────────────────────────────
# package.toml lists yazi's plugin/flavor deps; `ya pkg install` clones them.
# Must run after 'chezmoi apply' so ~/.config/yazi/package.toml exists.
echo "==> [5/5] Installing yazi plugins and refreshing tool data..."
ya pkg install

# tealdeer: download/refresh the tldr page cache.
if command -v tldr &>/dev/null; then
  tldr --update || echo "  WARN: 'tldr --update' failed (network?), skipping." >&2
fi

# television: fetch the latest community channel prototypes.
if command -v tv &>/dev/null; then
  tv update-channels || echo "  WARN: 'tv update-channels' failed, skipping." >&2
fi

# ── WSL login shell + Docker Engine ──────────────────────────────────────────
if [[ "$WSL" == true ]]; then
  # Configure bash to load Homebrew's environment, greet with fastfetch, and
  # drop into nushell on interactive login. config.nu suppresses its own
  # fastfetch greeting under WSL, so we run it here instead. Idempotent via the
  # marker comment; the interactive guard keeps non-interactive bash usable.
  echo "==> [WSL] Configuring bash login shell (~/.bashrc)..."
  BASHRC="$HOME/.bashrc"
  if [[ -f "$BASHRC" ]] && grep -q "# chezmoi-wsl:" "$BASHRC"; then
    echo "  ~/.bashrc already configured, skipping."
  else
    cat >>"$BASHRC" <<'EOF'

# chezmoi-wsl: brew env + greeting + nushell
if [[ $- == *i* ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fastfetch
  nu
fi
EOF
    echo "  Appended brew env + fastfetch + nushell block to ~/.bashrc."
  fi

  echo "==> [WSL] Setting up Docker Engine..."
  "$SCRIPT_DIR/setup-docker-wsl.sh"
fi

echo ""
echo "bootstrap-cli complete."
