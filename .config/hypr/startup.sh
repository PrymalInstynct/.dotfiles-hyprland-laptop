#!/bin/bash
# Open kitty on DP-1 in workspace 1
/usr/bin/hyprctl dispatch focusmonitor DP-10
/usr/bin/hyprctl dispatch exec [workspace 1] /usr/bin/kitty
# Wait for kitty to be fully started
sleep 1
# Ensure the kitty window is in focus
/usr/bin/hyprctl dispatch focuswindow kitty
# Open Discord in workspace 1 on DP-10
/usr/bin/hyprctl dispatch exec [workspace 1] /usr/bin/discord
# Wait for Discord to be fully started (Stupid Splash Screen)
sleep 5
# Ensure the kitty window is in focus
/usr/bin/hyprctl dispatch focuswindow kitty
# Open Spotify in workspace 1
/usr/bin/hyprctl dispatch exec [workspace 1] /usr/bin/spotify
# Ensure DP-11 is still in focous
/usr/bin/hyprctl dispatch focusmonitor DP-11
# Open Brave in workspace 1 (Always opens to the Left of kitty)
/usr/bin/hyprctl dispatch exec [workspace 2] /usr/bin/brave
# Wait for Brave to be fully started
sleep 2
# Ensure the kitty window is in focus
/usr/bin/hyprctl dispatch focuswindow brave
# Open VSCode in workspace 2 (Always opens to the left of kitty, ensuring it is in the center of the screen)
/usr/bin/hyprctl dispatch exec [workspace 2] /usr/bin/code
