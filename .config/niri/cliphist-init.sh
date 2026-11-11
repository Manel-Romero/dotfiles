#!/bin/bash
killall wl-paste

cliphist list | tail -n +101 | cliphist delete

wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
