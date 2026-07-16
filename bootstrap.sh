#!/usr/bin/env bash
# bootstrap.sh — Initial machine setup for chezmoi dotfiles.
# Idempotent: safe to re-run. Does NOT upgrade existing packages.
#
# Usage:
#   ./bootstrap.sh [--gaming|--no-gaming] [--multimedia|--no-multimedia] \
#                  [--theming|--no-theming] [--podman-alias|--no-podman-alias]
#
# Without flags: prompts interactively when run in a TTY. Defaults to false for all.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Argument parsing ──────────────────────────────────────────────────────────
GAMING=false
MULTIMEDIA=false
THEMING=false
PODMAN_ALIAS=false
GAMING_SET=false
MULTIMEDIA_SET=false
THEMING_SET=false
PODMAN_ALIAS_SET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  --gaming)
    GAMING=true
    GAMING_SET=true
    ;;
  --no-gaming)
    GAMING=false
    GAMING_SET=true
    ;;
  --multimedia)
    MULTIMEDIA=true
    MULTIMEDIA_SET=true
    ;;
  --no-multimedia)
    MULTIMEDIA=false
    MULTIMEDIA_SET=true
    ;;
  --theming)
    THEMING=true
    THEMING_SET=true
    ;;
  --no-theming)
    THEMING=false
    THEMING_SET=true
    ;;
  --podman-alias)
    PODMAN_ALIAS=true
    PODMAN_ALIAS_SET=true
    ;;
  --no-podman-alias)
    PODMAN_ALIAS=false
    PODMAN_ALIAS_SET=true
    ;;
  *)
    echo "ERROR: Unknown argument: $1" >&2
    exit 1
    ;;
  esac
  shift
done

# ── Interactive prompts (only in a TTY, only for unset flags) ─────────────────
_prompt_yn() {
  local varname="$1" question="$2" reply
  read -rp "$question [y/N] " reply
  case "$reply" in
  [Yy]*) eval "$varname=true" ;;
  *) eval "$varname=false" ;;
  esac
}

if [[ -t 0 ]]; then
  [[ "$GAMING_SET" == false ]] && _prompt_yn GAMING "Enable gaming features (Steam, emulators, Vesktop)?"
  [[ "$MULTIMEDIA_SET" == false ]] && _prompt_yn MULTIMEDIA "Enable multimedia features (Stremio, mpv)?"
  [[ "$THEMING_SET" == false ]] && _prompt_yn THEMING "Enable theming features (tinty, gnomad, gowall)?"
  [[ "$PODMAN_ALIAS_SET" == false ]] && _prompt_yn PODMAN_ALIAS "Enable podman docker alias (DOCKER_HOST + docker->podman)?"
fi

echo ""
echo "Bootstrap config:"
echo "  gaming_enabled       = $GAMING"
echo "  multimedia_enabled   = $MULTIMEDIA"
echo "  theming_enabled      = $THEMING"
echo "  podman_alias_enabled = $PODMAN_ALIAS"
echo ""

# ── Preflight: brew must be available ────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "ERROR: Homebrew (brew) is not installed or not in PATH." >&2
  echo "Install Homebrew first: https://brew.sh" >&2
  exit 1
fi

# Resolve Homebrew's prefix. Mirrors .chezmoitemplates/brew-prefix: /var/home on
# immutable/ostree hosts (Bluefin, Silverblue, Bazzite), /home on WSL and
# traditional distros, else ask brew directly. Keep the three in sync.
_brew_prefix() {
  if [[ -x /var/home/linuxbrew/.linuxbrew/bin/brew ]]; then
    echo /var/home/linuxbrew/.linuxbrew
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    echo /home/linuxbrew/.linuxbrew
  else
    brew --prefix
  fi
}

# ── Step 1: Base CLI tools + editor setup (delegated) ────────────────────────
echo "==> [1/15] Running bootstrap-cli.sh (base CLI tools + LazyVim + apply)..."
"$SCRIPT_DIR/bootstrap-cli.sh"

# ── Step 2: Base extras (visual/GUI host tools, skipped in dev containers) ───
echo "==> [2/15] Installing base extras..."
grep -E "^(tap|brew|cask)" "$SCRIPT_DIR/base-extra.Brewfile" |
  brew bundle install --file=- --no-upgrade

# ── Step 3: Rustup ───────────────────────────────────────────────────────────
echo "==> [3/15] Installing rustup..."
if brew list rustup &>/dev/null; then
  echo "  rustup: already installed, skipping."
