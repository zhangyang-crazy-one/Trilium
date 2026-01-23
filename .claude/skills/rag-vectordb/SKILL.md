---
name: rag-vectordb
description: |
  Trilium 语义检索与上下文管理说明。

  触发场景：
  - 语义检索、上下文构建
  - LLM 相关的 note 召回
  - 嵌入/向量相关能力

  触发词：RAG、向量、检索、embedding、语义搜索、上下文
---

# Trilium 语义检索与上下文管理

## 现状

LLM 上下文与语义检索位于：
- `apps/server/src/services/llm/context/`
- `apps/server/src/services/llm/context/modules/semantic_search.ts`

数据库迁移中曾出现嵌入表的新增与移除（`migrations.ts`），因此如需引入持久化向量，请先确认当前版本策略。

## 关键入口

- `context/services/context_service.ts`：上下文主入口
- `context/modules/provider_manager.ts`：embedding provider 选择
- `context/modules/semantic_search.ts`：语义召回

## MUST DO

- 优先复用 `context_service` 现有接口。
- 若新增持久化 embedding，必须同步更新 migration/schema。

## MUST NOT DO

- 不要在未确认迁移策略的情况下新增 embedding 表。
- 不要绕过 LLM context 模块直接访问 DB 做向量检索。
