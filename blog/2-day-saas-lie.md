# I Ship Production SaaS With AI. The "2-Day Deploy" Crowd Is Building Sandcastles.

Every week, someone posts "I built a SaaS in 48 hours with Claude/Cursor/GPT." The screenshot looks clean. The demo works. The likes pile up.

I don't doubt them. They did build something in 48 hours. But what they built isn't a SaaS. It's a screenshot.

I know because I build production SaaS products with AI too. Real estate management, waste compliance, multi-tenant platforms serving paying customers under Belgian and EU regulations. I use Claude Code every day, extensively, with 46 reusable packages and nearly 2,000 tests across the monorepo.

AI didn't make my job easier. It made my job faster. Those are very different things.

---

## What you actually built in 2 days

Let's be specific about what a "2-day SaaS" looks like under the hood:

- CRUD routes that return `{ ok: true }` with no business logic
- Clerk or Supabase auth bolted on (one tenant, one user: you)
- shadcn/ui components with hardcoded data
- TypeScript with `any` sprinkled everywhere the types got hard
- `catch (e) {}` — silent error swallowing
- No tests. Zero.
- Deploy to Vercel with a git push

That's not a product. That's a prototype wearing a product's clothes.

```
What they show on Twitter:

+--------------+
|   Login      |  <- Clerk
|   Dashboard  |  <- Hardcoded data
|   Settings   |  <- Does nothing
+--------------+
     "SaaS"


What's actually behind it:

+--------------+
|   Login      |  <- Single tenant
|   Dashboard  |  <- No error states
|   Settings   |  <- No backend
|              |
|   (nothing)  |  <- No audit trail
|   (nothing)  |  <- No billing
|   (nothing)  |  <- No GDPR
|   (nothing)  |  <- No i18n
|   (nothing)  |  <- No tests
+--------------+
    "Project"
```

---

## What a production SaaS actually requires

I run multiple products on a shared monorepo. Here's what exists behind each one — the stuff that never makes it into a Twitter demo.

**Data layer.** Every model has strict types, tenant isolation (`tenantId` + `appId` indexed on every collection), composite indexes on hot queries, and validation schemas mirrored between Mongoose and Zod. No `Mixed` type without an Architecture Decision Record explaining why.

**Auth and authorization.** Not just "can this person log in" but role-based access control through a shared auth package, middleware that guards every route, and tenant scoping that makes it physically impossible to query another customer's data. A single missing `tenantId` filter is a data breach. Not a bug — a breach.

**Audit trail.** Every mutation gets logged through a shared audit package. Who changed what, when, with what payload. Regulators ask for this. "I'll add it later" means you won't have it when the auditor shows up.

**Error handling.** Every user action can fail five ways: network timeout, validation error, permission denied, server error, missing data. Each one gets a specific, user-readable response. `catch (e) {}` is a masked bug, not error handling.

**Feature flags.** Sometimes a feature is done on the backend but blocked by a regulatory approval or a business decision. The pattern is: backend complete, flag in config, UI shows disabled state with explanation. Not `if (false)` — that's dead code. Not "Coming Soon" — that's a lie.

**Billing, i18n, GDPR consent, legal compliance.** Each one is its own package. Each one has its own test suite. Each one talks to the others through defined interfaces.

```
Production SaaS — actual stack:

+---------+---------+---------+
|  Auth   |  RBAC   |  Audit  |
+---------+---------+---------+
|  i18n   | Billing |  GDPR   |
+---------+---------+---------+
| Feature |  Error  |  Seed   |
|  Flags  | Handling|  Data   |
+---------+---------+---------+
| Tenant  |  Legal  |  Tests  |
| Isolat. | Comply. | (1945+) |
+---------+---------+---------+

Packages: 46
Tests: 1945+
Deploy: Kaniko on k3s
Time to build: months, not days
```

Each of these boxes is a package I wrote once and reuse across every product. That's 46 packages today. The second product took half the time of the first. The third took a quarter. That compounding is what AI-assisted development should aim for — not one-off speed, but structural leverage.

---

## AI is the best tool I've ever used. It's also the best debt generator I've ever seen.

Here's the thing nobody says out loud: AI coding tools produce code at the speed of thought, but they produce *whatever code gets the immediate task done*. Without constraints, that means:

- Functions that return null and call it "done"
- Routes that exist but connect to nothing
- Components with no loading, error, or empty states
- `console.log` left everywhere
- Reinventing logic that already exists in your own codebase

I've watched AI agents — my own agents, running in my own codebase — stub out a function with `// TODO: implement` and report the task as complete. With a green checkmark.

The problem isn't the AI. The problem is that most people treat AI like a junior developer who needs no supervision. In reality, it's a junior developer who works at mass-production speed and has no concept of "done."

---

## What guardrails actually look like

