---
source: .claude/rules/00-global.md
summary: Global behavior rules (always apply).
---

# Global rules (Codex wrapper)

Read `.claude/rules/00-global.md` for full details.

Quick summary:
- Preserve context and do not stop early due to token budget.
- Default to action; discover missing details via tools.
- Parallelize independent tool calls when possible.
- Investigate before answering; read referenced files first.
