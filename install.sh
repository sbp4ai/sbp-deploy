#!/bin/sh
# 安装/重装三个开机自启服务：sbp-server / sbp-bridge supervisor / sbp-agent panel。
# 幂等：反复执行只会先 bootout 再 bootstrap。
set -e

DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/config.sh"

DOMAIN="gui/$(id -u)"
AGENTS="$HOME/Library/LaunchAgents"
LABELS="com.sbp4ai.server com.sbp4ai.bridge com.sbp4ai.panel"

echo "== config =="
echo "  REPO_ROOT   : $REPO_ROOT"
echo "  PYTHON      : $PYTHON"
echo "  server      : $SERVER_HOST:$SERVER_PORT"
echo "  panel       : $PANEL_HOST:$PANEL_PORT"
echo "  SBP_HOME    : $SBP_HOME"

# ---- 前置检查 ----
[ -x "$PYTHON" ] || { echo "!! 解释器不存在: $PYTHON"; exit 1; }
[ -d "$REPO_ROOT/sbp-server" ] || { echo "!! 缺少 $REPO_ROOT/sbp-server"; exit 1; }
[ -d "$REPO_ROOT/sbp-agent" ] || { echo "!! 缺少 $REPO_ROOT/sbp-agent"; exit 1; }

mkdir -p "$LOG_DIR" "$AGENTS"

# panel 首次启动若无 .env 会生成随机账号密码，自启后没人知道答案 —— 这里先落一个空的，
# 让它稳定以「本机免登录」方式起来（想开登录见 README）。
if [ ! -f "$REPO_ROOT/sbp-agent/panel/.env" ]; then
  printf '# 本机自启：留空 = 关闭登录。需要登录时填下面两个再重启服务。\nPANEL_ACCOUNT=\nPANEL_SECERT=\n' \
    > "$REPO_ROOT/sbp-agent/panel/.env"
  chmod 600 "$REPO_ROOT/sbp-agent/panel/.env"
  echo "  created panel/.env (auth disabled)"
fi

# launchd 不继承你的 shell —— 需要的环境变量(kimi/dashscope key、自定义 PATH)写这里。
if [ ! -f "$SBP_HOME/env.sh" ]; then
  cp "$DIR/env.sh.example" "$SBP_HOME/env.sh"
  chmod 600 "$SBP_HOME/env.sh"
  echo "  created $SBP_HOME/env.sh (edit it to add API keys)"
fi

# ---- 安装 ----
chmod +x "$DIR"/bin/*.sh
for label in $LABELS; do
  src="$DIR/launchd/$label.plist"
  dst="$AGENTS/$label.plist"
  # 已经挂载就先摘掉，否则 bootstrap 会报 "already exists"
  launchctl bootout "$DOMAIN/$label" >/dev/null 2>&1 || true
  cp "$src" "$dst"
  if launchctl bootstrap "$DOMAIN" "$dst" 2>/dev/null; then
    echo "  bootstrap  $label"
  else
    # 部分 macOS 版本上 bootstrap 已被废弃/受限，退回到 load
    launchctl unload "$dst" >/dev/null 2>&1 || true
    launchctl load -w "$dst" >/dev/null 2>&1 && echo "  load       $label" || echo "  !! 挂载失败 $label"
  fi
  launchctl kickstart -k "$DOMAIN/$label" >/dev/null 2>&1 || true
done

sleep 3
echo
echo "== installed =="
"$DIR/status.sh"
