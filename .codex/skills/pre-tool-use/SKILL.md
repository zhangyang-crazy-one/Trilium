---
name: pre-tool-use
description: Manual pre-tool checklist for safety, rules, and planning.
source: .claude/hooks/pre-tool-guard.sh
---

# pre-tool-use (Codex wrapper)

Codex does not support auto hooks. Manually follow `.claude/hooks/pre-tool-guard.sh`.
Minimum checklist before Write/Edit/Bash:
- Re-check code quality, style, security, and performance rules.
- Confirm planning files exist and align with changes.
- Avoid risky commands and sensitive file edits.
