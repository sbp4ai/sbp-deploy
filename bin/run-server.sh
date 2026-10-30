#!/bin/sh
# 拉起 sbp-server：WS hub + JSONL store + device binding + /sbp-sdk.js
set -e
DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$DIR/config.sh"
cd "$REPO_ROOT/sbp-server"
mkdir -p "$LOG_DIR"
exec env \
  PYTHONPATH="$REPO_ROOT/sbp-server/server" \
  SBP_HOST="$SERVER_HOST" \
  SBP_PORT="$SERVER_PORT" \
  PYTHONUNBUFFERED=1 \
  "$PYTHON" -m sbp_server.app
