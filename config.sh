#!/bin/sh
# sbp4ai 部署配置 —— 改这里，不要改 launchd plist。
# install.sh 会把三个服务装进 ~/Library/LaunchAgents，开机自动拉起。

# 代码根目录（6 个子仓都在它下面）
REPO_ROOT="${REPO_ROOT:-/Users/mac/codes/sbp4ai}"

# 运行解释器。这个 venv 里装齐了 fastapi / uvicorn / python-dotenv / aiohttp / pyyaml。
# 换成你自己的 python 也可以，只要上面五个包都在。
PYTHON="${PYTHON:-/Users/mac/glbpy14/glbpy14/bin/python3}"

# ---- sbp-server（中心枢纽）----
SERVER_HOST="${SERVER_HOST:-127.0.0.1}"
SERVER_PORT="${SERVER_PORT:-8787}"

# ---- sbp-agent/panel（网页前端）----
PANEL_HOST="${PANEL_HOST:-127.0.0.1}"
PANEL_PORT="${PANEL_PORT:-20016}"

# ---- 日志 / 状态目录 ----
SBP_HOME="${SBP_HOME:-$HOME/.sbp}"
LOG_DIR="$SBP_HOME/logs"

export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
