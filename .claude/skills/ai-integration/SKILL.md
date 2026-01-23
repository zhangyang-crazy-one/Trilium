---
name: ai-integration
description: |
  Trilium AI/LLM 集成开发规范。

  触发场景：
  - AI 对话/聊天能力
  - LLM 流式响应
  - Provider 配置与切换
  - LLM 工具调用与上下文构建

  触发词：AI、LLM、大模型、OpenAI、Anthropic、Ollama、MiniMax、对话、流式、工具
---

# Trilium AI/LLM 集成开发规范

## 入口与架构

LLM 服务集中在 `apps/server/src/services/llm/`：

- `ai_service_manager.ts`：Provider 选择与统一入口
- `providers/`：OpenAI、Anthropic、Ollama、MiniMax 等实现
- `chat_service.ts` / `chat_storage_service.ts`：对话与存储
- `context/`：上下文构建与语义检索
- `tools/`：LLM 工具与调用初始化

## Provider 与配置

当前 Provider 实现位置：
- `providers/openai_service.ts`
- `providers/anthropic_service.ts`
- `providers/ollama_service.ts`
- `providers/minimax_service.ts`

配置入口：
- `config/`（配置解析与验证）
- `ai_service_manager.ts`（选择当前 provider 与模型）

## 流式响应

流式输出由 server 侧处理，客户端通过 WebSocket 接收：
- 服务端：`apps/server/src/services/llm/streaming/`
- WS 消息：`apps/server/src/services/ws.ts` -> `llm-stream`
- 客户端：`apps/client/src/services/ws.ts` 处理 `llm-stream`

## 上下文构建

上下文系统在 `apps/server/src/services/llm/context/`，主入口：
- `context/services/context_service.ts`
- `context/modules/*`（语义搜索、缓存、格式化等）

## 开发要点

- 统一使用 `AIServiceManager` 访问 provider。
- Provider 变更必须通过配置系统进行校验。
- 流式响应必须走 WS 通道，避免阻塞 HTTP 请求。
- 注意保护敏感信息，不在日志中输出密钥。

## MUST DO

- 使用 `ai_service_manager.ts` 获取服务实例。
- 变更 provider 或模型时更新配置验证。
- 流式输出通过 `llm-stream` 发送到前端。

## MUST NOT DO

- 不要在客户端直连 LLM API。
- 不要绕过配置系统直接实例化 provider。
- 不要在日志中输出 API Key 或完整 prompt 内容。
