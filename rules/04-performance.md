---
source: .claude/rules/04-performance.md
summary: Performance checks for data access and UI.
---

# Performance rules (Codex wrapper)

Read `.claude/rules/04-performance.md` for full details.

Quick summary:
- Avoid N+1 queries.
- Virtualize lists with 100+ items.
- Clean up side effects in `useEffect`.
