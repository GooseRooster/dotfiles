#!/usr/bin/env bash

#Give the wallpaper time to change
sleep 1

#Trigger sway config reload over IPC
swaymsg reload

#Force yazi processes to redraw by faking a resize event
pkill -SIGWINCH yazi
