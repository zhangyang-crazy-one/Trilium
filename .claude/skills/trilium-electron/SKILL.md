# Trilium Electron Development Skill

**Trigger Phrases**: Electron, desktop, main process, IPC, renderer, app, tray, menu

## Overview

The desktop app is a thin Electron wrapper around the server + client. The entry point is `apps/desktop/src/main.ts`, which starts the server and delegates window/tray behavior to server-side services.

## Architecture Overview

```
apps/desktop/src/main.ts        # Electron entry (starts server + windows)
apps/server/src/services/window.ts
apps/server/src/services/tray.ts
apps/server/src/routes/electron.ts
```

Key points:
- `window.ts` creates main/setup/print windows and registers IPC listeners.
- `tray.ts` manages the system tray and menu.
- `routes/electron.ts` wires IPC "server-request" to Express routes.

## Window & Tray Services

- `windowService.createMainWindow(app)` and `createSetupWindow()` are used by `main.ts`.
- Window options are defined in `apps/server/src/services/window.ts`.
- Tray menu and shortcuts are in `apps/server/src/services/tray.ts`.

## IPC Bridge

Electron IPC is used to proxy HTTP requests through the local server:
- Server side: `apps/server/src/routes/electron.ts`
- Client side: `apps/client/src/services/server.ts` listens for `server-response`

## Development Commands

```bash
pnpm desktop:start
pnpm desktop:build
pnpm desktop:start-prod
pnpm --filter desktop e2e
```

## MUST DO

- Use existing `windowService` and `tray` services instead of creating new Electron windows directly.
- Keep desktop logic in `apps/desktop` and `apps/server/src/services/*` rather than duplicating in the client.
- Test on at least one desktop platform after Electron changes.

## MUST NOT DO

- Do not introduce new Electron IPC channels without wiring them through `routes/electron.ts` and client services.
- Do not hardcode paths; use `app.getPath` or `RESOURCE_DIR` helpers.
