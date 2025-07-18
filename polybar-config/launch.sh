#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Find the primary monitor and launch the dock there
PRIMARY_MONITOR=$(xrandr --query | grep " primary" | cut -d" " -f1)
MONITOR=$PRIMARY_MONITOR polybar dock &

echo "Polybar launched..."
