# claude-code-guard

**Governance hooks for Claude Code** — guardrails that prevent AI agents from making the same mistakes twice.

```bash
npx claude-code-guard init
```

> Born from 77 documented agent failures across 22 projects over 6 months. Each hook exists because something went wrong without it.
>
> **Read:** [I Ship Production SaaS With AI. The "2-Day Deploy" Crowd Is Building Sandcastles.](blog/2-day-saas-lie.md)

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
> # zsh
> echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
> # bash
> echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
> # fish
> fish_add_path ~/.npm-global/bin
> ```

---

## What It Does

Installs 9 shell hooks into your Claude Code configuration that automatically enforce rules at the tool level — before or after the agent acts.

| Hook | Type | What it does |
|------|------|-------------|
| **agent-guard** | 🔴 Blocking | Blocks sub-agents that don't reference your project docs |
| **config-protection** | 🔴 Blocking | Prevents agents from weakening linter/formatter configs |
| **tenant-isolation** | 🟡 Advisory* | Detects database queries missing tenant scoping |
| **pii-guard** | 🟡 Advisory* | Detects PII exposure in logs, responses, and hardcoded data |
| **audit-log** | 🟢 Advisory | Logs every bash command with automatic secret redaction |
| **time-tracker** | 🟢 Advisory | JSONL time tracking per project and session |
| **compact-suggester** | 🟢 Advisory | Suggests `/compact` at strategic intervals |
| **session-reminder** | 🟢 Advisory | Injects context reminders on every prompt |
| **session-learn** | 🟢 Advisory | Extracts session learnings + RTK savings before compaction |

*🟡 = Advisory by default, can be set to blocking via config (`"blocking": true`). Disabled by default — enable with `claude-code-guard add tenant-isolation` or `claude-code-guard add pii-guard`.*

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

## Why These 7 Hooks?

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

### 7. Session Learn — Institutional Memory

Fires before context compaction (`PreCompact`). Prompts the agent to extract actionable learnings from the current session before they're lost:

- **Errors resolved** — bugs, crashes, misconfigurations that were fixed
- **Patterns discovered** — approaches that worked (or didn't) and why
- **Decisions made** — architecture choices, library selections, trade-offs
- **User corrections** — feedback on the agent's approach

Learnings are written to `LL.md` in structured format (Date, Symptom, Cause, Impact, Fix, Rule).

**RTK integration** (optional): If [RTK](https://github.com/contextcraft/rtk) is installed, the hook also reports weekly token savings, top commands by impact, and missed optimization opportunities.

### 8. Tenant Isolation — Data Boundary Enforcement

Scans every file you edit for database queries (`.find()`, `.updateMany()`, `.aggregate()`, etc.) and checks if `tenantId` appears within ±5 lines. If not — warning.

**Why this matters:** In multi-tenant SaaS, a single missing tenant filter is a data breach. Not a bug — a breach. This hook catches it at write time, not in code review.

```json
{
  "tenant-isolation": {
    "enabled": true,
    "tenantField": "tenantId",
    "blocking": false
  }
}
```

Set `blocking: true` if you want hard enforcement. Customize `tenantField` to match your schema (`organizationId`, `companyId`, etc.).

### 9. PII Guard — Personal Data Protection

Detects four categories of PII exposure:

1. **PII in logs** — `console.log(user.email)`, `logger.info(req.body.password)`
2. **Hardcoded PII** — real email addresses, IBAN numbers in source code (skips test files)
3. **PII in URLs** — `?email=john@example.com` in query parameters
4. **PII in responses** — `res.json({ password, hash, ssn })` returned to clients

```json
{
  "pii-guard": {
    "enabled": true,
    "blocking": false
  }
}
```

Advisory by default — warns but doesn't block. Set `blocking: true` for GDPR-critical projects.

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

## Companion Tools

These tools pair well with claude-code-guard for a complete agent governance + efficiency setup:

### RTK — Token-Optimized CLI Proxy

[RTK](https://github.com/contextcraft/rtk) is a Rust-based CLI proxy that filters verbose command output before it hits the context window. Transparent hook integration — `git status` becomes `rtk git status` automatically.

- **60-90% input token savings** on CLI output (measured 91.5% across 150+ commands)
- Automatic secret redaction (complements audit-log hook)
- Zero config — install and forget

```bash
cargo install rtk
```

### Caveman — Output Compression

[Caveman](https://github.com/JuliusBrussee/caveman) is a Claude Code plugin that makes the agent respond in compressed, caveman-style language — same technical accuracy, ~75% fewer output tokens.

```bash
# Install as Claude Code plugin
claude install caveman
```

Includes bonus skills: `caveman-commit` (terse commits), `caveman-review` (one-line code reviews), `caveman-compress` (~45% input savings on CLAUDE.md files).

### Cost Optimization — Advisor Strategy

When spawning sub-agents, use model tiering to cut costs without losing quality:

```
model: "haiku"   → file searches, grep, simple reads (85% cheaper)
model: "sonnet"  → code changes, moderate complexity (default)
model: "opus"    → architecture decisions, complex debugging (when needed)
```

This pairs with the **agent-guard** hook — sub-agents are both context-aware (guard) and cost-efficient (tiering).

## Roadmap

Planned hooks and features — contributions welcome.

- [ ] **dependency-check** — Block imports of deprecated or vulnerable packages
- [ ] **test-coverage-gate** — Warn when modified files lack corresponding test files
- [ ] **commit-message-lint** — Enforce conventional commits format
- [ ] **dead-code-detector** — Flag unused exports and unreachable functions
- [ ] **migration-guard** — Block schema changes without a corresponding migration file
- [ ] **cost-tracker** — Estimate token cost per session based on model and tool usage

Have an idea? [Open an issue](https://github.com/didierthill/024-OSS-forged-claude-code-guard/issues).

## Requirements

- Claude Code (with hooks support)
- Node.js >= 18
- bash, python3, jq (standard on macOS/Linux)

## License

MIT

---

*This code has been AI-assisted using [Claude Code](https://claude.ai/claude-code).*
