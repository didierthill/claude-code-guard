#!/bin/bash
# ──────────────────────────────────────────────────────────
# claude-code-guard: compact-suggester
# Hook PreToolUse:Edit|Write — Suggests /compact at strategic intervals
#
# Counts tool calls and suggests compaction at threshold, then every N calls.
# Non-blocking (exit 0 always).
# ──────────────────────────────────────────────────────────

# Read config or use defaults
CONFIG_FILE="$HOME/.claude-guard/config.json"
if [ -f "$CONFIG_FILE" ]; then
  THRESHOLD=$(python3 -c "
import json
try:
    c = json.load(open('$CONFIG_FILE'))
    print(c.get('hooks', {}).get('compact-suggester', {}).get('threshold', 50))
except:
    print(50)
" 2>/dev/null)
  INTERVAL=$(python3 -c "
import json
try:
    c = json.load(open('$CONFIG_FILE'))
    print(c.get('hooks', {}).get('compact-suggester', {}).get('interval', 25))
except:
    print(25)
" 2>/dev/null)
else
  THRESHOLD=50
  INTERVAL=25
fi

# Use PPID for stable counter across hook invocations
COUNTER_FILE="/tmp/claude-guard-tool-count-$PPID"

if [ -f "$COUNTER_FILE" ]; then
  COUNT=$(cat "$COUNTER_FILE" 2>/dev/null)
  COUNT=$((COUNT + 1))
else
  COUNT=1
fi

echo "$COUNT" > "$COUNTER_FILE"

if [ "$COUNT" -eq "$THRESHOLD" ]; then
  echo "[claude-code-guard] $THRESHOLD tool calls — consider running /compact if switching tasks." >&2
fi

if [ "$COUNT" -gt "$THRESHOLD" ]; then
  DELTA=$((COUNT - THRESHOLD))
  if [ $((DELTA % INTERVAL)) -eq 0 ]; then
    echo "[claude-code-guard] $COUNT tool calls — /compact recommended if context feels stale." >&2
  fi
fi

exit 0
