# Trilium Development Skill

> Skill for developing Trilium Notes - a hierarchical note-taking application built as a TypeScript monorepo.

## Skill Overview

This skill provides general Trilium project guidance: repository layout, core caches, widget/component patterns, and the backend/frontend boundary.

**Trilium Architecture Summary**:
- **Monorepo**: pnpm workspaces with apps in `apps/*` and shared libs in `packages/*`.
- **Desktop**: Electron entry in `apps/desktop/src/main.ts`, which starts the server and uses server services for windows/tray.
- **Cache System**: Becca (server) -> Froca (client) -> Shaca (share).
- **UI**: Hybrid widget/component system (jQuery widgets with Preact/React wrappers).
- **Database**: SQLite via `apps/server/src/services/sql.ts`.

## Specialized Skills (Use These for Specific Tasks)

| Task | Skill | Trigger Phrases |
|------|-------|-----------------|
| Backend development | **trilium-backend** | backend, server, Becca, ETAPI, API, services, SQLite |
| Frontend/UI development | **trilium-frontend** | frontend, client, widget, jQuery, Preact, Froca, UI |
| CKEditor5 editor | **trilium-ckeditor** | CKEditor, editor, rich text, WYSIWYG, plugins |
| Sync system | **trilium-sync** | sync, synchronization, WebSocket, EntityChange |
| Database operations | **trilium-database** | database, SQLite, schema, migrations, better-sqlite3 |
| Desktop/Electron | **trilium-electron** | Electron, desktop, main process, IPC, tray, menu |

## When to Use This Skill

Use this skill for broad project orientation:
- **Project Structure**: `apps/*` and `packages/*` layout.
- **Cache Architecture**: Becca/Froca/Shaca rules.
- **Widget Patterns**: `BasicWidget`, `NoteContextAwareWidget`, `RightPanelWidget`.
- **Entity Operations**: notes/branches/attributes and EntityChange flow.
- **Sync Entry Points**: `services/sync.ts`, `services/ws.ts`.

## Core Architecture Patterns

### Three-Layer Cache System (Critical)

```
Client (Browser/Electron)
└── Froca (frontend cache) ──────────┐
                                      │ WebSocket updates
Server (Node.js)                      │
└── Becca (backend cache) ───────────┤
    └── SQLite (persistence) ────────┤
                                      │
Shared (Share endpoint)               │
└── Shaca (share cache) ──────────────┘
```

**Golden Rule**: Do not bypass caches with ad-hoc SQL in application code.

```typescript
// Server cache
const note = becca.getNote(noteId);

// Client cache
const note = await froca.getNote(noteId);

// Avoid direct SQL access from app logic
const row = sql.getRow("SELECT * FROM notes WHERE noteId = ?", [noteId]);
```

### Entity Model

```
BNote ──┬── BBranch (parent/child tree relationships)
        │      Note can have multiple parents via cloning
        │
        └── BAttribute (key-value metadata)
               ├── Labels: #key=value
               └── Relations: ->targetNoteId
```

### Widget/Component Architecture

Widgets extend `BasicWidget` and render into `this.$widget` (jQuery). Right panel widgets extend `RightPanelWidget` and render into `this.$body`.

```typescript
// Right panel widget (sidebar)
class MyWidget extends RightPanelWidget {
    get widgetTitle() {
        return "My Widget";
    }

    doRenderBody() {
        this.$body.text("Hello from widget");
    }

    async refreshWithNote(note) {
        if (note) {
            this.$body.text(note.title);
        }
    }
}
```

**Note**: Preact/React components are supported via wrappers in `apps/client/src/widgets/react/`.

## Development Workflow

### Running & Testing

```bash
pnpm install
pnpm server:start
pnpm desktop:start

pnpm test:parallel
pnpm test:sequential
pnpm test:all

pnpm client:build
pnpm server:build
pnpm desktop:build
```

### Monorepo Navigation

```bash
pnpm --filter server test
pnpm --filter client build
pnpm --filter @triliumnext/commons lint
```

## Code Style & Conventions

- Follow `tsconfig.base.json` and the repo ESLint configs: `eslint.config.mjs`, `eslint.format.config.mjs`.
- Prefer explicit imports (no `import *`).

### Import Order

```typescript
import { h } from "preact";
import type { ComponentChildren } from "preact";

import type { EntityChange } from "@triliumnext/commons";

import froca from "../services/froca.js";
```

## Key Files & Locations

| Purpose | Location |
|---------|----------|
| Becca entities | `apps/server/src/becca/entities/` |
| Client cache (Froca) | `apps/client/src/services/froca.ts` |
| Search implementation | `apps/server/src/services/search/services/search.ts` |
| Widget base class | `apps/client/src/widgets/basic_widget.ts` |
| Database schema | `apps/server/src/assets/db/schema.sql` |
| Script API | `apps/server/src/services/backend_script_api.ts` |
| Routes registry | `apps/server/src/routes/routes.ts` |

## Common Patterns

### Protected Notes

```typescript
if (note.isContentAvailable()) {
    const content = note.getContent();
} else {
    const title = note.getTitleOrProtected();
}
```

### Attributes

```typescript
// Owned attributes only
const owned = note.getOwnedAttributes();

// All attributes, including inherited/template
const allAttrs = note.getAttributes();
```

### Long-Running Operations (TaskContext)

```typescript
const taskContext = new TaskContext("task-id", "import", "Import Notes");
taskContext.increaseProgressCount();
```

## Critical Pitfalls

- **Cache bypass**: avoid direct SQL writes outside of migrations or dedicated services.
- **Widget lifecycle**: create DOM in `doRender`/`doRenderBody`, update in `refreshWithNote`.
- **Sync timing**: after server writes from the client, wait for `ws.waitForMaxKnownEntityChangeId()` before reading from Froca.

## Documentation Guidelines

| Directory | Edit Method |
|-----------|-------------|
| `docs/User Guide/` | Use `pnpm edit-docs:edit-docs` |
| `docs/Script API/` | Auto-generated (do not edit manually) |
| `docs/Developer Guide/` | Direct Markdown editing |
| `docs/Release Notes/` | Direct Markdown editing |

## Commands Reference

```bash
pnpm server:start
pnpm desktop:start
pnpm edit-docs:edit-docs

pnpm test:parallel
pnpm test:sequential
pnpm test:all
pnpm client:coverage
pnpm server:coverage

pnpm typecheck
pnpm dev:linter-check
pnpm dev:format-check
```

## Using Specialized Skills

- **trilium-backend**: services, ETAPI, Becca, server routes
- **trilium-frontend**: widgets, Froca, client services, Preact wrappers
- **trilium-ckeditor**: editor build, plugins, toolbar/config
- **trilium-sync**: sync service, EntityChange flow, ws updates
- **trilium-database**: schema, migrations, sql service
- **trilium-electron**: desktop entry, window/tray integration
