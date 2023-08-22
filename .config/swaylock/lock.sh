#!/bin/sh
# Times the screen off and puts it to background
swayidle \
    timeout 15 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' &
# Locks the screen immediately
swaylock -C /$HOME/.config/swaylock/config
# Kills last background task so idle timer doesn't keep running
pkill --newest swayidle