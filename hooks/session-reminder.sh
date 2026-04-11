#!/bin/bash
# ──────────────────────────────────────────────────────────
# claude-code-guard: session-reminder
# Hook UserPromptSubmit — Injects context reminder every prompt
#
# Reads custom lines from ~/.claude-guard/config.json.
# Compact single-line output to minimize token usage.
# Non-blocking (exit 0 always).
# ──────────────────────────────────────────────────────────

CONFIG_FILE="$HOME/.claude-guard/config.json"

if [ -f "$CONFIG_FILE" ]; then
  python3 -c "
import json
try:
    c = json.load(open('$CONFIG_FILE'))
    lines = c.get('hooks', {}).get('session-reminder', {}).get('lines', [])
    if lines:
        print('GUARD: ' + ' | '.join(lines))
except:
    pass
" 2>/dev/null
else
  echo "GUARD: Read CLAUDE.md before changes. Check existing code before creating new files."
fi

exit 0
