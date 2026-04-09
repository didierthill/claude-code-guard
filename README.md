# claude-code-guard

**Governance hooks for Claude Code** — guardrails that prevent AI agents from making the same mistakes twice.

```bash
npx claude-code-guard init
```

> Born from 77 documented agent failures across 22 projects over 6 months. Each hook exists because something went wrong without it.

---

## Install

```bash
git clone https://github.com/didierthill/claude-code-guard
cd claude-code-guard
npm install
npm run build
npm install -g . --prefix ~/.npm-global
claude-code-guard init
```

> First time? Add the global bin to your PATH:
> ```bash
> echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
> ```

---

## What It Does

Installs 6 shell hooks into your Claude Code configuration that automatically enforce rules at the tool level — before or after the agent acts.

| Hook | Type | What it does |
|------|------|-------------|
| **agent-guard** | 🔴 Blocking | Blocks sub-agents that don't reference your project docs |
| **config-protection** | 🔴 Blocking | Prevents agents from weakening linter/formatter configs |
| **audit-log** | 🟢 Advisory | Logs every bash command with automatic secret redaction |
| **time-tracker** | 🟢 Advisory | JSONL time tracking per project and session |
| **compact-suggester** | 🟢 Advisory | Suggests `/compact` at strategic intervals |
| **session-reminder** | 🟢 Advisory | Injects context reminders on every prompt |

## Quick Start

```bash
# Interactive setup
npx claude-code-guard init

# Check what's installed
claude-code-guard status

# Add or remove individual hooks
claude-code-guard add audit-log
claude-code-guard remove compact-suggester
```

## Why These 6 Hooks?

### 1. Agent Guard — Preventing Amnesia

Sub-agents start with zero context. They don't know your stack, your conventions, or where anything is. This hook blocks sub-agents whose prompts don't reference your key documentation files.

**Before this hook:** 40% of sub-agent sessions wasted time reinventing existing code.
**After:** Zero.

### 2. Config Protection — No Shortcuts

When an agent hits a linter error, its instinct is to relax the rule — disable ESLint rules, add `@ts-ignore`, lower TypeScript strictness. This hook blocks all modifications to config files.

**Protects by default:** ESLint, Prettier, Biome, TypeScript, Vitest, Jest, Tailwind, Dockerfiles. Fully configurable.

### 3. Audit Log — Accountability

Every bash command the agent runs is logged to `~/.claude/bash-audit.log` with automatic redaction of:
- API keys (`sk-*`, `ghp_*`, `gho_*`, AWS access keys)
- Auth headers, passwords, Bearer tokens
- MongoDB connection strings
- Cloudflare tokens

### 4. Time Tracker — Cost Visibility

Logs every interaction to `~/.claude/time-tracking.jsonl` with project name, session ID, and timestamp. Answers the question: "How much agent time am I spending on which project?"

### 5. Compact Suggester — Context Management

Claude Code has a finite context window. This hook counts tool calls and suggests manual `/compact` at 50 calls (configurable), then every 25. Better than auto-compaction which cuts mid-thought.

### 6. Session Reminder — Fighting Drift

Injects your custom context lines on every prompt. Configurable — use it for whatever your agent keeps forgetting.

## Configuration

All hooks are configured via `~/.claude-guard/config.json`:

```json
{
  "hooks": {
    "agent-guard": {
      "enabled": true,
      "requiredFiles": ["CLAUDE.md"]
    },
    "config-protection": {
      "enabled": true,
      "protectedFiles": ["eslint*", "prettier*", "tsconfig*", "Dockerfile*"]
    },
    "compact-suggester": {
      "threshold": 50,
      "interval": 25
    },
    "session-reminder": {
      "lines": [
        "Read CLAUDE.md before making changes",
        "Check existing code before creating new files"
      ]
    }
  }
}
```

## Governance Templates

During `init`, you can optionally generate three governance documents:

- **CLAUDE.md** — Project rules and conventions for Claude Code
- **LL.md** — Lessons Learned log (structured incident documentation)
- **QUALITY.md** — Definition of "done" checklist

These are templates to customize, not rigid frameworks.

## How Hooks Work

Claude Code supports lifecycle hooks — shell scripts that fire before or after specific tool calls. The exit code determines behavior:

- `exit 0` — Pass (allow the action)
- `exit 2` — Block (reject the action with an error message)

Hooks are registered in `~/.claude/settings.json` (global) or `.claude/settings.json` (project-level). `claude-code-guard` manages this automatically.

## Requirements

- Claude Code (with hooks support)
- Node.js >= 18
- bash, python3, jq (standard on macOS/Linux)

## License

MIT
