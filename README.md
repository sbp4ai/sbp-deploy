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

### Registering SBP4AI in Work Buddy's custom menu bar

The panel is **local-only** — it reads this machine's tmux sessions and
`~/.claude/projects/*/*.jsonl` directly, so it must run on the same Mac that
runs your agents. Two things make it appear in Work Buddy:

1. **Keep the panel running.** The three `launchd` agents
   (`com.sbp4ai.server`, `com.sbp4ai.bridge`, `com.sbp4ai.panel`) are already
   registered and auto-start on login. If you ever need to start them by hand,
   run `sh ./install.sh` from a real Terminal (not a sandboxed shell, which
   hits the `Bootstrap failed: 5` error).
2. **Add a custom-menu entry in Work Buddy.** Open the **自定义菜单栏**
   (Custom Menu Bar) and add an item:
   - Name: `SBP4AI`
   - URL: `http://127.0.0.1:20016/static/sidebar.html`
   - (optional) icon of your choice.

   The sidebar is a compact tmux-session monitor: it lists sessions grouped by
   tmux, shows live/agent tags, and expands an embedded full panel for the
   selected session. For a full-page view instead, use
   `http://127.0.0.1:20016/` as the menu URL.

The panel sets **no `X-Frame-Options` / CSP**, so it embeds cleanly inside
Work Buddy's menu iframe. If an embedded view ever reports a connection error,
use the sidebar's "open in new window" button (⧉ / ↗) to launch the full
panel in a standalone tab.

### Installing the SBP4AI qwapp into QwenWork (千问办公)

The qwapp is a self-contained web app that embeds your **local** agent sessions
(Claude Code / Qwen Code / Codex / Aider / OpenCode / DSH / Qoder …) into
QwenWork's left sidebar. It talks to the local panel over REST (ETag/304 polling)
and recognises each CLI through the **unified adapter declarations** in
`sbp-spec/spec/adapters/`.

Prerequisite: the local panel (`com.sbp4ai.panel`, port `20016`) must be running on
this Mac. QwenWork is a desktop app, so the qwapp can reach it at
`http://127.0.0.1:20016`.

1. **Get the package.** It is `qwapp/sbp4ai-qwapp.zip` in this repo (contains
   `web/index.html`). Alternatively, point QwenWork straight at the same-origin URL
   `http://127.0.0.1:20016/static/qwapp.html` and skip the upload.
2. **Admin console → Navigation & Menus.** Go to *Users & experience →
   Personalization → Navigation & Menus*, click **Add custom link**.
3. Fill in:
   - Name: `SBP4AI` (≤10 chars)
   - Web address: leave blank when using the plugin package; otherwise
     `http://127.0.0.1:20016/static/qwapp.html`
   - Open: choose **open inside QwenWork (在千问办公内打开)**.
4. **Advanced configuration → Plugin package (插件包).** Upload
   `qwapp/sbp4ai-qwapp.zip` (must contain `web/index.html`, ≤50 MB). Set a
   **route id (路由标识)** such as `sbp4ai` (1–32 lowercase letters/digits/dashes,
   unique, not `knowledge-base`); the **direct link (直达链接)** is generated
   automatically. A plain web address works too — but the plugin package takes
   priority if both are present.
