#!/bin/bash

# 監視間隔（秒）
INTERVAL=5
REG_EXE="/mnt/c/Windows/System32/reg.exe"
BASE_KEY="HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"

export PATH="$HOME/.local/share/mise/shims:$PATH"

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

    # 状態判定
    if [ -n "$CAM_APP" ]; then
        STATUS="VIDEO_MEETING"
        APP="$CAM_APP"
        ruby ~/dotfiles/bin/swithbot.rb on
    elif [ -n "$MIC_APP" ]; then
        STATUS="AUDIO_HUDDLE"
        APP="$MIC_APP"
        ruby ~/dotfiles/bin/swithbot.rb on
    else
        STATUS="IDLE"
        APP=""
        ruby ~/dotfiles/bin/swithbot.rb off
    fi

    echo "[$(date)] Status: $STATUS (App: $APP)"

    sleep $INTERVAL
done
