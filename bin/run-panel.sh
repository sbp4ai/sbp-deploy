#!/bin/sh
# 拉起 sbp-agent/panel：tmux 会话的网页前端（侧边栏要嵌的就是它）。
# 注意 panel 从 cwd 读 .env，所以必须 cd 到 panel 目录。
set -e
DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$DIR/config.sh"
cd "$REPO_ROOT/sbp-agent/panel"
mkdir -p "$LOG_DIR"
exec env \
  PYTHONPATH="$REPO_ROOT/sbp-agent/panel:$REPO_ROOT/sbp-agent/bridge" \
  HOST="$PANEL_HOST" \
  PORT="$PANEL_PORT" \
  PYTHONUNBUFFERED=1 \
  "$PYTHON" -m tmux_panel
