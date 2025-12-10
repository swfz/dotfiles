#!/bin/bash

set -e

echo "=== Setting up Meeting Monitor Service ==="

DOTFILES_DIR="$HOME/dotfiles"
BIN_SRC="$DOTFILES_DIR/bin/monitor-mtg.sh"
SERVICE_SRC="$DOTFILES_DIR/systemd/mtg-monitor.service"

mkdir -p "$HOME/.config/systemd/user"
ln -sf "$SERVICE_SRC" "$HOME/.config/systemd/user/mtg-monitor.service"
echo "✅ Linked service file"

SWITCHBOT_DIR="$HOME/.config/switchbot"
SWITCHBOT_FILE="$SWITCHBOT_DIR/api.env"

if [ ! -f "$SWITCHBOT_FILE" ]; then
    echo "⚠️  WARNING: Token file not found at $SWITCHBOT_FILE"
    echo "   Creating directory..."
    mkdir -p "$SWITCHBOT_DIR"
    echo "   Please create 'api.env' with SWITCHBOT_SWITCHBOT and SWITCHBOT_SECRET and SWITCHBOT_DEVICE_ID manually."
else
    echo "✅ Switchbot file found."
fi

echo "🔄 Reloading systemd..."
systemctl --user daemon-reload
systemctl --user enable mtg-monitor
systemctl --user restart mtg-monitor

echo "=== Setup Complete! ==="
systemctl --user status mtg-monitor --no-pager | head -n 10

