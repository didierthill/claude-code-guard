#!/bin/bash
# ──────────────────────────────────────────────────────────
# claude-code-guard: audit-log
# Hook PostToolUse:Bash — Logs every command with secret redaction
#
# Log file: ~/.claude/bash-audit.log
# Non-blocking (exit 0 always).
# ──────────────────────────────────────────────────────────

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json, re
try:
    data = json.load(sys.stdin)
    cmd = data.get('tool_input', {}).get('command', '?')
    # Redact secrets
    cmd = re.sub(r'--token[= ][^ ]*', '--token=<REDACTED>', cmd)
    cmd = re.sub(r'Authorization:[: ]*[^ ]*', 'Authorization:<REDACTED>', cmd, flags=re.I)
    cmd = re.sub(r'AKIA[A-Z0-9]{16}', '<REDACTED>', cmd)
    cmd = re.sub(r'password[= ][^ ]*', 'password=<REDACTED>', cmd, flags=re.I)
    cmd = re.sub(r'ghp_[A-Za-z0-9_]+', '<REDACTED>', cmd)
    cmd = re.sub(r'gho_[A-Za-z0-9_]+', '<REDACTED>', cmd)
    cmd = re.sub(r'sk-[a-zA-Z0-9]{20,}', '<REDACTED>', cmd)
    cmd = re.sub(r'mongodb\+srv://[^ ]*', 'mongodb+srv://<REDACTED>', cmd)
    cmd = re.sub(r'CF_[A-Za-z_]*=[^ ]*', 'CF_<KEY>=<REDACTED>', cmd)
    cmd = re.sub(r'Bearer [A-Za-z0-9\-._~+/]+=*', 'Bearer <REDACTED>', cmd)
    cmd = cmd.replace('\n', ' ')
    print(cmd)
except:
    print('?')
" 2>/dev/null)

[ "$COMMAND" = "?" ] && exit 0

LOG_FILE="$HOME/.claude/bash-audit.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] $COMMAND" >> "$LOG_FILE"

exit 0
