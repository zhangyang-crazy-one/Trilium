---
name: platform-build
description: |
  Trilium 构建与打包规范（桌面端与服务端）。

  触发场景：
  - Desktop/Electron 构建
  - Server/Client 构建
  - 发布包产物

  触发词：打包、构建、build、desktop、electron、server、client
---

# Trilium 构建与打包规范

## 构建入口

- Client: `pnpm client:build`
- Server: `pnpm server:build`
- Desktop: `pnpm desktop:build`

## 桌面打包

- Electron Forge: `pnpm run --filter desktop electron-forge:make`
- 生产启动：`pnpm desktop:start-prod`

## 质量检查

- `pnpm typecheck`
- `pnpm dev:linter-check`

## MUST DO

- 确保 client/server 构建通过再打包 desktop。
- 大改动后跑 `pnpm test:all`。

## MUST NOT DO

- 不要跳过类型检查就发布构建产物。
