#!/bin/sh
# 卸载三个开机自启服务。只是摘掉 launchd 任务，不动你的代码和配置。
set -e
DIR=$(cd "$(dirname "$0")" && pwd)
DOMAIN="gui/$(id -u)"
AGENTS="$HOME/Library/LaunchAgents"

for label in com.sbp4ai.server com.sbp4ai.bridge com.sbp4ai.panel; do
  launchctl bootout "$DOMAIN/$label" >/dev/null 2>&1 && echo "  bootout $label" \
    || launchctl remove "$label" >/dev/null 2>&1 || true
  rm -f "$AGENTS/$label.plist"
done
echo "  已卸载。plist 已从 ~/Library/LaunchAgents 移除。"
