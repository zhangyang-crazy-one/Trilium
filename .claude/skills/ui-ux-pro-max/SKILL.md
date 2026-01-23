---
name: ui-ux-pro-max
description: |
  Trilium UI/UX 设计规范。

  触发场景：
  - 前端 UI/交互修改
  - 组件样式/布局
  - 可用性与无障碍优化

  触发词：UI、UX、样式、布局、交互、可访问性、视觉
---

# Trilium UI/UX 规范

## 基本原则

- 遵循 `rules/ui-ux-rules.md` 的项目规范。
- UI 主要使用 Bootstrap + 自有 CSS。
- 组件体系以 `apps/client/src/widgets/` 和 `apps/client/src/components/` 为主。

## 风格约束

- 禁止使用 emoji 作为 UI 图标。
- 保持一致的图标风格与大小。
- 避免 hover 引起布局抖动。

## 可访问性

- 所有交互元素需有可见 focus 状态。
- 表单控件需有 label 或 aria-label。
- 颜色不能作为唯一信息载体。

## 常用入口

- CSS：`apps/client/src/stylesheets/`
- Widgets：`apps/client/src/widgets/`
- Components：`apps/client/src/components/`

## MUST DO

- 改动 UI 前先确认现有布局和类名。
- 重要交互提供 hover/focus/active 状态。

## MUST NOT DO

- 不要引入新的 UI 组件库。
- 不要直接内联大量样式，优先 CSS 文件。
