#!/usr/bin/env zsh
# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar
# Launch polybar on all monitors
if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload main -c ~/.config/polybar/config.ini &
  done
else
  polybar --reload main -c ~/.config/polybar/config.ini &
fi
echo "Polybar launched..."