5. **Save and publish.** Re-open QwenWork; SBP4AI shows up in the left sidebar.
   The app lists sessions grouped by tmux with **multi-agent badges**
   (Claude Code / Qwen Code / Codex / Aider / OpenCode / DSH / Qoder …), and for
   Claude Code sessions a full **conversation history** (your messages + the
   agent's reply summaries). Tap a session to open the live terminal and send
   input / pick options.

Notes:
- The panel already sends `Access-Control-Allow-Origin: *`, so the qwapp's
  cross-origin fetch to localhost works inside the QwenWork webview.
- To target a different panel address, append `?api=https://host:port` to the
  qwapp URL, or have the host inject `window.SBP_CONFIG = { api: "..." }`.
- Adding a new CLI: drop a `*.yaml` adapter into `sbp-spec/spec/adapters/`
  (see `claude-code.yaml`, `qwen-code.yaml`, `codex.yaml`, `aider.yaml`,
  `opencode.yaml`, `qodercli.yaml`, `dsh.yaml`) and register its command name in
  `sbp_supervise.py`'s `agent_adapters`. Both the panel and the supervisor pick
  it up automatically — no code change elsewhere.

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

### 在 Work Buddy 自定义菜单栏注册 SBP4AI

panel 是**纯本机**的——它直接读这台 Mac 的 tmux 会话和
`~/.claude/projects/*/*.jsonl`，所以必须和运行智能体的同一台机器上跑。
要让它出现在 Work Buddy 里，做两件事：

1. **保证 panel 在跑。** 三个 `launchd` 任务
   （`com.sbp4ai.server`、`com.sbp4ai.bridge`、`com.sbp4ai.panel`）已经登记，
   登录 / 重启后自动起来。万一要手动起，请在**真实终端**里跑
   `sh ./install.sh`（别在沙箱 shell 里跑，会撞 `Bootstrap failed: 5`）。
2. **在 Work Buddy 里加一个自定义菜单项。** 打开 **自定义菜单栏**，新增一项：
   - 名称：`SBP4AI`
   - 网址：`http://127.0.0.1:20016/static/sidebar.html`
   - （可选）自选图标。

   这个侧栏是一个紧凑的 tmux 会话监控器：按 tmux 分组列出会话、标出
   live / 智能体标签，并能在选中会话里展开内嵌的完整面板。如果想要整页视图，
   把菜单网址换成 `http://127.0.0.1:20016/` 即可。

panel **没有设置 `X-Frame-Options` / CSP**，所以能被 Work Buddy 的菜单 iframe
干净地嵌进去。万一内嵌视图报连接错误，点侧栏里的「新窗口打开」按钮
（⧉ / ↗）在独立标签页里开完整面板即可。

### 把 SBP4AI qwapp 装进千问办公（QwenWork）左侧边栏

qwapp 是一个自包含的网页应用，把你的**本机** agent 会话（Claude Code / Qwen Code /
Codex / Aider / OpenCode / DSH / Qoder …）嵌进千问办公左侧边栏。它通过 REST
（ETag/304 轮询）与本地 panel 通信，并借助 `sbp-spec/spec/adapters/` 里的
**统一适配器声明**识别每一种 CLI。

前提：本机 panel（`com.sbp4ai.panel`，端口 `20016`）必须在跑。千问办公是桌面应用，
qwapp 能直连 `http://127.0.0.1:20016`。

1. **拿安装包。** 在本仓 `qwapp/sbp4ai-qwapp.zip`（内含 `web/index.html`）。也可以不传
   ZIP，直接让千问办公指向同源地址 `http://127.0.0.1:20016/static/qwapp.html`。
2. **管理后台 → 导航与菜单。** 进入 *用户与体验 → 个性化配置 → 导航与菜单*，点
   **添加自定义链接**。
3. 填写：
   - 名称：`SBP4AI`（≤10 字）
   - 网页地址：用插件包时留空；否则填 `http://127.0.0.1:20016/static/qwapp.html`
   - 打开方式：选 **在千问办公内打开**。
4. **高级配置 → 插件包（插件包）。** 上传 `qwapp/sbp4ai-qwapp.zip`
   （必须含 `web/index.html`，≤50 MB）。设一个**路由标识**（如 `sbp4ai`，
   1–32 个小写字母/数字/连字符，唯一，不能是 `knowledge-base`）；**直达链接**会自动生成。
   只用网页地址也行——但若同时有插件包，**插件包优先**。
5. **保存并发布。** 重新打开千问办公，左侧栏出现 SBP4AI。应用按 tmux 分组列出会话，
   带**多 CLI 徽章**（Claude Code / Qwen Code / Codex / Aider / OpenCode / DSH /
   Qoder …）；对 Claude Code 会话还展示完整**对话历史**（你发的消息 + 智能体回复摘要）。
   点开一个会话即可看到实时终端，并发送输入 / 选择选项。

说明：
- panel 已发送 `Access-Control-Allow-Origin: *`，所以 qwapp 在千问办公 webview 里
  跨源 fetch 本机 API 是通的。
- 想指向别的 panel 地址：在 qwapp 网址后加 `?api=https://host:port`，或由宿主注入
  `window.SBP_CONFIG = { api: "..." }`。
- 新增一种 CLI：往 `sbp-spec/spec/adapters/` 丢一份 `*.yaml` 适配器（参考
  `claude-code.yaml`、`qwen-code.yaml`、`codex.yaml`、`aider.yaml`、`opencode.yaml`、
  `qodercli.yaml`、`dsh.yaml`），并在 `sbp_supervise.py` 的 `agent_adapters` 里登记它的
  命令名。panel 与 supervisor 都会自动识别——其它代码无需改动。

---

## Work Buddy 集成（SBP4AI 自动注册）

SBP4AI 在 Work Buddy 里有两种接入方式，二者已经都做好了。

### A. 已发布应用（无需手点，立即可用）✅

通过「发布为应用」把 SBP4AI 登记成了 Work Buddy 的一个**应用条目**，打开即出现在应用里，
不需要在「自定义菜单栏」里手动添加。

- 分享链接：`https://sbp4ai.app.workbuddy.host/?sharecode=GAOAVQZBNI`
- 它本质是一个**全屏 iframe**，嵌入你本机正在跑的 panel
  `http://127.0.0.1:20016/static/qwapp.html`，由 panel 驱动本机 tmux 里的各类 agent
  （Claude Code / Qwen Code / Codex / Aider / OpenCode / Qoder / dsh …）。
- **约束**：因为 panel 只读本机 tmux，所以这个云端壳只在**同一台机器**上打开时可用
  （你机器上的 panel 必须处于运行态，见上面的开机自启）。
- 源码：`sbp4ai-web/index.html`（就是那个 iframe 壳）。

### B. Work Buddy 扩展包（qwapp 等价物，结构完整）

Work Buddy 的内置扩展是 **Module-Federation 微前端**：每个扩展由
`extension.json` + `distribution.json` 声明，`ui.entry.url` 指向一个 `remoteEntry.js`，
侧边栏里「灵感社区」「云助理 2.0」等都是这么进来的。这就是 Work Buddy 里等价于
千问办公 qwapp 的「侧边栏应用包」形态。

我们已经按这个格式产出了完整的 SBP4AI 扩展包（`workbuddy-extension/`）：

```
workbuddy-extension/
├── extension.json          # id/name/ui.entry(title+icon+remoteEntry.js)
├── distribution.json       # kind/permissions/trustedUrls(127.0.0.1:20016)
├── package.json            # vite + @module-federation/vite + react
├── vite.config.mjs        # 产出 ui/assets/remoteEntry.js（暴露 ./Main）
├── src/Main.jsx           # 嵌入本机 panel 的 qwapp
└── ui/assets/             # 已构建的 remoteEntry.js + chunks + icon.svg
```

- 构建：`cd workbuddy-extension && npm install && npx vite build`（已构建好，可直接用）。
- 接入方式：把整个 `workbuddy-extension/` 作为扩展目录放到 Work Buddy 的扩展加载路径
  （参考内置扩展的 `resources/extensions/<id>/`），由它的联邦清单服务发现即可在侧边栏出现。

> **现状说明**：当前 Work Buddy 的扩展由腾讯内置打包、经其联邦清单服务发现，安装包内未提供
> 用户级「丢一个包就加载」的加载器，因此该扩展包作为**标准交付物**已就绪，能否被第三方环境
> 直接加载取决于 Work Buddy 是否开放第三方扩展入口。功能逻辑（嵌入本机 panel）与方案 A 一致。

---

## Work Buddy integration (SBP4AI, programmatic registration)

SBP4AI has two ways to land inside Work Buddy; both are done.

### A. Published app (no manual click, live now) ✅

"发布为应用" registered SBP4AI as a **Work Buddy app entry** — it shows up in the app list
without adding anything in the custom menu.

- Share link: `https://sbp4ai.app.workbuddy.host/?sharecode=GAOAVQZBNI`
- It is a full-page iframe embedding your local panel
  `http://127.0.0.1:20016/static/qwapp.html`, which drives the local tmux agents
  (Claude Code / Qwen Code / Codex / Aider / OpenCode / Qoder / dsh …).
- **Constraint**: because the panel only reads local tmux, this cloud shell only works on the
  **same machine** that runs the panel (panel must be up — see launchd autostart above).
- Source: `sbp4ai-web/index.html` (the iframe shell).

### B. Work Buddy extension package (qwapp equivalent, format-complete)

Work Buddy's built-in extensions are **Module-Federation micro-frontends**: each extension is
declared by `extension.json` + `distribution.json`, `ui.entry.url` points at a `remoteEntry.js`,
and that is exactly how sidebar items like "灵感社区" / "云助理 2.0" appear. This is the Work Buddy
equivalent of Qwen Work's qwapp sidebar package.

We produced a complete SBP4AI extension package in that format (`workbuddy-extension/`):

```
workbuddy-extension/
├── extension.json          # id/name/ui.entry(title+icon+remoteEntry.js)
├── distribution.json       # kind/permissions/trustedUrls(127.0.0.1:20016)
├── package.json            # vite + @module-federation/vite + react
├── vite.config.mjs        # emits ui/assets/remoteEntry.js (exposes ./Main)
├── src/Main.jsx           # embeds the local panel qwapp
└── ui/assets/             # built remoteEntry.js + chunks + icon.svg
```

- Build: `cd workbuddy-extension && npm install && npx vite build` (already built, ready to use).
- To load: drop the whole `workbuddy-extension/` dir into Work Buddy's extension-load path
  (cf. built-in `resources/extensions/<id>/`); its federation manifest service discovers it and
  surfaces it in the sidebar.

> **Status note**: currently Work Buddy's extensions are Tencent-bundled and discovered via its
> federation manifest service; the installed app exposes no user-level "drop a package to load it"
> loader. The extension package is therefore a **format-complete deliverable**; whether a
> third-party environment can load it depends on Work Buddy opening a third-party extension entry.
> Its runtime behavior (embedding the local panel) is identical to path A.
