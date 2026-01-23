---
source: .claude/rules/03-security.md
summary: Secret handling and env file hygiene.
---

# Security rules (Codex wrapper)

Read `.claude/rules/03-security.md` for full details.

Quick summary:
- Never hardcode secrets; use environment variables.
- Maintain `.env.template`.
- Ensure `.gitignore` excludes `.env` and other sensitive files.
