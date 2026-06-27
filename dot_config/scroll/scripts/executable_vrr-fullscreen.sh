#!/usr/bin/env bash

VRR_BLACKLIST=("mpv" "firefox" "zen-browser" "chromium" "vlc")

scrollmsg -t subscribe -m '["window"]' | while read -r event_json; do
  change=$(echo "$event_json" | jq -r '.change')
  if [[ "$change" == "fullscreen_mode" || "$change" == "focus" ]]; then
    fullscreen=$(echo "$event_json" | jq -r '.container.fullscreen_mode')
    app_id=$(echo "$event_json" | jq -r '.container.app_id // .container.window_properties.class // ""')

    if [[ "$fullscreen" != "0" && "$fullscreen" != "null" ]]; then
      blocked=false
      for app in "${VRR_BLACKLIST[@]}"; do
        [[ "$app_id" == "$app" ]] && blocked=true && break
      done
      [[ "$blocked" == "false" ]] && scrollmsg output '*' adaptive_sync on || scrollmsg output '*' adaptive_sync off
    else
      scrollmsg output '*' adaptive_sync off
    fi
  fi
done
