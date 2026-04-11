#!/bin/bash
# ──────────────────────────────────────────────────────────
# claude-code-guard: tenant-isolation
# Hook PostToolUse:Edit|Write — Checks for missing tenant scoping
#
# Scans modified files for database queries that lack tenant
# isolation (e.g., find/update/delete without tenantId filter).
# Advisory by default — set blocking: true in config to enforce.
#
# Non-blocking (exit 0) unless configured as blocking (exit 2).
# ──────────────────────────────────────────────────────────

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

# Only check relevant file types
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.py|*.rb|*.go)
    ;;
  *)
    exit 0
    ;;
esac

[ ! -f "$FILE_PATH" ] && exit 0

# Read config
CONFIG_FILE="$HOME/.claude-guard/config.json"
BLOCKING="false"
TENANT_FIELD="tenantId"

if [ -f "$CONFIG_FILE" ]; then
  eval $(python3 -c "
import json
try:
    c = json.load(open('$CONFIG_FILE'))
    ti = c.get('hooks', {}).get('tenant-isolation', {})
    print(f'BLOCKING={str(ti.get(\"blocking\", False)).lower()}')
    print(f'TENANT_FIELD={ti.get(\"tenantField\", \"tenantId\")}')
except:
    print('BLOCKING=false')
    print('TENANT_FIELD=tenantId')
" 2>/dev/null)
fi

# Patterns that indicate a database query
QUERY_PATTERNS='\.find\(|\.findOne\(|\.findMany\(|\.updateOne\(|\.updateMany\(|\.deleteOne\(|\.deleteMany\(|\.aggregate\(|\.countDocuments\(|\.findOneAndUpdate\(|\.findOneAndDelete\(|\.remove\(|\.where\(|\.query\('

# Check if file contains DB queries
QUERIES=$(grep -nE "$QUERY_PATTERNS" "$FILE_PATH" 2>/dev/null)
[ -z "$QUERIES" ] && exit 0

# Check if those query lines (or nearby context) include tenant scoping
VIOLATIONS=""
while IFS= read -r line; do
  LINE_NUM=$(echo "$line" | cut -d: -f1)

  # Check a window of ±5 lines around the query for tenantId
  START=$((LINE_NUM - 5))
  [ "$START" -lt 1 ] && START=1
  END=$((LINE_NUM + 5))

  CONTEXT=$(sed -n "${START},${END}p" "$FILE_PATH" 2>/dev/null)

  if ! echo "$CONTEXT" | grep -qi "$TENANT_FIELD"; then
    VIOLATIONS="$VIOLATIONS\n  Line $LINE_NUM: $(echo "$line" | cut -d: -f2- | sed 's/^[[:space:]]*//')"
  fi
done <<< "$QUERIES"

if [ -n "$VIOLATIONS" ]; then
  FILENAME=$(basename "$FILE_PATH")
  echo "claude-code-guard: Potential missing tenant isolation in $FILENAME"
  echo ""
  echo "Database queries without '$TENANT_FIELD' in nearby context:"
  echo -e "$VIOLATIONS"
  echo ""
  echo "Every query MUST filter by $TENANT_FIELD. Missing it = data leak across tenants."
  echo "Configure: ~/.claude-guard/config.json → hooks.tenant-isolation.tenantField"

  if [ "$BLOCKING" = "true" ]; then
    exit 2
  fi
fi

exit 0
