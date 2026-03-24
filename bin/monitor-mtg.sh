#!/bin/bash

export PATH="$HOME/.local/share/mise/shims:$PATH"

# 監視間隔（秒）
REG_EXE="/mnt/c/Windows/System32/reg.exe"
ARP_EXE="/mnt/c/Windows/System32/arp.exe"
ROUTE_EXE="/mnt/c/Windows/System32/route.exe"
BASE_KEY="HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"

INTERVAL=5
LAST_STATE=""

# 除外するアプリのパターン（Windows音声入力など）
EXCLUDE_APPS="MicrosoftWindows.Client.CBS"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

get_gateway_mac() {
    local gateway_ip
    gateway_ip=$("$ROUTE_EXE" print 0.0.0.0 2>/dev/null | awk '/0\.0\.0\.0/{for(i=1;i<=NF;i++) if($i~/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && $i!="0.0.0.0") {print $i; exit}}')
    if [ -n "$gateway_ip" ]; then
        "$ARP_EXE" -a "$gateway_ip" 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i~/[0-9a-f][0-9a-f]-[0-9a-f][0-9a-f]-/) {print $i; exit}}'
    fi
}

is_home_network() {
    if [ -z "$HOME_GATEWAY_MAC" ]; then
        return 0
    fi

    local current_mac
    current_mac=$(get_gateway_mac)
    [ "$current_mac" = "$HOME_GATEWAY_MAC" ]
}

check_device() {
    local device=$1
    "$REG_EXE" query "$BASE_KEY\\$device" /s 2>/dev/null | awk '
        /^HKEY/ { path=$0 }
        /LastUsedTimeStop/ && /0x0/ {
            n=split(path, a, "\\");
            print a[n]
        }
    ' | grep -v "$EXCLUDE_APPS"
}

echo "Monitoring started..."

while true; do
    if ! is_home_network; then
        if [ "$LAST_STATE" == "on" ]; then
            log "Left home network, turning off"
            ruby ~/dotfiles/bin/swithbot.rb off
            LAST_STATE="off"
        fi
        sleep $INTERVAL
        continue
    fi

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

