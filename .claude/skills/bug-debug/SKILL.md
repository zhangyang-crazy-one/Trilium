---
name: bug-debug
description: |
  Trilium 问题排查调试指南。

  触发场景：
  - 排查报错/崩溃
  - 服务端/桌面端运行问题
  - 前端渲染与 WebSocket 同步异常
  - 性能问题定位

  触发词：Bug、报错、错误、异常、调试、排查、崩溃、性能、慢、sync、ws
---

# Trilium 问题排查调试指南

## 基本思路

1. 先确认是 **客户端(UI)**、**服务端(server)**、还是 **桌面端(Electron)**。
2. 记录复现步骤与日志位置。
3. 通过最小化修改验证定位。

## 常用入口

- Server 启动：`pnpm server:start`
- Desktop 启动：`pnpm desktop:start`
- Client 构建：`pnpm client:build`
- 全量测试：`pnpm test:all`

## 前端问题

- 入口：`apps/client/src/`
- WebSocket：`apps/client/src/services/ws.ts`
- Froca：`apps/client/src/services/froca.ts`
- Widget：`apps/client/src/widgets/`

检查点：
- 是否收到 `frontend-update` 消息
- 是否正确更新 Froca
- 是否使用 `t()` 做 i18n

## 后端问题

- 入口：`apps/server/src/`
- 日志：`apps/server/src/services/log.ts`
- 数据库：`apps/server/src/services/sql.ts`

检查点：
- Becca 是否加载成功
- SQL 是否在 `sql.transactional()` 内执行
- EntityChange 是否生成

## 桌面端问题

- 入口：`apps/desktop/src/main.ts`
- 窗口/托盘：`apps/server/src/services/window.ts`, `tray.ts`
- IPC 代理：`apps/server/src/routes/electron.ts`

检查点：
- server 是否成功启动
- Electron 日志是否有异常
- IPC 请求是否被 `electron.ts` 路由接收

## MUST DO

- 复现并记录最小步骤。
- 查日志与 WebSocket 消息流。
- 修复后至少跑相关测试或构建。

## MUST NOT DO

- 不要跳过 WS 同步检查。
- 不要直接在 DB 写入跳过 Becca。
