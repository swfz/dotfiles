#!/bin/bash
# Toggl APIプロキシサーバ（~/memo/apps/ts-input/server/toggl2ts-server.rb）を
# systemdユーザーサービスとして常駐させるセットアップスクリプト
# 前提
#   WSL環境でsystemdを利用
#   Rubyはmise管理（shim経由で起動するのでバージョン更新の影響を受けない）
#   webrick gemがインストール済みであること（gem install webrick）
# トークンは ~/.config/toggl/api.env に置く（toggl-* 系サービスで共有する想定）

set -e

echo "=== Setting up Toggl Proxy Service ==="

DOTFILES_DIR="$HOME/dotfiles"
SERVICE_SRC="$DOTFILES_DIR/systemd/toggl-proxy.service"

mkdir -p "$HOME/.config/systemd/user"
ln -sf "$SERVICE_SRC" "$HOME/.config/systemd/user/toggl-proxy.service"
echo "✅ Linked service file"

TOGGL_DIR="$HOME/.config/toggl"
TOGGL_FILE="$TOGGL_DIR/api.env"

if [ ! -f "$TOGGL_FILE" ]; then
    echo "⚠️  WARNING: Token file not found at $TOGGL_FILE"
    echo "   Creating directory..."
    mkdir -p "$TOGGL_DIR"
    echo "   Please create 'api.env' with TOGGL_TOKEN (and optionally TOGGL_WORKSPACE_ID / TOGGL2TS_PORT) manually."
else
    echo "✅ Toggl env file found."
fi

echo "🔄 Reloading systemd..."
systemctl --user daemon-reload
systemctl --user enable toggl-proxy
systemctl --user restart toggl-proxy

echo "=== Setup Complete! ==="
systemctl --user status toggl-proxy --no-pager | head -n 10
