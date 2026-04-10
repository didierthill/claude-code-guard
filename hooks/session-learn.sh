#!/bin/bash
# ──────────────────────────────────────────────────────────
# claude-code-guard: session-learn
# Hook PreCompact — Extracts session learnings + RTK savings
#
# Fires before context compaction. Reminds the agent to:
# 1. Extract patterns (errors, decisions, feedback) from session
# 2. Write actionable learnings to LL.md
# 3. Include RTK token savings report (if rtk is installed)
#
# Non-blocking (exit 0 always).
# ──────────────────────────────────────────────────────────

set -euo pipefail

# ── RTK data collection (optional) ──────────────────────

RTK_SUMMARY=""
RTK_MISSED=""

if command -v rtk &>/dev/null; then
  # Weekly savings
  WEEKLY_JSON=$(rtk gain --weekly --format json 2>/dev/null || echo '{}')
  RTK_SUMMARY=$(echo "$WEEKLY_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    s = data.get('summary', {})
    total = s.get('total_saved', 0)
    pct = s.get('avg_savings_pct', 0)
    cmds = s.get('total_commands', 0)

    # Format token count
    if total >= 1_000_000:
        saved_str = f'{total/1_000_000:.1f}M'
    elif total >= 1_000:
        saved_str = f'{total/1_000:.1f}K'
    else:
        saved_str = str(total)

    print(f'{saved_str} tokens saved ({pct:.1f}%) across {cmds} commands')
except:
    print('')
" 2>/dev/null)

  # Missed optimization opportunities
  DISCOVER_JSON=$(rtk discover --all --format json 2>/dev/null || echo '{}')
  RTK_MISSED=$(echo "$DISCOVER_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    supported = data.get('supported', [])
    if not supported:
        print('')
        sys.exit(0)

    total_est = sum(c.get('estimated_savings_tokens', 0) for c in supported)
    cmds = ', '.join(c['command'] for c in supported[:5])

    if total_est >= 1_000:
        est_str = f'{total_est/1_000:.1f}K'
    else:
        est_str = str(total_est)

    print(f'{len(supported)} commands could use rtk ({est_str} est. savings): {cmds}')
except:
    print('')
" 2>/dev/null)
fi

# ── Output learning prompt ──────────────────────────────

echo "SESSION LEARNING — Extract before compacting:"
echo ""
echo "1. SCAN this session for:"
echo "   - Errors resolved (bugs, crashes, misconfigs)"
echo "   - Patterns that worked (approaches, tools, techniques)"
echo "   - Patterns that failed (and why)"
echo "   - Decisions made (architecture, libraries, trade-offs)"
echo "   - User corrections on your approach"
echo ""
echo "2. For each actionable pattern, WRITE to LL.md (if it exists):"
echo "   - Format: LL-XXX with Date/Symptom/Cause/Impact/Fix/Rule"
echo "   - Skip if pattern already documented"
echo "   - Skip ephemeral details (only session-specific)"
echo ""

if [ -n "$RTK_SUMMARY" ]; then
  echo "3. RTK TOKEN SAVINGS:"
  echo "   - Weekly: $RTK_SUMMARY"
  if [ -n "$RTK_MISSED" ]; then
    echo "   - Missed: $RTK_MISSED"
  fi
  echo ""
fi

echo "4. Output a summary of what was extracted and where it was written."

exit 0
