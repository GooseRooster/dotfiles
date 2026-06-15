#!/usr/bin/env bash
# ~/.config/scroll/scripts/capture.sh
# Unified screenshot & recording with HDR support via gpu-screen-recorder
# Dependencies: gpu-screen-recorder, grim, slurp, ffmpeg, wl-clipboard, jq, libnotify
#
# scroll config:
#   bindsym Print              exec ~/.config/scroll/scripts/capture.sh screenshot full
#   bindsym $mod+Print         exec ~/.config/scroll/scripts/capture.sh screenshot region
#   bindsym $mod+r             exec ~/.config/scroll/scripts/capture.sh record
#   bindsym $mod+Shift+r       exec ~/.config/scroll/scripts/capture.sh record region
#   bindsym $mod+Ctrl+r        exec ~/.config/scroll/scripts/capture.sh record full mic
#   bindsym $mod+Ctrl+Shift+r  exec ~/.config/scroll/scripts/capture.sh record region mic

# ── User config ───────────────────────────────────────────────────────────────
SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
RECORDINGS_DIR="$HOME/Videos/Recordings"
RECORD_FPS=60
AUDIO_SOURCE="default_output"
MIC_SOURCE="default_input"
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

ACTION="${1:-screenshot}"
MODE="${2:-full}"
MIC="${3:-}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

RECORD_PIDFILE="/tmp/capture-recording.pid"
RECORD_OUTFILE="/tmp/capture-recording-outfile"

mkdir -p "$SCREENSHOTS_DIR" "$RECORDINGS_DIR"

# Query scrollmsg once for both HDR detection and focused output name
OUTPUTS=$(scrollmsg -t get_outputs)
HDR_ACTIVE=$(echo "$OUTPUTS" | jq 'any(.[]; .hdr == true)')
FOCUSED_OUTPUT=$(echo "$OUTPUTS" | jq -r '.[] | select(.focused == true) | .name')

# Convert slurp geometry (X,Y WxH) → gpu-screen-recorder region (WxH+X+Y)
slurp_to_gsr_region() {
  local pos="${1% *}" size="${1#* }"
  local x="${pos%,*}" y="${pos#*,}"
  local w="${size%x*}" h="${size#*x}"
  echo "${w}x${h}+${x}+${y}"
}

case "$ACTION" in

# ── Screenshot ────────────────────────────────────────────────────────────
screenshot)
  OUTFILE="$SCREENSHOTS_DIR/screenshot_${TIMESTAMP}.png"

  if [[ "$HDR_ACTIVE" == "true" ]]; then
    TMPVID=$(mktemp /tmp/capture_XXXXXX.mp4)
    trap "rm -f '$TMPVID'" EXIT

    # Build capture args
    GSR_ARGS=(-k hevc_hdr -cr full -f 60 -cursor no -v no -o "$TMPVID")

    if [[ "$MODE" == "region" ]]; then
      GEO=$(slurp -d) || exit 0
      GSR_ARGS=(-w region -region "$(slurp_to_gsr_region "$GEO")" "${GSR_ARGS[@]}")
    else
      GSR_ARGS=(-w "$FOCUSED_OUTPUT" "${GSR_ARGS[@]}")
    fi

    gpu-screen-recorder "${GSR_ARGS[@]}" &
    GSR_PID=$!
    sleep 0.5
    kill "$GSR_PID"
    wait "$GSR_PID" 2>/dev/null || true

    # Extract first frame and tonemap PQ → SDR BT.709
    # zscale auto-detects input colorspace from hevc_hdr metadata
    ffmpeg -loglevel error -i "$TMPVID" -vframes 1 \
      -vf "zscale=transfer=linear:npl=100,\
tonemap=hable,\
zscale=transfer=bt709:primaries=bt709:matrix=bt709,\
format=rgb24" \
      "$OUTFILE"
  else
    # SDR: grim is lossless and has no intermediate video overhead
    if [[ "$MODE" == "region" ]]; then
      GEO=$(slurp -d) || exit 0
      grim -g "$GEO" "$OUTFILE"
    else
      grim "$OUTFILE"
    fi
  fi

  wl-copy -t image/png <"$OUTFILE"
  notify-send -i "camera" -t 3000 "Screenshot" "$(basename "$OUTFILE")"
  ;;

# ── Recording (toggle) ────────────────────────────────────────────────────
record)
  if [[ -f "$RECORD_PIDFILE" ]]; then
    GSR_PID=$(cat "$RECORD_PIDFILE")

    if kill -0 "$GSR_PID" 2>/dev/null; then
      kill "$GSR_PID"
      wait "$GSR_PID" 2>/dev/null || true
    fi

    SAVED=$(cat "$RECORD_OUTFILE" 2>/dev/null || echo "unknown")
    rm -f "$RECORD_PIDFILE" "$RECORD_OUTFILE"
    notify-send -i "media-record" -t 4000 "Recording saved" "$(basename "$SAVED")"
  else
    OUT="$RECORDINGS_DIR/recording_${TIMESTAMP}.mp4"

    GSR_ARGS=()

    if [[ "$MODE" == "region" ]]; then
      GEO=$(slurp -d) || exit 0
      GSR_ARGS+=(-w region -region "$(slurp_to_gsr_region "$GEO")")
    else
      GSR_ARGS+=(-w "$FOCUSED_OUTPUT")
    fi

    if [[ "$HDR_ACTIVE" == "true" ]]; then
      GSR_ARGS+=(-k hevc_hdr -cr full)
    else
      GSR_ARGS+=(-k hevc)
    fi

    GSR_ARGS+=(-f "$RECORD_FPS" -a "$AUDIO_SOURCE" -cursor yes -v no -o "$OUT")
    [[ "$MIC" == "mic" ]] && GSR_ARGS+=(-a "$MIC_SOURCE")

    gpu-screen-recorder "${GSR_ARGS[@]}" &
    echo $! >"$RECORD_PIDFILE"
    echo "$OUT" >"$RECORD_OUTFILE"
    NOTIFY_BODY="$(basename "$OUT")$([[ "$MIC" == "mic" ]] && echo " · mic on" || true)"
    notify-send -i "media-record" -t 3000 "Recording started" "$NOTIFY_BODY"
  fi
  ;;

*)
  echo "Usage: $0 [screenshot|record] [full|region]" >&2
  exit 1
  ;;
esac
