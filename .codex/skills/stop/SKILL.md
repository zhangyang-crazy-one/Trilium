---
name: stop
description: Manual session completion checklist.
source: .claude/hooks/session-complete.sh
---

# stop (Codex wrapper)

Codex does not support auto hooks. Manually follow `.claude/hooks/session-complete.sh`.
Minimum checklist:
- Verify documentation updates for any API/architecture/config changes.
- Update planning files (task_plan/progress/findings) if used.
- Run `lsp_diagnostics` if code changed.
- Clean temporary files.
