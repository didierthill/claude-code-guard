#!/bin/bash
# ──────────────────────────────────────────────────────────
# claude-code-guard: pii-guard
# Hook PostToolUse:Edit|Write — Detects PII exposure in code
#
# Scans modified files for patterns that suggest PII is being
# logged, hardcoded, or exposed without protection.
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
  *.ts|*.tsx|*.js|*.jsx|*.py|*.rb|*.go|*.java)
    ;;
  *)
    exit 0
    ;;
esac

[ ! -f "$FILE_PATH" ] && exit 0

# Read config
CONFIG_FILE="$HOME/.claude-guard/config.json"
BLOCKING="false"

if [ -f "$CONFIG_FILE" ]; then
  BLOCKING=$(python3 -c "
import json
try:
    c = json.load(open('$CONFIG_FILE'))
    print(str(c.get('hooks', {}).get('pii-guard', {}).get('blocking', False)).lower())
except:
    print('false')
" 2>/dev/null)
fi

VIOLATIONS=""

# Pattern 1: Logging PII fields directly
# console.log/logger with user.email, user.password, req.body.ssn, etc.
PII_LOG=$(grep -nE '(console\.(log|info|warn|debug|error)|logger\.(info|warn|error|debug)|log\.(info|warn|error|debug))\(.*\b(email|password|passwd|ssn|social.?security|national.?id|phone|mobile|birth.?date|date.?of.?birth|iban|credit.?card|card.?number|passport|driver.?license|health.?record|medical|diagnosis)\b' "$FILE_PATH" 2>/dev/null)

if [ -n "$PII_LOG" ]; then
  while IFS= read -r line; do
    VIOLATIONS="$VIOLATIONS\n  PII in log: $line"
  done <<< "$PII_LOG"
fi

# Pattern 2: Hardcoded PII patterns (emails, phones, SSNs, IBANs)
# Skip test files and fixtures
case "$FILE_PATH" in
  *.test.*|*.spec.*|*__tests__*|*fixture*|*mock*|*seed*)
    ;;
  *)
    # Real email addresses (not example.com/test.com)
    HARDCODED_EMAIL=$(grep -nE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|be|eu|fr|de|nl|org|net|io)' "$FILE_PATH" 2>/dev/null | grep -vE '(@example\.|@test\.|@localhost|@placeholder|noreply@|no-reply@|info@your|TODO)')

    if [ -n "$HARDCODED_EMAIL" ]; then
      while IFS= read -r line; do
        VIOLATIONS="$VIOLATIONS\n  Hardcoded email: $line"
      done <<< "$HARDCODED_EMAIL"
    fi

    # IBAN patterns
    HARDCODED_IBAN=$(grep -nE '\b[A-Z]{2}[0-9]{2}[A-Z0-9]{4}[0-9]{7}([A-Z0-9]?){0,16}\b' "$FILE_PATH" 2>/dev/null | grep -vE '(example|test|mock|placeholder|XXXX)')

    if [ -n "$HARDCODED_IBAN" ]; then
      while IFS= read -r line; do
        VIOLATIONS="$VIOLATIONS\n  Hardcoded IBAN: $line"
      done <<< "$HARDCODED_IBAN"
    fi
    ;;
esac

# Pattern 3: PII in URL parameters or query strings
PII_URL=$(grep -nE "(email|password|ssn|phone|iban|passport)=[^&\s]+" "$FILE_PATH" 2>/dev/null | grep -vE '(example|test|mock|placeholder)')

if [ -n "$PII_URL" ]; then
  while IFS= read -r line; do
    VIOLATIONS="$VIOLATIONS\n  PII in URL param: $line"
  done <<< "$PII_URL"
fi

# Pattern 4: Returning PII in API responses without filtering
PII_RESPONSE=$(grep -nE '(res\.(json|send)|return|response)\s*\(.*\b(password|passwd|hash|salt|ssn|secret|token)\b' "$FILE_PATH" 2>/dev/null)

if [ -n "$PII_RESPONSE" ]; then
  while IFS= read -r line; do
    VIOLATIONS="$VIOLATIONS\n  PII in response: $line"
  done <<< "$PII_RESPONSE"
fi

if [ -n "$VIOLATIONS" ]; then
  FILENAME=$(basename "$FILE_PATH")
  echo "claude-code-guard: Potential PII exposure in $FILENAME"
  echo ""
  echo "Found patterns that may expose personal data:"
  echo -e "$VIOLATIONS"
  echo ""
  echo "PII must be redacted in logs, excluded from API responses, and never hardcoded."
  echo "Configure: ~/.claude-guard/config.json → hooks.pii-guard.blocking"

  if [ "$BLOCKING" = "true" ]; then
    exit 2
  fi
fi

exit 0
