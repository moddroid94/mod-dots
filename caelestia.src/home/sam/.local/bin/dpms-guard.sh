#!/bin/sh
# ~/.local/bin/dpms-guard.sh

SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - "UNIX-CONNECT:$SOCK" | while IFS= read -r line; do
    echo "[$(date +%T)] $line" >&2
    case "$line" in
        "monitorremoved>>DP-1")
            date +%s > /tmp/dp1-drop-time
            ;;
        "monitoradded>>DP-1")
            if [ -f /tmp/dp1-drop-time ]; then
                drop=$(cat /tmp/dp1-drop-time)
                now=$(date +%s)
                if [ $((now - drop)) -lt 10 ]; then
                    sleep 0.5
                    hyprctl dispatch 'hl.dsp.dpms({ action = "disable"})'
                fi
            fi
            rm -f /tmp/dp1-drop-time
            ;;
    esac
done   