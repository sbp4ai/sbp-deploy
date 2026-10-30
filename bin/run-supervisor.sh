#!/bin/sh
# 拉起 sbp-supervise：枚举全部 tmux 会话，逐个拉起 bridge 上报到本地 + 远端 server。
# 会话/端点列表、端的地址都写在 ~/.sbp/bridge-supervisor.yaml。
set -e
DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$DIR/config.sh"
cd "$REPO_ROOT/sbp-agent/bridge"
mkdir -p "$LOG_DIR" "$SBP_HOME"
exec env \
  PYTHONPATH="$REPO_ROOT/sbp-agent/bridge" \
  PYTHONUNBUFFERED=1 \
  "$PYTHON" sbp_supervise.py
