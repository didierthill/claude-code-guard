#!/bin/bash
# ──────────────────────────────────────────────────────────
# claude-code-guard: session-reminder
# Hook UserPromptSubmit — Injects critical context every prompt
#
# Reads custom lines from ~/.claude-guard/config.json.
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
        print('CONTEXT REMINDER:')
        for line in lines:
            print(f'- {line}')
except:
    pass
" 2>/dev/null
else
  echo "CONTEXT REMINDER:"
  echo "- Read CLAUDE.md before making changes"
  echo "- Check existing code before creating new files"
fi

exit 0
