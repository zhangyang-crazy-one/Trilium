# Trilium Backend Development Skill

**Trigger Phrases**: backend, server, Becca, ETAPI, API, services, SQLite, EntityChange

## Overview

Trilium's backend lives in `apps/server`. It is a Node.js/Express app with a Becca cache, a SQL wrapper around better-sqlite3, and a large service layer.

## Backend Structure

```
apps/server/src/
├── becca/                 # Backend cache
│   └── entities/          # BNote/BBranch/BAttribute/etc.
├── services/              # Business logic (notes, sync, search, etc.)
├── routes/                # Internal API routes
├── etapi/                 # External API (ETAPI)
├── migrations/            # Migration modules
└── assets/db/             # schema.sql + demo content
```

Entry points:
- `apps/server/src/main.ts` -> starts `www.ts`.
- `apps/server/src/app.ts` / `www.ts` -> Express app setup.

## Becca Cache Patterns

- **Read**: use Becca entities (`becca.getNote`, `becca.getBranch`, etc.).
- **Write**: use services (e.g., `services/notes.ts`, `services/attributes.ts`).
- **EntityChange**: Becca entities create `EntityChange` records when saved/deleted.

```typescript
import becca from "../becca/becca.js";
import noteService from "../services/notes.js";

const note = becca.getNote(noteId);
const { note: created, branch } = noteService.createNewNote(params);
```

## SQL Access

Direct SQL should go through `apps/server/src/services/sql.ts`.

```typescript
import sql from "../services/sql.js";

const row = sql.getRow("SELECT * FROM notes WHERE noteId = ?", [noteId]);

sql.transactional(() => {
    sql.execute("UPDATE notes SET title = ? WHERE noteId = ?", [title, noteId]);
});
```

## ETAPI (External API)

ETAPI routes live in `apps/server/src/etapi/` and are registered in `routes/routes.ts`.

Common helpers:
- `apps/server/src/etapi/etapi_utils.ts` (route wrapper + error helpers)
- `apps/server/src/etapi/validators.ts`

## Sync Integration

Backend sync is handled by:
- `apps/server/src/services/sync.ts` (sync orchestration)
- `apps/server/src/services/sync_update.ts` (apply incoming changes)
- `apps/server/src/services/ws.ts` (frontend updates)

## Development Commands

```bash
pnpm server:start
pnpm server:test
pnpm server:build
pnpm server:coverage
```

## Key Files

| File | Purpose |
|------|---------|
| `apps/server/src/services/sql.ts` | SQL wrapper + transactions |
| `apps/server/src/services/notes.ts` | Note creation/update logic |
| `apps/server/src/services/attributes.ts` | Label/relation helpers |
| `apps/server/src/services/ws.ts` | Frontend WS updates |
| `apps/server/src/etapi/` | ETAPI endpoints |
| `apps/server/src/routes/routes.ts` | Route registry |

## MUST DO

- Use Becca + service layer for entity changes.
- Use `sql.transactional` for multi-step DB changes.
- Keep ETAPI responses backward compatible.
- Log via `services/log.ts` on the server.

## MUST NOT DO

- Do not write to SQLite directly from random modules.
- Do not bypass Becca by mutating DB rows outside services/migrations.
- Do not assume client cache is up-to-date without WS updates.
