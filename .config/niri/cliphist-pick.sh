#!/usr/bin/env bash

items=$(cliphist list)

[ -z "$items" ] && exit 0

idx=$(echo "$items" | sed 's/^[0-9]*\t//' | fuzzel -d --prompt='󱘣 ' --index)

if [ -n "$idx" ]; then
    echo "$items" | sed -n "$((idx + 1))p" | cliphist decode | wl-copy
fi
