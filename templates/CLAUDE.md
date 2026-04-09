# CLAUDE.md — Project Instructions

> This file is read by Claude Code at the start of every session.
> It defines rules, conventions, and context for AI-assisted development.

## Rules

1. **Read before coding** — Read this file and any referenced docs before making changes.
2. **Reuse existing code** — Check for existing utilities, helpers, and patterns before creating new ones.
3. **DRY / KISS / YAGNI** — No duplication, keep it simple, don't over-engineer.
4. **Fix code, not configs** — If a linter flags an issue, fix the source code. Never weaken linter/formatter configs.
5. **No console.log in production** — Use your project's structured logger.

## Stack

<!-- Update this section for your project -->
- Runtime: Node.js
- Language: TypeScript
- Testing: Vitest

## Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | This file — rules and context |
| `LL.md` | Lessons Learned — read before coding, update after incidents |
| `QUALITY.md` | Definition of "done" for code changes |

## Sub-Agent Instructions

When spawning sub-agents, always include in their prompt:
```
READ CLAUDE.md before starting work.
READ LL.md to avoid repeating past mistakes.
```

## Session Protocol

- At the end of each session, update LL.md with any new learnings.
- Document: new patterns discovered, gotchas encountered, decisions made.
