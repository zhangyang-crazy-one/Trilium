---
name: session-start
description: Manual session start checklist (Codex has no auto hooks).
source: .claude/hooks/session-init.sh
---

# session-start (Codex wrapper)

Codex does not support auto hooks. Manually follow `.claude/hooks/session-init.sh`.
Minimum steps:
1. Read `codex_commons/AGENTS.md` and project `AGENTS.md` if present.
2. Read `.claude/rules/*.md` (or `codex_commons/rules/*.md`).
3. List available skills and remind quick commands.