else
  # 'brew install rustup' can exit non-zero when only the formula's post_install
  # step fails — the same failure mode seen with rustup in brew bundle. The
  # rustup manager binary is still poured and linked in that case, and the stable
  # toolchain is set up explicitly below, so a post_install-only failure is
  # non-fatal. A genuinely missing rustup binary is caught right after.
  brew install rustup ||
    echo "  WARN: 'brew install rustup' reported a failure (likely post_install); verifying rustup binary..." >&2
fi

# Ensure rustup binaries are on PATH for the rest of this script.
# brew install rustup does not modify PATH, so we add the keg bin explicitly.
export PATH="$(brew --prefix rustup)/bin:$PATH"

if ! command -v rustup &>/dev/null; then
  echo "ERROR: rustup is not available after install." >&2
  exit 1
fi

# The Homebrew rustup formula provides the rustup manager binary but does not
# run rustup-init automatically. We need to install the stable toolchain.
if rustup toolchain list 2>/dev/null | grep -q "stable"; then
  echo "  Rust stable toolchain already present, skipping."
else
  echo "  Installing Rust stable toolchain..."
  rustup toolchain install stable || {
    echo "ERROR: 'rustup toolchain install stable' failed." >&2
    exit 1
  }
fi

if ! cargo --version &>/dev/null; then
  echo "ERROR: 'cargo' is not accessible after rustup setup." >&2
  exit 1
fi
echo "  Rust:  $(rustup --version 2>&1 | head -1)"
echo "  Cargo: $(cargo --version)"

