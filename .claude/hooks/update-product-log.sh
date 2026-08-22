#!/usr/bin/env bash
# Stop hook: append a session checkpoint entry to product-log.md.
# Runs after every agent turn. Always exits 0 — non-blocking.
#
# Agents write their own detailed log entries in their procedures.
# This hook is a safety net: it guarantees a minimum record exists
# even if an agent procedure does not complete normally.

set -uo pipefail

# Read JSON payload from stdin
INPUT=$(cat)

# Prevent infinite loop — do not run when stop_hook_active is true
STOP_HOOK_ACTIVE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print('true' if data.get('stop_hook_active', False) else 'false')
except Exception:
    print('false')
" 2>/dev/null || echo "false")

if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

# Agent name — prefer environment variable, fall back to 'agent'
AGENT="${CLAUDE_AGENT_NAME:-agent}"
DATE=$(date +"%Y-%m-%d %H:%M")

# Locate product-log.md ---------------------------------------------------
# Strategy 1: walk up from the current working directory
PRODUCT_LOG=""
DIR="$PWD"
while [ "$DIR" != "/" ]; do
    if [ -f "$DIR/product-log.md" ]; then
        PRODUCT_LOG="$DIR/product-log.md"
        break
    fi
    DIR=$(dirname "$DIR")
done

# Strategy 2: search under projects/ in the workflow root
if [ -z "$PRODUCT_LOG" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    WORKFLOW_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    FOUND=$(find "$WORKFLOW_ROOT/projects" -name "product-log.md" -maxdepth 3 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        PRODUCT_LOG="$FOUND"
    fi
fi

# No product-log.md found — skip silently
if [ -z "$PRODUCT_LOG" ]; then
    exit 0
fi

# Append checkpoint entry
echo "| $DATE | $AGENT | Session checkpoint (stop hook) |" >> "$PRODUCT_LOG"
exit 0
