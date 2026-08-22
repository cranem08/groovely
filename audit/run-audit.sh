#!/usr/bin/env bash
# run-audit.sh — start the offline audit worker + dashboard together.
#
# Deterministic, offline, no LLM, localhost only. The worker tails Claude's native
# logs and writes state + reports; the dashboard serves a live view.
#
# Usage:
#   ./run-audit.sh                 # uses audit/config.json, dashboard on :8787
#   PORT=9000 ./run-audit.sh       # custom port
#   ./run-audit.sh /path/config.json

set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${1:-$HERE/config.json}"
PORT="${PORT:-8787}"

echo "[audit] config: $CONFIG"
python3 "$HERE/audit_worker.py" --config "$CONFIG" &
WORKER_PID=$!
trap 'kill "$WORKER_PID" 2>/dev/null || true' EXIT INT TERM

python3 "$HERE/dashboard_server.py" --config "$CONFIG" --port "$PORT"