# ── Step 4: Cargo packages ───────────────────────────────────────────────────
echo "==> [4/15] Installing cargo packages..."
while IFS= read -r line; do
  if [[ "$line" =~ ^cargo[[:space:]]+\"([^\"]+)\" ]]; then
    pkg="${BASH_REMATCH[1]}"
    if cargo install --list 2>/dev/null | grep -q "^${pkg} "; then
      echo "  $pkg: already installed, skipping."
    else
      echo "  Installing: $pkg"
      cargo install "$pkg"
    fi
  fi
done <"$SCRIPT_DIR/cargo.Brewfile"

# ── Step 5: Dev tool chain (language toolchains, container tooling) ─────────
echo "==> [5/15] Installing dev tool chain..."
grep -E "^(tap|brew|cask)" "$SCRIPT_DIR/devtools.Brewfile" |
  brew bundle install --file=- --no-upgrade

# ── Step 6: Podman socket ─────────────────────────────────────────────────────
echo "==> [6/15] Ensuring podman socket is active..."
if [[ "$PODMAN_ALIAS" == true ]]; then
  if ! command -v podman &>/dev/null; then
    echo "  WARN: podman_alias_enabled=true but podman binary not found; skipping." >&2
  elif ! command -v systemctl &>/dev/null; then
    echo "  WARN: systemctl not available (container/minimal env?); skipping socket setup." >&2
  elif systemctl --user is-active --quiet podman.socket; then
    echo "  podman.socket already active, skipping."
  else
    systemctl --user enable --now podman.socket
    echo "  podman.socket enabled and started."
  fi
else
  echo "  podman_alias_enabled=false, skipping."
fi

# ── Step 7: Theming tools ────────────────────────────────────────────────────
echo "==> [7/15] Theming tools..."
if [[ "$THEMING" == true ]]; then
  brew bundle install --file="$SCRIPT_DIR/theming.Brewfile" --no-upgrade
else
  echo "  theming_enabled=false, skipping."
fi

# ── Step 8: Base flatpaks ────────────────────────────────────────────────────
_install_flatpaks() {
  local brewfile="$1"
  [[ -f "$brewfile" ]] || {
    echo "  WARN: $brewfile not found, skipping." >&2
    return
  }
  while IFS= read -r line; do
    if [[ "$line" =~ ^flatpak[[:space:]]+\"([^\"]+)\" ]]; then
      local app_id="${BASH_REMATCH[1]}"
      if flatpak info "$app_id" &>/dev/null; then
        echo "  $app_id: already installed."
      else
        echo "  Installing: $app_id"
        flatpak install --noninteractive -y flathub "$app_id" ||
          echo "  WARN: Failed to install flatpak $app_id" >&2
      fi
    fi
  done <"$brewfile"
}

echo "==> [8/15] Installing base flatpaks..."
_install_flatpaks "$SCRIPT_DIR/base.flatpak.Brewfile"

# ── Step 9: Gaming flatpaks ──────────────────────────────────────────────────
echo "==> [9/15] Gaming flatpaks..."
if [[ "$GAMING" == true ]]; then
  _install_flatpaks "$SCRIPT_DIR/gaming.flatpak.Brewfile"
else
  echo "  gaming_enabled=false, skipping."
fi

# ── Step 10: Multimedia flatpaks ──────────────────────────────────────────────
echo "==> [10/15] Multimedia flatpaks..."
if [[ "$MULTIMEDIA" == true ]]; then
  _install_flatpaks "$SCRIPT_DIR/multimedia.flatpak.Brewfile"
else
  echo "  multimedia_enabled=false, skipping."
fi

# ── Step 11: Gaming CLI tools ─────────────────────────────────────────────────
echo "==> [11/15] Gaming CLI tools..."
if [[ "$GAMING" == true ]]; then
  if grep -qE "^(tap|brew|cask)" "$SCRIPT_DIR/gaming.Brewfile" 2>/dev/null; then
    grep -E "^(tap|brew|cask)" "$SCRIPT_DIR/gaming.Brewfile" |
      brew bundle install --file=- --no-upgrade
  else
    echo "  gaming.Brewfile has no formulae yet, skipping."
  fi
else
  echo "  gaming_enabled=false, skipping."
fi

# ── Step 12: Ghostty terminal ────────────────────────────────────────────────
echo "==> [12/15] Ghostty terminal..."
if command -v ghostty &>/dev/null; then
  echo "  ghostty already installed natively, skipping AppImage."
else
  grep -E "^(tap|brew|cask)" "$SCRIPT_DIR/ghostty.Brewfile" |
    brew bundle install --file=- --no-upgrade
fi

# ── Step 13: Bootstrap chezmoi.toml ──────────────────────────────────────────
echo "==> [13/15] Bootstrapping ~/.config/chezmoi/chezmoi.toml..."
CHEZMOI_DIR="$HOME/.config/chezmoi"
CHEZMOI_CONFIG="$CHEZMOI_DIR/chezmoi.toml"
CHEZMOI_BASE_SRC="$SCRIPT_DIR/dot_config/chezmoi.base.toml"

mkdir -p "$CHEZMOI_DIR"

if [[ -f "$CHEZMOI_CONFIG" ]] &&
  grep -q "gaming_enabled" "$CHEZMOI_CONFIG" &&
  grep -q "multimedia_enabled" "$CHEZMOI_CONFIG" &&
  grep -q "theming_enabled" "$CHEZMOI_CONFIG" &&
  grep -q "devcontainer_enabled" "$CHEZMOI_CONFIG" &&
  grep -q "wsl_enabled" "$CHEZMOI_CONFIG" &&
  grep -q "podman_alias_enabled" "$CHEZMOI_CONFIG"; then
  echo "  chezmoi.toml already has all [data] keys. Skipping."
  echo "  To update feature flags, edit $CHEZMOI_CONFIG and run 'chezmoi apply'."
else
  if [[ -f "$CHEZMOI_CONFIG" ]]; then
    BACKUP="${CHEZMOI_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$CHEZMOI_CONFIG" "$BACKUP"
    echo "  Backed up existing config to $BACKUP"
  fi

  cp "$CHEZMOI_BASE_SRC" "$CHEZMOI_CONFIG"
  sed -i "s|@NU_BIN@|$(_brew_prefix)/bin/nu|" "$CHEZMOI_CONFIG"
  printf '\n[data]\ngaming_enabled = %s\nmultimedia_enabled = %s\ntheming_enabled = %s\npodman_alias_enabled = %s\ndevcontainer_enabled = false\nwsl_enabled = false\n' \
    "$GAMING" "$MULTIMEDIA" "$THEMING" "$PODMAN_ALIAS" >>"$CHEZMOI_CONFIG"

  echo "  Created $CHEZMOI_CONFIG"
fi

# ── Step 14: Tinty hook target directories ────────────────────────────────────
echo "==> [14/15] Creating tinty directories..."
if [[ "$THEMING" == true ]]; then
  mkdir -p "$HOME/.config/yazi/flavors/tinted-scheme.yazi/"
  mkdir -p "$HOME/.claude/themes/"
  mkdir -p "$HOME/.config/ghostty/themes/"
  if [[ "$GAMING" == true ]]; then
    mkdir -p "$HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings/"
  fi
  echo "  Done."
else
  echo "  theming_enabled=false, skipping."
fi

# ── Step 15: Apply dotfiles ───────────────────────────────────────────────────
echo "==> [15/15] Running 'chezmoi apply'..."
chezmoi apply

echo ""
echo "Bootstrap complete."
if [[ "$GAMING" == false ]] || [[ "$MULTIMEDIA" == false ]] || [[ "$THEMING" == false ]]; then
  echo ""
  echo "Some features were not enabled. To enable them later:"
  echo "  1. Edit ~/.config/chezmoi/chezmoi.toml and set the relevant flags to true"
  echo "  2. Re-run this script with --gaming / --multimedia / --theming"
  echo "     (package installs are skipped if already present)"
fi
