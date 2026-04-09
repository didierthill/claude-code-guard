#!/bin/bash
# ──────────────────────────────────────────────────────────
# claude-code-guard: agent-guard
# Hook PreToolUse:Agent — Blocks sub-agents missing context
#
# Reads required files from ~/.claude-guard/config.json.
# If the sub-agent prompt doesn't reference them → exit 2 (block).
# ──────────────────────────────────────────────────────────

INPUT=$(cat)

# Extract the prompt from the Agent tool input
PROMPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('prompt', ''))
except:
    print('')
" 2>/dev/null)

# Read required files from config (default: CLAUDE.md)
CONFIG_FILE="$HOME/.claude-guard/config.json"
if [ -f "$CONFIG_FILE" ]; then
  REQUIRED_FILES=$(python3 -c "
import json
try:
    c = json.load(open('$CONFIG_FILE'))
    files = c.get('hooks', {}).get('agent-guard', {}).get('requiredFiles', ['CLAUDE.md'])
    print(' '.join(files))
except:
    print('CLAUDE.md')
" 2>/dev/null)
else
  REQUIRED_FILES="CLAUDE.md"
fi

# Check each required file is mentioned in the prompt
MISSING=""
for FILE in $REQUIRED_FILES; do
  COUNT=$(echo "$PROMPT" | grep -ci "$FILE")
  if [ "$COUNT" -eq 0 ]; then
    MISSING="$MISSING $FILE"
  fi
done

if [ -n "$MISSING" ]; then
  echo "claude-code-guard: Sub-agent prompt missing required references:$MISSING"
  echo ""
  echo "Add these to your sub-agent prompt:"
  for FILE in $MISSING; do
    echo "  - READ $FILE before starting work"
  done
  echo ""
  echo "Configure required files: ~/.claude-guard/config.json → hooks.agent-guard.requiredFiles"
  exit 2
fi

exit 0
