#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Wallpapers" "$WALLPAPER_DIR not found."
    exit 1
fi

SELECTED=$(ls -1 "$WALLPAPER_DIR" | fuzzel -d -p "Wallpaper: ")

[ -z "$SELECTED" ] && exit 0

TARGET="$WALLPAPER_DIR/$SELECTED"

OLD_PID=$(pgrep -x swaybg)

swaybg -i "$TARGET" -m fill &

sleep 0.3
if [ -n "$OLD_PID" ]; then
    kill $OLD_PID
fi
