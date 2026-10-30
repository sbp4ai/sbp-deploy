"""端到端验收：扮演一个客户端，问 server 要会话列表。

串起来的链路是：
    tmux 会话 -> sbp-supervise -> sbp-bridge(devices) -> sbp-server(/sbp WS) -> 本脚本

用法：
    python verify-stack.py                      # 用最新一个绑定码
    python verify-stack.py --code M98C-P2YA     # 指定绑定码
    python verify-stack.py --server ws://host   # 指定 server
"""
from __future__ import annotations

import argparse
import asyncio
import json
import os
import re
import sys
from pathlib import Path

import aiohttp

# 沙箱里常常塞了 *_PROXY，会把 127.0.0.1 的请求也发出去 —— 本机直连必须清掉
for _k in list(os.environ):
    if _k.lower().endswith("_proxy"):
        os.environ.pop(_k, None)

SUB_PROTO = "sbp.v0.1"
DEFAULT_SERVER = os.environ.get("SBP_SERVER", "http://127.0.0.1:8787")
LOG_DIR = Path(os.environ.get("SBP_HOME") or Path.home() / ".sbp") / "logs"


def latest_bind_code() -> str | None:
    """从 bridge 子进程的日志里抓一个还没过期的绑定码（10 分钟有效）。"""
    logs = sorted(LOG_DIR.glob("bridge-*.log"), key=lambda p: p.stat().st_mtime, reverse=True)
    for p in logs[:8]:
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        hits = re.findall(r"绑定码\s*:\s*([A-Z0-9]{4}-[A-Z0-9]{4})", text)
        if hits:
            return hits[-1]
    return None


async def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser("verify-stack", description="SBP 端到端验收")
    ap.add_argument("--server", default=DEFAULT_SERVER)
    ap.add_argument("--code", default=None, help="绑定码；不给就自动从 bridge 日志里抓")
    ap.add_argument("--attach", default=None, help="顺便 attach 某个 sid 并把屏幕打出来")
    ap.add_argument("--timeout", type=float, default=12.0)
    args = ap.parse_args(argv)

    base = args.server.rstrip("/")
    ws_base = base.replace("https://", "wss://").replace("http://", "ws://")

    health_url = f"{base}/api/health"
    async with aiohttp.ClientSession() as http:
        async with http.get(health_url) as r:
            health = await r.json()
        print(f"[1/4] health         : {json.dumps(health, ensure_ascii=False)}")

        code = args.code or latest_bind_code()
        if not code:
            print("!! 拿不到绑定码：先看 ~/.sbp/logs/bridge-*.log，或直接 --code XXXX-XXXX")
            return 2
        async with http.post(f"{base}/api/bind",
                             json={"code": code, "im_user": "verify-script", "channel": "cli"}) as r:
            tok = await r.json()
        if not tok.get("ok"):
            print(f"!! 绑定失败: {tok}（绑定码 10 分钟有效，可能已过期）")
            return 3
        print(f"[2/4] bind           : ok  device={tok.get('device_id')}")

        async with http.ws_connect(f"{ws_base}/sbp", protocols=(SUB_PROTO,), timeout=10) as ws:
            await ws.send_json({
                "v": "sbp/0.1", "id": "h1", "type": "req", "name": "hello", "ts": 0,
                "payload": {"role": "client", "token": tok.get("client_token")},
            })
            sessions: list[dict] = []
            attached: dict = {}
            deadline = asyncio.get_event_loop().time() + args.timeout
            hello_ok = False
            while asyncio.get_event_loop().time() < deadline:
                try:
                    msg = await asyncio.wait_for(ws.receive(), timeout=1.0)
                except asyncio.TimeoutError:
                    if sessions and (not args.attach or attached):
                        break
                    continue
                if msg.type is not aiohttp.WSMsgType.TEXT:
                    continue
                f = json.loads(msg.data)
                if f.get("type") == "res" and f.get("name") == "hello.ok":
                    hello_ok = True
                    print(f"[3/4] hello          : ok")
                    if args.attach:
                        await ws.send_json({"v": "sbp/0.1", "id": "a1", "type": "req",
                                            "name": "session.attach", "sid": args.attach,
                                            "ts": 0, "payload": {}})
                    continue
                if f.get("type") == "evt" and f.get("name") == "session.index":
                    sessions = (f.get("payload") or {}).get("sessions") or []
                    continue
                if args.attach and f.get("sid") == args.attach and f.get("type") == "evt":
                    if f.get("name") in ("output.delta", "session.state", "session.screen"):
                        attached[f["name"]] = f.get("payload") or {}

            if not hello_ok:
                print("!! hello 没回 ok")
                return 4
            print(f"[4/4] session.index  : {len(sessions)} session(s)")
            for s in sessions:
                sid = s.get("sid") or s.get("id") or "?"
                title = s.get("title") or s.get("name") or ""
                agent = s.get("agent") or ""
                state = s.get("state") or ""
                print(f"        - {sid:<26s} {agent:<12s} {state:<14s} {title}")

            if args.attach:
                screen = (attached.get("output.delta") or {}).get("text") or \
                         (attached.get("session.screen") or {}).get("text") or ""
                print(f"\n-- attach {args.attach} --")
                print(f"   frames: {sorted(attached)}")
                if screen:
                    tail = screen.rstrip().splitlines()[-12:]
                    print("   " + "\n   ".join(tail))
                else:
                    print("   (no screen frame)")

            return 0 if sessions else 5


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
