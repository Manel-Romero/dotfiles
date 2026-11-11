#!/usr/bin/env bash

TOGGLE_FILE="/tmp/waybar_bat_intel_toggle"

CAP=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
STATUS=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)

if [ "$CAP" -ge 90 ]; then ICON="";
elif [ "$CAP" -ge 60 ]; then ICON="";
elif [ "$CAP" -ge 40 ]; then ICON="";
elif [ "$CAP" -ge 15 ]; then ICON="";
else ICON=""; fi

if [ "$STATUS" = "Charging" ]; then
    ICON="󰂄"
fi

CLASS=""
if [ "$CAP" -le 15 ]; then CLASS="critical";
elif [ "$CAP" -le 30 ]; then CLASS="warning"; fi

if [ -f "$TOGGLE_FILE" ]; then
    P="/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj"
    E1=$(cat "$P")
    sleep 0.3
    E2=$(cat "$P")
    WATTS=$(awk -v e1="$E1" -v e2="$E2" 'BEGIN {printf "%.1f", (e2-e1)/300000}')
    
    if [ "$STATUS" = "Charging" ]; then
        TEXT="+${WATTS}W ${CAP}% ${ICON}"
    else
        TEXT="${WATTS}W ${CAP}% ${ICON}"
    fi
else
    TEXT="${CAP}% ${ICON}"
fi

echo "{\"text\": \"$TEXT\", \"class\": \"$CLASS\", \"tooltip\": \"SoC: ${STATUS}\"}"
