#!/usr/bin/env bash
# setup-docker-wsl.sh — Install Docker Engine on Ubuntu under WSL2 (no Docker
# Desktop), so dev containers can run natively. Adds Docker's official apt repo,
# installs the engine + compose/buildx plugins, adds you to the docker group, and
# enables systemd in /etc/wsl.conf.
#
# Idempotent: safe to re-run. Auto-invoked by 'bootstrap-cli.sh --wsl', but can
# also be run standalone.
#
# Usage:
#   ./setup-docker-wsl.sh
#
# After it finishes you must restart WSL for systemd + docker group membership to
# take effect: run 'wsl --shutdown' from Windows PowerShell, then reopen Ubuntu.

set -euo pipefail

# ── Preflight ────────────────────────────────────────────────────────────────
if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
  echo "  WARN: WSL_DISTRO_NAME is unset — this doesn't look like a WSL session." >&2
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "  WARN: expected Ubuntu (ID=ubuntu), found ID='${ID:-unknown}'." >&2
    echo "  This script targets Ubuntu's apt repo layout and may not work as-is." >&2
  fi
fi

if ! command -v apt-get &>/dev/null; then
  echo "ERROR: apt-get not found — this script only supports Debian/Ubuntu." >&2
  exit 1
fi

if ! command -v sudo &>/dev/null; then
  echo "ERROR: sudo not found — required to install Docker Engine." >&2
  exit 1
fi

# ── Step 1: Docker Engine ─────────────────────────────────────────────────────
if command -v docker &>/dev/null; then
  echo "==> [1/4] Docker already installed ($(docker --version 2>/dev/null)), skipping apt install."
else
  echo "==> [1/4] Installing Docker Engine from Docker's apt repo..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# ── Step 2: docker group ──────────────────────────────────────────────────────
echo "==> [2/4] Ensuring '$USER' is in the docker group..."
if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
  echo "  Already a member of the docker group."
else
  sudo usermod -aG docker "$USER"
  echo "  Added $USER to the docker group (takes effect after WSL restart)."
fi

# ── Step 3: systemd in /etc/wsl.conf ──────────────────────────────────────────
echo "==> [3/4] Ensuring systemd is enabled in /etc/wsl.conf..."
WSL_CONF=/etc/wsl.conf
if [[ -f "$WSL_CONF" ]] && grep -Eq '^\s*systemd\s*=\s*true' "$WSL_CONF"; then
  echo "  systemd already enabled in $WSL_CONF."
elif [[ -f "$WSL_CONF" ]] && grep -Eq '^\s*\[boot\]' "$WSL_CONF"; then
  # A [boot] section exists but without systemd=true — insert the key under it.
  sudo cp "$WSL_CONF" "${WSL_CONF}.bak.$(date +%Y%m%d%H%M%S)"
  sudo sed -i '/^\s*\[boot\]/a systemd=true' "$WSL_CONF"
  echo "  Added systemd=true under existing [boot] section in $WSL_CONF."
else
  [[ -f "$WSL_CONF" ]] && sudo cp "$WSL_CONF" "${WSL_CONF}.bak.$(date +%Y%m%d%H%M%S)"
  printf '\n[boot]\nsystemd=true\n' | sudo tee -a "$WSL_CONF" >/dev/null
  echo "  Wrote [boot] systemd=true to $WSL_CONF."
fi

# ── Step 4: enable docker service ─────────────────────────────────────────────
echo "==> [4/4] Enabling the docker service..."
if systemctl is-system-running &>/dev/null || [[ "$(systemctl is-system-running 2>/dev/null)" == "degraded" ]]; then
  sudo systemctl enable --now docker || echo "  WARN: could not enable/start docker now; it will start after restart." >&2
else
  echo "  systemd is not active yet — docker will be enabled after the WSL restart below."
  sudo systemctl enable docker &>/dev/null || true
fi

echo ""
echo "Docker setup complete."
echo ""
echo "IMPORTANT: restart WSL for systemd and docker group membership to apply:"
echo "  1. From Windows PowerShell:  wsl --shutdown"
echo "  2. Reopen your Ubuntu distro"
echo "  3. Verify with:              docker run hello-world"