I'm not going to pretend I have this figured out. I have it *less broken* than it was six months ago. Here's what helped.

**A definition of done that the AI reads before every task.** Not a wiki page nobody checks — a file at the root of the repository that defines what "finished" means per layer. Model: strict types, tenant isolation, indexes. Route: auth middleware, Zod validation in and out, audit log on mutations. Component: typed props, loading state, error state, empty state, no hardcoded colors. If the agent's output doesn't match the checklist, it's not done.

**Hooks that fire on every action.** Before an AI agent writes code, a hook checks: did you read the project rules? Did you check the secrets file instead of asking me for a token? Before it reports "done," another hook checks: is there a `console.log`? A `TODO`? An `any`?

**A guard on sub-agents.** When I spin up a sub-agent for a specific task, a hook inspects its instructions. If the prompt doesn't include "read the project rules" and "read the secrets file," the hook blocks the agent from launching. Hard stop. Not a suggestion — a gate.

```
Agent launch flow:

Developer prompt
      |
      v
+------------+    NO
| Mentions   |---------> BLOCKED
| rules +    |          (exit 2)
| secrets?   |
+-----+------+
      | YES
      v
+------------+
| Inject     |
| quality    |
| reminder   |
+-----+------+
      |
      v
  Agent runs
  (with context)
```

**A lessons-learned file that compounds.** Every time something breaks — a deploy failure, a stub that slipped through, a tenant isolation miss — it goes into a structured file with symptom, cause, fix, and rule. The AI reads this file before starting work. Mistake once, never again. In theory. In practice, maybe 80% of the time. But 80% beats zero.

**The right AI model for the right job.** Not everything needs the most expensive model. File searches and grep? Use the cheap model — 85% cost reduction, same result. Code generation? Mid-tier model. Architecture decisions and complex debugging? Top-tier model. Bulk translation? Don't even use Claude — route it to Gemini Flash through an API, it's faster and cheaper for that job.

---

## The metric that matters

"Time to first deploy" is vanity. The metric that matters is time to first paying customer who stays.

A customer stays when:

- The app handles their actual data without silent failures
- Their data doesn't leak to another tenant
- The error message says something useful, not `Error: undefined`
- The feature they need isn't a button that does nothing
- The invoice comes on time and the amounts are correct
- The audit trail exists when the regulator asks

None of these are visible in a demo. All of them are visible in churn.

I've shipped products where the first deploy took weeks, not days. But the first customer is still a customer a year later. That math works out better than a 2-day deploy followed by six months of apologizing for broken features.

---

## A confession and a frustration

I'm not a software engineer. My background is infrastructure — servers, networks, systems. I'm a founder who learned to build software because nobody else was going to do it at the budget I had.

AI didn't replace my engineering team. I never had one. It became one.

But here's what nobody warns you about when your engineering team is an AI: it's agreeable. Relentlessly, infuriatingly agreeable. It tells you your code is great when it's not. It says "done" when it shipped a stub. It apologizes and immediately does the exact same thing again.

I'm the kind of person who wants facts, not reassurance. Tell me the code is broken — don't tell me it's "a great start." Tell me the architecture has a flaw — don't tell me it's "solid overall." When I ask "is this done?" I mean "would a paying customer use this without calling support in the first hour?" Not "does the file exist?"

That frustration is why the guardrails exist. Every hook in [claude-code-guard](https://github.com/didierthill/024-OSS-forged-claude-code-guard) started as a moment where I caught the AI cutting a corner and thought: never again. The agent-guard exists because sub-agents kept asking me for credentials that were already documented. The quality templates exist because "done" kept meaning "the function exists but returns null." The session-reminder exists because the AI would forget the rules mid-conversation.

77 documented failures. 22 projects. That's not a framework born from theory. It's scar tissue turned into automation.

---

## The uncomfortable truth

AI didn't lower the bar for building software. It lowered the bar for *looking like* you built software.

The gap between "working demo" and "working product" has always existed. AI just made it possible to cross the demo line so fast that people mistake it for the finish line.

If you're building something real — something that handles money, personal data, regulatory requirements, multiple customers who don't know each other exist — the work is the same as it always was. It's tenant isolation, error handling, audit trails, compliance, tests. AI makes that work faster. It doesn't make it disappear.

I use AI every single day. My codebase would be half its size without it. My development speed is probably 3-4x what it was two years ago. But that speed only pays off because I spent months building the guardrails that keep the AI from producing garbage at scale.

The 2-day SaaS crowd will figure this out. Usually around month three, when their first real customer finds a bug that a test would have caught, in a feature that a checklist would have flagged, with data that tenant isolation would have protected.

By then the rewrite costs more than doing it right the first time.

---

Worth the effort? Every single day. AI with discipline is the most productive setup I've ever had.

AI without discipline is just fast typing.
