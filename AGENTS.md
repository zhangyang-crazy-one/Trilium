# Codex Project Configuration (commons)

This folder mirrors the project-level configuration used for Claude Code and OpenCode, adapted to Codex CLI.
Codex does not support automatic hooks or slash commands, so commands, agents, and hooks are provided as skills.

## Installation
Option A (recommended): copy these items into the project root:
- `codex_commons/AGENTS.md` -> `AGENTS.md`
- `codex_commons/.codex` -> `.codex`
- `codex_commons/rules` -> `rules` (or keep `codex_commons/rules` and adjust paths below)

Option B: keep `codex_commons/` in the repo and refer to it explicitly in prompts.

## How to invoke
- Skills: `$skill-name`
- Commands (as skills): `$bootstrap`, `$start`, `$progress`, `$next`, `$update-status`, `$feature-start`, `$commit`
- Agents (as skills): `$code-reviewer`, `$feature-developer`, `$project-manager`, `$plan`
- Hooks (manual skills): `$session-start`, `$skill-eval`, `$pre-tool-use`, `$stop`

## Manual hook flow (Codex has no auto hooks)
1. Run `$session-start` at the beginning of the session.
2. If the right skill is unclear, run `$skill-eval` after a prompt.
3. Before any Write/Edit/Bash or file changes, run `$pre-tool-use`.
4. Before finishing, run `$stop`.

## Rules
Read these rules at session start and re-check before edits:
- `rules/00-global.md`
- `rules/01-code-quality.md`
- `rules/02-code-style.md`
- `rules/03-security.md`
- `rules/04-performance.md`
- `rules/05-documentation.md`
- `rules/06-context7-query.md`
- `rules/07-refactoring.md`
- `rules/architecture-rules.md`
- `rules/ui-ux-rules.md`

Each wrapper points to the authoritative source in `.claude/rules/`.

## Core skills available
- `$planning-with-files`
- `$spec-interview`
- `$bug-debug`
- `$context7`
- `$ui-ux-pro-max`
- `$rag-vectordb`
- `$ai-integration`
- `$mcp-tools`
- `$platform-build`
- `$tauri-main`
- `$tauri-react`

## Agent skills available
- `$code-reviewer`
- `$feature-developer`
- `$project-manager`
- `$bug-fixer`
- `$frontend-dev`
- `$backend-dev`
- `$enhanced-plan`
- `$plan`

## Project skills available
- `$trilium-general`
- `$trilium-frontend`
- `$trilium-backend`
- `$trilium-ckeditor`
- `$trilium-sync`
- `$trilium-database`
- `$trilium-electron`

## Project context (TriliumNext)
- Monorepo managed by pnpm workspaces (`pnpm-workspace.yaml`) with apps in `apps/*` and shared libs in `packages/*`.
- Main apps: `apps/client` (Preact + jQuery/Knockout), `apps/server` (Express 5 + SQLite), `apps/desktop` (Electron), `apps/web-clipper` (browser extension).
- Developer guide: `docs/Developer Guide/Developer Guide.md` and project structure at `docs/Developer Guide/Developer Guide/Project Structure.md`.
- Common commands: `pnpm server:start`, `pnpm desktop:start`, `pnpm client:build`, `pnpm test:all`, `pnpm typecheck`.

## Agent definitions (project)
- Source agents live in `.claude/agents/` (`.claude/agents/code-reviewer.md`, `.claude/agents/feature-developer.md`, `.claude/agents/project-manager.md`).
- Codex wrappers live in `.codex/skills/*` and point to these sources.

## Entry points (quick index)
- Client entry: `apps/client/src/index.ts` (HTML: `apps/client/src/index.html`)
- Server entry: `apps/server/src/main.ts` (app setup: `apps/server/src/app.ts`)
- Desktop entry: `apps/desktop/src/main.ts`
- Web clipper: `apps/web-clipper/background.js` and `apps/web-clipper/content.js`
- Shared core: `packages/commons`
