#!/bin/sh
# 查看三个服务的存活状态与端口监听情况。
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/config.sh"
DOMAIN="gui/$(id -u)"

printf '%-22s %s\n' "SERVICE" "PID / STATUS"
printf '%-22s %s\n' "-------" "-----------"
for label in com.sbp4ai.server com.sbp4ai.bridge com.sbp4ai.panel; do
  info=$(launchctl print "$DOMAIN/$label" 2>/dev/null)
  if [ -n "$info" ]; then
    pid=$(printf '%s\n' "$info" | awk '$1=="pid"||$1=="PID"{print $NF}' | head -1)
    state=$(printf '%s\n' "$info" | grep -m1 -A0 "state =" | head -1)
    printf '%-22s pid=%s %s\n' "$label" "${pid:-?}" "$state"
  else
    printf '%-22s %s\n' "$label" "not loaded"
  fi
done

echo
echo "== ports =="
for p in "$SERVER_PORT" "$PANEL_PORT"; do
  hit=$(lsof -nP -iTCP:"$p" -sTCP:LISTEN 2>/dev/null | tail -n +2 | head -1)
  if [ -n "$hit" ]; then echo "  $p  LISTEN  $hit"; else echo "  $p  (not listening)"; fi
done

echo
echo "== tmux sessions =="
tmux list-sessions -F '  #{session_name}  (#{pane_start_command})' 2>/dev/null || echo "  (no tmux server)"

echo
echo "== logs =="
ls -1 "$LOG_DIR" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
