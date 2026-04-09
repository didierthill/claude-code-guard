#!/bin/bash
# ──────────────────────────────────────────────────────────
# claude-code-guard: config-protection
# Hook PreToolUse:Edit|Write — Blocks modifications to config files
#
# Prevents agents from weakening linters/formatters/build configs.
# Protected files are configurable via ~/.claude-guard/config.json.
# ──────────────────────────────────────────────────────────

INPUT=$(cat)

# Extract file_path from tool input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

BASENAME=$(basename "$FILE_PATH")

# Read protected patterns from config
CONFIG_FILE="$HOME/.claude-guard/config.json"
if [ -f "$CONFIG_FILE" ]; then
  PROTECTED=$(python3 -c "
import json, fnmatch, sys
try:
    c = json.load(open('$CONFIG_FILE'))
    patterns = c.get('hooks', {}).get('config-protection', {}).get('protectedFiles', [])
    basename = sys.argv[1]
    for p in patterns:
        if fnmatch.fnmatch(basename, p):
            print('MATCH')
            sys.exit(0)
    print('OK')
except:
    print('OK')
" "$BASENAME" 2>/dev/null)
else
  # Default protected files (no config yet)
  case "$BASENAME" in
    .eslintrc|.eslintrc.*|eslint.config.*|\
    .prettierrc|.prettierrc.*|prettier.config.*|\
    biome.json|biome.jsonc|\
    tsconfig.json|tsconfig.*.json|\
    vitest.config.*|jest.config.*|\
    tailwind.config.*|\
    Dockerfile|Dockerfile.*)
      PROTECTED="MATCH"
      ;;
    *)
      PROTECTED="OK"
      ;;
  esac
fi

if [ "$PROTECTED" = "MATCH" ]; then
  echo "claude-code-guard: Modifying $BASENAME is blocked." >&2
  echo "Fix the source code to satisfy the linter/formatter, not the config." >&2
  echo "Configure protected files: ~/.claude-guard/config.json → hooks.config-protection.protectedFiles" >&2
  exit 2
fi

exit 0
