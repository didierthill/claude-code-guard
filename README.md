# claude-code-guard

**Governance hooks for Claude Code** — guardrails that prevent AI agents from making the same mistakes twice.

```bash
git clone https://github.com/didierthill/024-OSS-forged-claude-code-guard.git
cd 024-OSS-forged-claude-code-guard
npm install && npm run build
npm install -g . --prefix ~/.npm-global
claude-code-guard init
```

> Born from 77 documented agent failures across 22 projects over 6 months. Each hook exists because something went wrong without it.
>
> **Read:** [The "2-Day SaaS" Is a Demo. Here's What Production Actually Looks Like.](blog/2-day-saas-lie.md)

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
claude-code-guard init

# Check what's installed
claude-code-guard status

# Add or remove individual hooks
claude-code-guard add audit-log
claude-code-guard remove compact-suggester
```

## The 9 Hooks

### 1. Agent Guard — Preventing Amnesia

Sub-agents start with zero context. They don't know your stack, your conventions, or where anything is. This hook blocks sub-agents whose prompts don't reference your key documentation files.

**Before this hook:** 40% of sub-agent sessions wasted time reinventing existing code.
**After:** Zero.

When blocked, the agent sees:

```
claude-code-guard: Sub-agent prompt missing required references: CLAUDE.md
                                                                 
Add these to your sub-agent prompt:
  - READ CLAUDE.md before starting work

Configure required files: ~/.claude-guard/config.json → hooks.agent-guard.requiredFiles
```

When the prompt passes, the hook injects quality reminders into the sub-agent's context:

```
AGENT RULES (injected by guard):
1. Search project docs BEFORE asking questions.
2. ZERO stubs. No TODO, no fake data, no 'Not implemented'.
3. 'Done' = works end-to-end for a real user. UI without backend = NOT done.
4. Read QUALITY.md for the full definition of done.
```

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

Injects your custom context lines on every prompt. Compact single-line output to minimize token overhead. Configurable — use it for whatever your agent keeps forgetting.

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

Example output:

```
claude-code-guard: Potential missing tenant isolation in userService.ts

Database queries without 'tenantId' in nearby context:
  Line 42: const users = await User.find({ role: 'admin' })
  Line 67: await Order.deleteMany({ status: 'expired' })

Every query MUST filter by tenantId. Missing it = data leak across tenants.
```

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

Example output:

```
claude-code-guard: Potential PII exposure in apiController.ts

Found patterns that may expose personal data:
  PII in log: 47: logger.info('User logged in', { email: user.email })
  PII in response: 83: res.json({ user: { password: user.password, ...userData } })

PII must be redacted in logs, excluded from API responses, and never hardcoded.
```

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

## Works well with

- **[RTK](https://github.com/contextcraft/rtk)** — Rust CLI proxy, 60-90% input token savings on command output
- **[Caveman](https://github.com/JuliusBrussee/caveman)** — Claude Code plugin, ~75% output token compression

## Roadmap

Planned hooks and features — contributions welcome.

- [ ] **npm publish** — `npx claude-code-guard init` without cloning
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
