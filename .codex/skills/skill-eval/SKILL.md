---
name: skill-eval
description: Manual skill evaluation checklist.
source: .claude/hooks/skill-forced-eval.sh
---

# skill-eval (Codex wrapper)

Codex does not support auto hooks. Manually follow `.claude/hooks/skill-forced-eval.sh`:
- Evaluate the user prompt for skill triggers.
- If external libraries are mentioned and unfamiliar, query docs (Context7 -> deepwiki -> GitHub).
- Activate the relevant skills by name.
