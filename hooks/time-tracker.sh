#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# claude-code-guard: time-tracker
# Hook UserPromptSubmit — JSONL time tracking per project/session
#
# Log file: ~/.claude/time-tracking.jsonl
# Non-blocking (exit 0 always).
# ──────────────────────────────────────────────────────────

set -euo pipefail
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"

LOG_FILE="${HOME}/.claude/time-tracking.jsonl"
INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"' 2>/dev/null)

# Detect project from cwd — customize this regex for your project structure
PROJECT="default"
if [ -f "$CWD/package.json" ]; then
  PROJECT=$(python3 -c "
import json, sys
try:
    p = json.load(open(sys.argv[1] + '/package.json'))
    print(p.get('name', 'unknown'))
except:
    print('unknown')
" "$CWD" 2>/dev/null)
fi
# Fallback: use directory name
if [ "$PROJECT" = "default" ] || [ "$PROJECT" = "unknown" ]; then
  PROJECT=$(basename "$CWD")
fi

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n -c \
  --arg ts "$TS" \
  --arg project "$PROJECT" \
  --arg session "$SESSION_ID" \
  --arg cwd "$CWD" \
  '{ts: $ts, project: $project, session: $session, cwd: $cwd}' >> "$LOG_FILE"

exit 0
