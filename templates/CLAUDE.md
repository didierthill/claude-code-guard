# CLAUDE.md — Project Instructions

> This file is read by Claude Code at the start of every session.
> It defines rules, conventions, and context for AI-assisted development.

## Do NOT ask — search first

Before asking the developer ANY question, check these files:

| Question about | Answer in |
|----------------|-----------|
| Project rules, conventions | This file |
| Past mistakes, gotchas | `LL.md` |
| What "done" means | `QUALITY.md` |
| Stack, dependencies | `package.json`, this file |

**If the answer is in these files and you ask anyway — that's a failure.**
**Only legitimate question: info that exists in NONE of the project files.**

## Definition of done — zero stubs

A deliverable is REJECTED if:
- A function returns `null`, `TODO`, `Not implemented`, or hardcoded data
- A UI button triggers no backend action
- An API route returns `{ ok: true }` with no logic
- `any`, `@ts-ignore`, `console.log` are present
- Happy path works but error/loading/empty states are missing
- Backend exists without UI, or UI exists without backend

**Full checklist in `QUALITY.md` — read it.**

## Rules

1. **Read before coding** — Read this file and any referenced docs before making changes.
2. **Reuse existing code** — Check for existing utilities, helpers, and patterns before creating new ones.
3. **DRY / KISS / YAGNI** — No duplication, keep it simple, don't over-engineer.
4. **Fix code, not configs** — If a linter flags an issue, fix the source code. Never weaken linter/formatter configs.
5. **No console.log** — Use your project's structured logger.
6. **Don't ask** — Search project files before asking. Questions are a last resort.

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
READ QUALITY.md for the definition of done. ZERO stubs.
```

## Session Protocol

- At the end of each session, update LL.md with any new learnings.
- Document: new patterns discovered, gotchas encountered, decisions made.
