# sbp-deploy

## English (default)

Boot-startup tooling for the sbp4ai stack on macOS. It registers three
`launchd` user agents so that after login (or reboot) the whole stack comes up
by itself:

| Label | What it runs | Port |
|---|---|---|
| `com.sbp4ai.server` | `sbp-server` — WS hub, JSONL store, device binding, `/sbp-sdk.js` | `8787` |
| `com.sbp4ai.bridge` | `sbp_supervise` — enumerates tmux sessions and raises one bridge per session, reporting to each configured endpoint | — |
| `com.sbp4ai.panel` | `panel` — the tmux/claude web frontend (also serves the SBP4AI sidebar) | `20016` |

All three use `RunAtLoad` + `KeepAlive`, so a crash is restarted automatically.

### Usage

```sh
sh ./install.sh        # install (idempotent) and print status
sh ./status.sh         # show PID/state, listening ports, tmux sessions, logs
sh ./uninstall.sh      # unload the three agents (code and config untouched)
```

### Configuration

Edit **`config.sh`**, never the plists. Knobs:
`REPO_ROOT` (parent of the six sub-repos), `PYTHON`
(interpreter that has `fastapi / uvicorn / python-dotenv / aiohttp / pyyaml`),
`SERVER_HOST/PORT`, `PANEL_HOST/PORT`, `SBP_HOME` (`~/.sbp`, holds logs and config).

Two generated files:
- `~/.sbp/env.sh` — environment for the launchd children. **launchd does not read
  your `~/.zshrc`**, so anything the agents need (PATH to `node`/`qwen`, API keys)
  goes here. After editing: `launchctl kickstart -k gui/$UID/com.sbp4ai.bridge`.
- `~/.sbp/bridge-supervisor.yaml` — poll interval, rows/cols, adapter map
  (`claude`, `qwen`/`qwen-code`), include/exclude lists, and the `endpoints` to
  report to (`local` = the local server, `remote` disabled by default).

The panel reads `.env` from its working directory; if it is missing,
`install.sh` writes an empty one so the panel starts in local no-login mode.

### Notes

- The bridge only dials **out** — the machine never opens an inbound port.
- Logs: `~/.sbp/logs/` (`server.log`, `supervisor.log`, `panel.log`,
  `bridge-local-<session>.log`).
- If `launchctl bootstrap` is run from a non-GUI context (a sandboxed shell, an
  SSH session without Aqua) it fails with `Bootstrap failed: 5: Input/output
  error`. The plists are still valid and **do** load at the next login; to adopt
  them into the current session, run `install.sh` from a real Terminal.

## 中文

sbp4ai 技术栈在 macOS 上的**开机自启**工具。它注册三个 `launchd` 用户级任务，
登录 / 重启后整套栈会自己起来：

| Label | 运行内容 | 端口 |
|---|---|---|
| `com.sbp4ai.server` | `sbp-server`（WS 枢纽、JSONL 存储、设备绑定、`/sbp-sdk.js`） | `8787` |
| `com.sbp4ai.bridge` | `sbp_supervise`（枚举 tmux 会话，每个会话拉一个 bridge 并上报到各端点） | — |
| `com.sbp4ai.panel` | `panel`（tmux/claude 网页前端，同时托管 SBP4AI 侧边栏） | `20016` |

三者都是 `RunAtLoad` + `KeepAlive`，进程挂了会自动拉回。

### 用法

```sh
sh ./install.sh        # 安装（幂等）并打印状态
sh ./status.sh         # 查看 PID/状态、监听端口、tmux 会话、日志
sh ./uninstall.sh      # 卸载三个任务（代码和配置不动）
```

### 配置

改 **`config.sh`**，不要改 plist。可调整：
`REPO_ROOT`（六个子仓的父目录）、`PYTHON`（需装有
`fastapi / uvicorn / python-dotenv / aiohttp / pyyaml` 的解释器）、
`SERVER_HOST/PORT`、`PANEL_HOST/PORT`、`SBP_HOME`（默认 `~/.sbp`，放日志与配置）。

两个会自动生成的文件：
- `~/.sbp/env.sh`：给 launchd 子进程注入的环境变量。**launchd 不读你的
  `~/.zshrc`**，子进程需要的（`node`/`qwen` 的 PATH、各家 API key）都写在这里。
  改完执行：`launchctl kickstart -k gui/$UID/com.sbp4ai.bridge`。
- `~/.sbp/bridge-supervisor.yaml`：轮询间隔、rows/cols、adapter 映射
  （`claude`、`qwen`/`qwen-code`）、include/exclude 列表，以及要上报的
  `endpoints`（`local` 指本地 server，`remote` 默认关闭）。

panel 从自身工作目录读 `.env`；若不存在，`install.sh` 会写一个空的，
让 panel 以「本机免登录」方式启动。

### 注意

- bridge 只**向外**拨号，本机不开放任何入站端口。
- 日志在 `~/.sbp/logs/`（`server.log`、`supervisor.log`、`panel.log`、
  `bridge-local-<会话>.log`）。
- 在非 GUI 上下文（沙箱 shell、无 Aqua 的 SSH）里执行
  `launchctl bootstrap` 会报 `Bootstrap failed: 5: Input/output error`。
  plist 本身是有效的，**下次登录仍会自动加载**；要在本会话立即托管，
  请在真实终端里跑一次 `install.sh`。
