#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch the dock, explicitly specifying the correct config file with -c
polybar -c /etc/polybar/config.ini dock &

echo "Polybar launched..."
