#!/usr/bin/env bash
# ~/.config/sway/scripts/screenshot.sh
# Dependencies: grim, slurp, ffmpeg, wl-clipboard, jq, libnotify
#
# Usage:
#   screenshot.sh full    — capture whole screen
#   screenshot.sh region  — interactive slurp selection
#
# Sway config:
#   bindsym Print         exec ~/.config/sway/scripts/screenshot.sh full
#   bindsym $mod+Print    exec ~/.config/sway/scripts/screenshot.sh region

set -euo pipefail

MODE="${1:-full}"
SAVEDIR="$HOME/Pictures/Screenshots"
OUTFILE="$SAVEDIR/screenshot_$(date +%Y%m%d_%H%M%S).png"
GEOMETRY=""

mkdir -p "$SAVEDIR"

case "$MODE" in
region)
  # Exit silently if the user cancels the selection
  GEOMETRY=$(slurp -d) || exit 0
  ;;
full)
  ;;
*)
  echo "Usage: $0 [full|region]" >&2
  exit 1
  ;;
esac

# Check if HDR is active on any output.
hdr_active=$(swaymsg -t get_outputs | jq 'any(.[]; .hdr == true)')

GRIM_ARGS=()
[[ -n "$GEOMETRY" ]] && GRIM_ARGS+=(-g "$GEOMETRY")

if [[ "$hdr_active" == "true" ]]; then
  # HDR path: capture raw PPM, tonemap to SDR via ffmpeg, write PNG
  grim -t ppm "${GRIM_ARGS[@]}" - |
    ffmpeg -loglevel error -i pipe:0 \
      -vf "zscale=transfer=linear,tonemap=hable,zscale=transfer=bt709" \
      -frames:v 1 "$OUTFILE"
else
  # SDR path: capture directly as PNG
  grim "${GRIM_ARGS[@]}" "$OUTFILE"
fi

wl-copy -t image/png <"$OUTFILE"
notify-send -i "camera" -t 3000 "Screenshot" "$(basename "$OUTFILE")"
