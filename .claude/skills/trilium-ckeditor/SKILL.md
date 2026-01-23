# Trilium CKEditor5 Development Skill

**Trigger Phrases**: CKEditor, editor, rich text, WYSIWYG, CKEditor5 plugins, contenteditable

## Overview

Trilium uses a custom CKEditor5 build from `packages/ckeditor5`. Editor configuration and toolbar setup live in the client text widget under `apps/client/src/widgets/type_widgets/text/`.

## CKEditor5 Package Layout

```
packages/ckeditor5/src/
├── index.ts             # Exports ClassicEditor/PopupEditor/AttributeEditor
├── plugins.ts           # Plugin lists (CORE/COMMON/POPUP)
├── plugins/             # Trilium-specific plugins
├── theme/               # Theme CSS
```

External plugin packages:
- `packages/ckeditor5-admonition`
- `packages/ckeditor5-footnotes`
- `packages/ckeditor5-math`
- `packages/ckeditor5-mermaid`
- `packages/ckeditor5-keyboard-marker`

## Client Integration

```
apps/client/src/widgets/type_widgets/text/
├── config.ts            # buildConfig() - EditorConfig
├── toolbar.ts           # buildToolbarConfig()
├── CKEditorWithWatchdog.tsx
└── EditableText.tsx
```

## Adding a Plugin

1. Add the plugin implementation under `packages/ckeditor5/src/plugins/` or a dedicated `packages/ckeditor5-*` package.
2. Register it in `packages/ckeditor5/src/plugins.ts` (COMMON_PLUGINS or POPUP_EDITOR_PLUGINS).
3. Update toolbar entries in `apps/client/src/widgets/type_widgets/text/toolbar.ts` if needed.
4. Adjust config in `apps/client/src/widgets/type_widgets/text/config.ts` when new options are required.

## Development Commands

```bash
pnpm --filter @triliumnext/ckeditor5 build
pnpm --filter @triliumnext/ckeditor5 test
```

## MUST DO

- Keep editor config changes centralized in `config.ts` and `toolbar.ts`.
- Ensure plugins are added to the correct plugin list (CORE/COMMON/POPUP).
- Add theme CSS for new visual elements where required.

## MUST NOT DO

- Do not manipulate editor DOM directly; use CKEditor model/command APIs.
- Do not add plugin code without updating toolbar/config if the UI changes.
