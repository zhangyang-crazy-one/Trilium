---
source: .claude/rules/01-code-quality.md
summary: Type safety, diagnostics, and export typing.
---

# Code quality rules (Codex wrapper)

Read `.claude/rules/01-code-quality.md` for full details.

Quick summary:
- Do not use `as any`, `@ts-ignore`, or `@ts-expect-error`.
- Run `lsp_diagnostics` after edits.
- All exports must have explicit type annotations.
