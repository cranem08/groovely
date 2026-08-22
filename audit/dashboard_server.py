#!/usr/bin/env python3
"""
Offline dashboard server for the audit layer.

Serves the dashboard page and the worker's state.json over localhost only. Standard
library only; binds to 127.0.0.1 and makes no external calls. Reads (never writes) the
state and reports the worker produces.
"""

import argparse
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, unquote

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(HERE)


def load_config(path):
    with open(path, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    for key in ("state_path", "reports_dir"):
        p = cfg[key]
        cfg[key] = p if os.path.isabs(p) else os.path.join(REPO_ROOT, p)
    return cfg


def make_handler(cfg):
    state_path = cfg["state_path"]
    reports_dir = os.path.abspath(cfg["reports_dir"])
    dashboard_html = os.path.join(HERE, "dashboard.html")

    class Handler(BaseHTTPRequestHandler):
        def _send(self, code, body, ctype="text/plain; charset=utf-8"):
            if isinstance(body, str):
                body = body.encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            path = urlparse(self.path).path
            if path in ("/", "/index.html"):
                try:
                    with open(dashboard_html, "rb") as f:
                        self._send(200, f.read(), "text/html; charset=utf-8")
                except FileNotFoundError:
                    self._send(404, "dashboard.html not found")
                return

            if path == "/api/state":
                try:
                    with open(state_path, "rb") as f:
                        self._send(200, f.read(), "application/json; charset=utf-8")
                except FileNotFoundError:
                    self._send(200, json.dumps({
                        "updated_at": None, "agents_running": 0,
                        "sessions_total": 0, "planes": [], "sessions": [],
                        "note": "worker has not produced state yet",
                    }), "application/json; charset=utf-8")
                return

            if path.startswith("/reports/"):
                name = unquote(path[len("/reports/"):])
                target = os.path.abspath(os.path.join(reports_dir, name))
                # Path-traversal guard: must stay within reports_dir.
                if not target.startswith(reports_dir + os.sep):
                    self._send(403, "forbidden")
                    return
                if not os.path.isfile(target):
                    self._send(404, "report not found")
                    return
                ctype = "application/json; charset=utf-8" if target.endswith(".json") \
                    else "text/plain; charset=utf-8"
                with open(target, "rb") as f:
                    self._send(200, f.read(), ctype)
                return

            self._send(404, "not found")

        def log_message(self, *args):
            pass  # quiet

    return Handler


def main():
    ap = argparse.ArgumentParser(description="Offline audit dashboard server (localhost).")
    ap.add_argument("--config", default=os.path.join(HERE, "config.json"))
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=8787)
    args = ap.parse_args()

    cfg = load_config(args.config)
    httpd = ThreadingHTTPServer((args.host, args.port), make_handler(cfg))
    print(f"[dashboard] http://{args.host}:{args.port}  (offline, localhost only). Ctrl-C to stop.")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[dashboard] stopped.")


if __name__ == "__main__":
    main()
