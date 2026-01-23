---
name: mcp-tools
description: |
  MCP 工具协议说明（本项目默认未集成）。

  触发场景：
  - 引入 MCP server/client
  - 使用 MCP 工具进行外部集成

  触发词：MCP、工具、protocol、server
---

# MCP 工具协议（Trilium 说明）

当前仓库未发现 MCP 相关实现目录或配置。若需要新增 MCP 支持：

1. 明确集成目标与协议需求。
2. 选择落点（server 侧或 client 侧）。
3. 衔接现有 LLM 工具体系：`apps/server/src/services/llm/tools/`。

**建议**：若只是 LLM 工具调用，优先复用现有工具框架。
