#!/usr/bin/env bash
# Runs on the HOST (devcontainer.json initializeCommand) — NOT inside the container.
#
# Publishes the host compositor's Wayland socket at a fixed path so the clipboard
# mount in devcontainer.json can be unconditional: the spec has no way to make a
# mount optional, and podman refuses to start when a bind source doesn't exist.
# Hosts with no Wayland session get a placeholder file instead — the container
# still comes up, wl-copy just fails to connect and Neovim/nushell fall back to
# OSC 52 (see .devcontainer/README.md, "Clipboard").
#
# The path is hardcoded rather than derived from XDG_CACHE_HOME: devcontainer.json's
# mount source has to name the same path literally, and ${localEnv:...} has no
# default-value syntax.
set -euo pipefail

shim_dir="$HOME/.cache/devcontainer/clipboard"
link="$shim_dir/wayland-0"
mkdir -p "$shim_dir"

# WAYLAND_DISPLAY is either an absolute socket path or a name relative to
# XDG_RUNTIME_DIR (libwayland accepts both).
sock=""
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
  case "$WAYLAND_DISPLAY" in
  /*) sock="$WAYLAND_DISPLAY" ;;
  *) sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$WAYLAND_DISPLAY" ;;
  esac
fi

rm -f "$link"
if [ -n "$sock" ] && [ -S "$sock" ]; then
  # podman/docker resolve the symlink host-side, so the container gets a bind
  # mount of the real socket.
  ln -s "$sock" "$link"
else
  : >"$link"
fi
