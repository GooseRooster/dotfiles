#!/usr/bin/env bash

sleep 1

swaymsg reload

pkill -SIGWINCH yazi
