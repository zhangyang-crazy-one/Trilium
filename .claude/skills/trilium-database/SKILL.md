# Trilium Database Development Skill

**Trigger Phrases**: database, SQLite, schema, migrations, better-sqlite3, EntityChange, sql, db

## Overview

Trilium uses SQLite with a centralized SQL wrapper (`apps/server/src/services/sql.ts`). Schema lives in `apps/server/src/assets/db/schema.sql`, and migrations are defined in `apps/server/src/migrations/migrations.ts` and applied by `services/migration.ts`.

## Database Structure

```
apps/server/src/assets/db/
├── schema.sql
├── demo.zip

apps/server/src/migrations/
├── migrations.ts
└── 0xxx__*.ts
```

Common tables: `notes`, `branches`, `attributes`, `attachments`, `blobs`, `entity_changes`, `options`.

## SQL Wrapper (Preferred API)

Use `services/sql.ts` for all queries and transactions.

```typescript
import sql from "../services/sql.js";

const note = sql.getRow("SELECT * FROM notes WHERE noteId = ?", [noteId]);
const count = sql.getValue<number>("SELECT COUNT(*) FROM notes");

sql.transactional(() => {
    sql.execute("UPDATE notes SET title = ? WHERE noteId = ?", [title, noteId]);
});
```

### Important Notes

- `sql.transactional()` automatically notifies WebSocket clients after commit.
- If a transaction fails, Becca reloads and `entity_changes` are recalculated.

## Migrations

- Migration definitions: `apps/server/src/migrations/migrations.ts`.
- Runner: `apps/server/src/services/migration.ts` (invoked during startup).

Migrations can be SQL strings or JS modules. Keep migrations ordered and update `dbVersion` in `options` via the migration runner (not manually).

## Initialization

- `apps/server/src/services/sql_init.ts` creates schema and imports demo content.
- `schema.sql` is the canonical schema used for fresh DB creation.

## Environment Notes

- `BETTERSQLITE3_NATIVE_PATH` can override native binding.
- `TRILIUM_INTEGRATION_TEST=memory` / `memory-no-store` changes DB behavior for tests.

## Development Commands

```bash
pnpm server:start
pnpm server:test
pnpm server:build
```

## Key Files

| File | Purpose |
|------|---------|
| `apps/server/src/services/sql.ts` | SQL wrapper + statement cache |
| `apps/server/src/services/sql_init.ts` | DB initialization |
| `apps/server/src/services/migration.ts` | Migration runner |
| `apps/server/src/migrations/migrations.ts` | Migration list |
| `apps/server/src/assets/db/schema.sql` | Schema definition |

## MUST DO

- Use `sql` helper functions for queries.
- Wrap multi-step operations in `sql.transactional()`.
- Add migrations instead of editing schema in-place for existing DBs.

## MUST NOT DO

- Do not use raw better-sqlite3 directly outside the SQL service.
- Do not change `schema.sql` without a corresponding migration.
- Do not bypass EntityChange creation when mutating core entities.
