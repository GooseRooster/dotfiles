#!/usr/bin/env bash
APP_ID="scratchpad-term"

exists=$(swaymsg -t get_tree | jq -r ".. | objects | select(.app_id? == \"$APP_ID\") | .id" 2>/dev/null | head -1)

if [ -z "$exists" ]; then
  kitty --app-id="$APP_ID" &
  sleep 0.5
  swaymsg "[app_id=\"$APP_ID\"] move scratchpad"
fi

swaymsg "[app_id=\"$APP_ID\"] scratchpad show, move position center"
