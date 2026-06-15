#!/usr/bin/env bash

#Give the wallpaper time to change
sleep 1

#Trigger scroll config reload over IPC
scrollmsg reload

#Force yazi processes to redraw by faking a resize event
pkill -SIGWINCH yazi
