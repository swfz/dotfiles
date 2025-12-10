#!/bin/bash

export PATH="$HOME/.local/share/mise/shims:$PATH"

# 監視間隔（秒）
REG_EXE="/mnt/c/Windows/System32/reg.exe"
BASE_KEY="HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"

INTERVAL=5
LAST_STATE=""

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

check_device() {
    local device=$1
    "$REG_EXE" query "$BASE_KEY\\$device" /s 2>/dev/null | awk '
        /^HKEY/ { path=$0 }
        /LastUsedTimeStop/ && /0x0/ {
            n=split(path, a, "\\");
            print a[n]
        }
    '
}

echo "Monitoring started..."

while true; do
    CAM_APP=$(check_device "webcam")
    MIC_APP=$(check_device "microphone")

    if [ -n "$CAM_APP" ] || [ -n "$MIC_APP" ]; then
        TARGET_STATE="on"
        ACTIVE_APP="${CAM_APP}${MIC_APP}"
    else
        TARGET_STATE="off"
        ACTIVE_APP=""
    fi

    if [ "$TARGET_STATE" != "$LAST_STATE" ]; then
        if [ "$TARGET_STATE" == "on" ]; then
            log "Status Change: OFF -> ON (Active App: $ACTIVE_APP)"
            ruby ~/dotfiles/bin/swithbot.rb on
        else
            log "Status Change: ON -> OFF (Idle)"
            ruby ~/dotfiles/bin/swithbot.rb off
        fi

        LAST_STATE="$TARGET_STATE"
    fi

    sleep $INTERVAL
done

