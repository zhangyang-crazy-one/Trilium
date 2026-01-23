# Trilium Sync Development Skill

**Trigger Phrases**: sync, synchronization, WebSocket, EntityChange, sync protocol

## Overview

Trilium sync has two related pieces:
1. **Frontend updates** via WebSocket (`ws.ts`) that keep Froca in sync with Becca.
2. **Server-to-server sync** (`sync.ts`) that pushes/pulls EntityChanges to a sync server.

## Key Components

```
apps/server/src/services/
├── ws.ts                # WebSocket updates to clients
├── sync.ts              # Sync orchestration (push/pull)
├── sync_update.ts       # Apply incoming changes
├── sync_mutex.ts        # Sync locking
├── sync_options.ts      # Sync config
├── entity_changes.ts    # EntityChange tracking

apps/client/src/services/
├── ws.ts                # WebSocket client
├── froca_updater.ts     # Apply EntityChange to Froca
```

## WebSocket Frontend Updates

- Client sends `ping` with `lastEntityChangeId`.
- Server replies with `frontend-update` containing `entityChanges`.
- Client processes changes via `froca_updater`.

Other server-sent messages include:
- `sync-pull-in-progress`, `sync-push-in-progress`, `sync-finished`, `sync-failed`
- `reload-frontend`, `sync-hash-check-failed`, `consistency-checks-failed`
- `toast`, `llm-stream`, `api-log-messages`

## Server-to-Server Sync Flow

`services/sync.ts`:
- Authenticates with sync server.
- Pushes local `EntityChange` records.
- Pulls remote changes and applies them via `sync_update.ts`.
- Uses `sync_mutex.ts` to avoid concurrent sync runs.

## EntityChange

`entity_changes` table is the source of truth for change propagation.
- Created by Becca entities or services.
- Used by WebSocket updates and server sync.

## MUST DO

- Use `entity_changes` and `sync_update` instead of ad-hoc data sync.
- Wrap sync operations in `sync_mutex` to prevent concurrent runs.
- Use `ws.waitForMaxKnownEntityChangeId()` after client writes.

## MUST NOT DO

- Do not bypass `entity_changes` when modifying synced entities.
- Do not add custom sync protocols outside `services/sync.ts` without integrating with existing flows.
