# QUALITY.md — Definition of Done

> A feature is "done" when it meets ALL criteria below.
> No exceptions. No "I'll fix it later."

## Code Quality Checklist

- [ ] No `TODO`, `FIXME`, `HACK` comments left behind
- [ ] No `console.log` — use structured logger
- [ ] No `any` types in TypeScript (use proper typing)
- [ ] No hardcoded values (URLs, colors, API keys) — use config/env/constants
- [ ] No commented-out code blocks
- [ ] No unused imports or variables
- [ ] Error handling on every async operation
- [ ] Input validation on every user-facing endpoint

## Testing Checklist

- [ ] Unit tests for business logic
- [ ] Integration tests for API endpoints
- [ ] Edge cases covered (empty input, invalid data, network errors)
- [ ] Tests pass locally before committing

## UI Checklist (if applicable)

- [ ] Responsive on mobile, tablet, desktop
- [ ] Loading states for async operations
- [ ] Error states with clear user messaging
- [ ] Empty states (no data yet)
- [ ] No Lorem ipsum — use real content
- [ ] Accessibility: proper labels, contrast, keyboard navigation

## Deployment Checklist

- [ ] Environment variables documented
- [ ] Health check endpoint works
- [ ] Build succeeds in CI
- [ ] No secrets in code or logs
