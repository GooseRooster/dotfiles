#!/bin/bash
# Usage: screenshot.sh [region|output|window]
SAVEDIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVEDIR"
FILE="$SAVEDIR/$(date +%Y%m%d_%H%M%S).png"

case "$1" in
output)
  grim -o "$(scrollmsg -t get_outputs | jq -r '.[] | select(.focused) | .name')" - |
    tee "$FILE" | wl-copy
  ;;
window)
  scrollmsg -t get_tree |
    jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' |
    grim -g - - | tee "$FILE" | wl-copy
  ;;
*)
  grim -g "$(slurp -d)" - | tee "$FILE" | wl-copy
  ;;
esac

notify-send "Screenshot" "$FILE" -i "$FILE"
