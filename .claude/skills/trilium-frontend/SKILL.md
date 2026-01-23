# Trilium Frontend Development Skill

**Trigger Phrases**: frontend, client, widget, jQuery, Preact, Froca, UI, components, frontend services

## Overview

Trilium's frontend is in `apps/client`. It uses a hybrid widget/component system: legacy widgets render with jQuery, and newer UI uses Preact/TSX. This skill covers widget lifecycle, Froca cache usage, and client service patterns.

## Architecture Overview

```
apps/client/src/
├── widgets/              # Widget system (jQuery + TSX widgets)
│   ├── basic_widget.ts
│   ├── note_context_aware_widget.ts
│   ├── right_panel_widget.ts
│   └── type_widgets/
├── components/           # Component system, event bus, tab manager
├── services/             # Client services (server, ws, froca, etc.)
├── entities/             # FNote/FBranch/FAttribute
├── translations/         # i18n JSON
└── stylesheets/          # CSS
```

Key services:
- `services/server.ts` - HTTP/IPC client for backend routes.
- `services/ws.ts` - WebSocket connection + frontend-update handling.
- `services/froca.ts` - Frontend cache.
- `services/froca_updater.ts` - Applies entity changes.
- `services/note_create.ts`, `services/branches.ts`, `services/attributes.ts` - common operations.

## Widget System

### BasicWidget

`BasicWidget` (via `basic_widget.ts`) expects `doRender()` to build `this.$widget` (jQuery element).

```typescript
class MyWidget extends BasicWidget {
    doRender() {
        this.$widget = $("<div class=\"my-widget\"></div>");
        this.$widget.text("Hello");
    }
}
```

### NoteContextAwareWidget

Use `NoteContextAwareWidget` when the widget depends on the active note.

```typescript
class NoteInfoWidget extends NoteContextAwareWidget {
    async refreshWithNote(note) {
        if (note) {
            this.$widget.text(note.title);
        }
    }
}
```

### RightPanelWidget

Right panel widgets render into `this.$body` and can define header buttons.

```typescript
class MyPanelWidget extends RightPanelWidget {
    get widgetTitle() {
        return "My Panel";
    }

    doRenderBody() {
        this.$body.text("Panel body");
    }
}
```

### Preact/React Wrappers

Use wrappers in `apps/client/src/widgets/react/` if you need JSX inside widgets. Do not mix direct DOM mutations inside JSX components.

## Froca Cache

Froca is read-only cache mirrored from the server.

```typescript
const note = await froca.getNote(noteId);
const notes = await froca.getNotes([id1, id2]);
await froca.reloadNotes([noteId]);
await froca.loadSubTree(subTreeNoteId);
```

Writes should go through `services/server.ts` or higher-level services. After a write, wait for WebSocket sync before reading from Froca:

```typescript
await server.post("notes/...", payload);
await ws.waitForMaxKnownEntityChangeId();
const note = await froca.getNote(noteId);
```

## WebSocket Updates

- Client socket: `apps/client/src/services/ws.ts`.
- Server socket: `apps/server/src/services/ws.ts`.

Common message types handled on the client:
- `ping`
- `frontend-update`
- `sync-hash-check-failed`
- `consistency-checks-failed`
- `toast`
- `llm-stream`

`frontend-update` delivers `EntityChange[]` processed by `froca_updater`.

## i18n

- Use `t()` from `services/i18n.ts` for all UI strings.
- Translation JSON lives in `apps/client/src/translations/`.

## Development Commands

```bash
pnpm server:start
pnpm desktop:start
pnpm client:build
pnpm test:parallel
```

## Key Files

| File | Purpose |
|------|---------|
| `apps/client/src/widgets/basic_widget.ts` | Widget base class |
| `apps/client/src/widgets/note_context_aware_widget.ts` | Note-aware widget base |
| `apps/client/src/widgets/right_panel_widget.ts` | Right panel widget base |
| `apps/client/src/services/froca.ts` | Client cache |
| `apps/client/src/services/ws.ts` | WebSocket client |
| `apps/client/src/services/server.ts` | HTTP/IPC client |
| `apps/client/src/widgets/type_widgets/` | Note type widgets |

## MUST DO

- Build DOM in `doRender()`/`doRenderBody()` and update in `refreshWithNote()`.
- Use Froca for reads; use `server.ts` or higher-level services for writes.
- Wait for WS sync (`ws.waitForMaxKnownEntityChangeId()`) after writes before reading from Froca.
- Use `t()` for user-facing strings.

## MUST NOT DO

- Do not bypass Froca with ad-hoc cache mutations.
- Do not assume synchronous WebSocket updates after server writes.
- Do not mix direct DOM mutations inside JSX components.
