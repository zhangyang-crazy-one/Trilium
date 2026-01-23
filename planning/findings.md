# 发现与研究记录

## 概述
记录软删除可见性与 MiniMax 工具调用失败的关键发现与代码位置。

---

## 技术发现

### Release tag 命名与说明文件
**日期:** 2026-01-23
**来源:** `.github/workflows/release.yml`, `docs/Release Notes/Release Notes/`

**内容:**
- 现有 release 流水线仅在 `v*` tag 触发。
- Release Notes 存在 `v0.101.1.md`，说明版本号通常带 `v` 前缀。

**影响:**
- 新增的手动 Release workflow 需确保 tag 统一使用 `v` 前缀，或做输入规范化。

### Release 仅构建 x64
**日期:** 2026-01-23
**来源:** 用户要求

**内容:**
- CI/CD Release workflow 仅发布 Linux x64 与 Windows x64 产物。

**影响:**
- 移除 Linux arm64 构建矩阵，保持 Linux 仅上传 deb/rpm 格式。

### 软删除历史仍可见
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/chat_storage_service.ts`

**内容:**
- 删除仅设置 `notes.isDeleted = 1`（软删除）。
- `getAllChats` 与 `getChat` 查询未过滤 `notes.isDeleted`，导致已删聊天仍被列出/拉回。

**影响:**
- 用户删除对话后仍能在历史中看到（与预期不符）。

---

### MiniMax 流式工具调用缺失
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/providers/minimax_service.ts`

**内容:**
- 当前流式解析仅在 `content_block_start` 里识别 `tool_use`。
- 若 MiniMax 仅在最终 `message.content` 中返回 `tool_use`，当前逻辑不会补解析。
- `input_json_delta` 采用 `event.index` 映射，但未建立 index->toolId 的稳定映射（多块混合时可能错配）。
- 未设置默认 `tool_choice` 时，模型可能选择纯文本回答。

**影响:**
- `response.tool_calls` 为空，工具调用阶段被跳过。

---

### 流式 follow-up 导致工具调用丢失 + 空响应
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/pipeline/chat_pipeline.ts`

**内容:**
- 工具执行后的 follow-up 仍按 `stream=true` 请求，MiniMax 在流式阶段生成 `tool_use`，但 tool loop 在流式完成后不再继续迭代。
- 当 follow-up 响应 `text` 为空时，pipeline 直接发送 `done=true`，导致客户端无法完成消息收尾。

**影响:**
- 工具调用不稳定、可能被“吞掉”。
- 流式结束后助手消息丢失。

---

### MiniMax 流式请求 400 invalid params
**日期:** 2026-01-22
**来源:** 运行日志 + `apps/server/src/services/llm/providers/minimax_service.ts`

**内容:**
- 在流式请求阶段返回 400 `invalid_request_error: invalid params`。
- 日志显示请求包含 `tools` 与 `tool_choice: 'auto'`，且走 `client.messages.stream(...)`。
- `tool_choice` 当前为字符串形式，MiniMax/Anthropic 兼容接口可能要求对象格式（例如 `{ type: "auto" }`），或对 `tools`/`input_schema` 的 JSON Schema 结构更严格。
- 错误发生在请求阶段，说明还未进入 tool_calls 解析或执行链路。

**影响:**
- 请求被拒绝，无法进入流式响应或工具调用阶段。

---

### LLMCompletionStage provider 解析报错
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/pipeline/stages/llm_completion_stage.ts`

**内容:**
- 日志报错 `getSelectedProviderAsync is not a function`。
- 实际可用方法为 `getSelectedProvider()`。

**影响:**
- provider 解析失败时会走 auto 路径，日志噪音增多，影响调试。

---

### minimax_service.ts 超过服务/工具文件长度限制
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/providers/minimax_service.ts`

**内容:**
- 当前文件 655 行，超过 500 行限制。
- 需要评估拆分为基础请求/流式解析/工具适配等模块。

**影响:**
- 违反代码风格规则，后续维护成本上升。

---

### 流式保存依赖 done+content
**日期:** 2026-01-22
**来源:** `apps/client/src/widgets/llm_chat/communication.ts`

**内容:**
- 客户端仅在收到 `message.content` 时更新 UI 与本地消息。
- 若服务端 `done=true` 包含空 content，助手消息不会被追加到本地消息队列。

**影响:**
- 某些异常流式场景下只保存用户消息。

---

### stream done 无 content 时客户端不收尾
**日期:** 2026-01-22
**来源:** `apps/client/src/widgets/llm_chat/communication.ts`

**内容:**
- 客户端仅在 `message.content` 存在时调用 `onContentUpdate`。
- 若仅收到 `done=true` 且 content 为空，streaming UI 仍处于“进行中”，未写入 assistant 消息。

**影响:**
- UI 刷新后助手回复消失（仅保留用户输入）。

---

## 代码发现

### 相关代码位置
| 文件 | 功能 | 备注 |
|------|------|------|
| apps/server/src/services/llm/chat_storage_service.ts | 聊天存储/删除/获取 | 未过滤 isDeleted |
| apps/server/src/services/llm/providers/minimax_service.ts | MiniMax 流式解析 | tool_use 解析不完整 |
| apps/server/src/services/llm/pipeline/chat_pipeline.ts | 流式消息处理 | done 信号与内容保存 |
| apps/server/src/routes/api/llm.ts | WebSocket streaming | done 时保存助手消息 |
| apps/client/src/widgets/llm_chat/communication.ts | 客户端流式接收 | 仅在 content 时更新 |

### 现有模式
- 工具定义由 `tool_registry` 注入到 LLM 请求。
- 聊天消息存储为 notes + blobs JSON。

---

## 决策记录

### 决策 1: 软删除通过查询过滤实现
**日期:** 2026-01-22
**选项:**
1. 仅过滤 `notes.isDeleted = 0`
2. 物理删除（永久移除）

**选择:** 选项 1
**理由:** 保留可恢复性，同时满足"历史不可见"。

---

## 已实施的修复

### 软删除过滤
**日期:** 2026-01-22
**文件:** `chat_storage_service.ts`

**修改:**
1. `getAllChats()` - 添加 `AND notes.isDeleted = 0` 过滤
2. `getChat()` - 添加 `isDeleted` 检查，删除笔记返回 null

### MiniMax 工具调用
**日期:** 2026-01-22
**文件:** `minimax_service.ts`

**修改:**
1. 添加默认 `tool_choice`（对象格式）
2. 添加兜底解析：从 `activeToolCalls` 构建 toolCalls
3. 确保 message 事件结束后 tool_calls 正确设置
4. 规范化 `tool_choice` 为 Anthropic 兼容对象（避免 400 invalid params）
5. 默认 `tool_choice` 调整为 `{ type: "any" }` 强制触发工具调用

---

### 工具名与提示不一致
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/constants/llm_prompt_constants.ts`, `apps/server/src/services/llm/pipeline/stages/tool_calling_stage.ts`

**内容:**
- 提示词中使用了不存在的 `vector_search`/`keyword_search` 名称。
- 工具实际名称为 `search_notes`/`keyword_search_notes`，导致模型或引导信息出现混淆。

**影响:**
- 降低工具调用命中率，且在空结果提示与参数指导中误导模型。

---

### 文本笔记 Markdown 输出导致内容格式错误
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/tools/note_creation_tool.ts`, `apps/server/src/services/llm/tools/note_update_tool.ts`

**内容:**
- AI 创建/更新文本笔记时经常输出 Markdown，而 Trilium 文本笔记默认是 HTML（rich text）。
- 已新增 Markdown->HTML 自动转换工具函数，并在 create/update 工具中应用。
- 系统提示补充：文本笔记应使用 HTML，Markdown 需转换或指定 Markdown MIME。

**影响:**
- 文本笔记显示为原始 Markdown 字符，影响可读性。

---

### 流式工具执行导致助手消息未落库
**日期:** 2026-01-22
**来源:** `apps/server/src/routes/api/llm.ts`

**内容:**
- 流式回调仅在累计内容非空时保存助手消息。
- 当工具调用阶段无文本流出但最终响应存在时，聊天记录可能缺失本轮助手回复。
- 已添加 pipeline 完成后的兜底保存（若流式未保存且最终响应非空）。

**影响:**
- 工具执行后刷新会话时，助手回复可能“消失”。

---

### 工具 follow-up 非流式 + 最终文本兜底
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/pipeline/chat_pipeline.ts`

**内容:**
- 工具 follow-up 请求强制 `stream=false`，避免 tool_calls 在流式阶段丢失。
- 当最终响应为空时，额外触发一次非工具 LLM 请求生成最终文本；仍为空则用工具结果兜底。

**影响:**
- 工具调用循环更稳定，避免“只执行工具但无最终回复”。

---

### MiniMax 首轮无 tool_calls 的兜底策略
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/pipeline/chat_pipeline.ts`

**内容:**
- MiniMax 工具请求禁用流式以提高 tool_calls 命中。
- 若首轮没有 tool_calls，则强制用特定工具执行一次（默认 search_notes / list_notes / keyword_search_notes）。

**影响:**
- 避免 MiniMax 无工具调用导致工具链路完全不启动。

---

### MiniMax 工具请求强制非流式
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/pipeline/stages/llm_completion_stage.ts`

**内容:**
- 在 LLMCompletionStage 内部直接检测所选 provider，当为 minimax 且工具启用时强制 `stream=false`。

**影响:**
- 避免 provider 流式模式下 tool_calls 丢失。

---

### 缺少移动笔记的工具
**日期:** 2026-01-22
**来源:** 运行日志（工具调用完成但无法移动）

**内容:**
- 工具链可以创建分类笔记，但缺少移动/改父节点的工具，导致“整理笔记”无法完成最后一步。

**影响:**
- 任务无法闭环，需要新增 move_note 工具。

---

### search_notes 无向量服务降级
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/tools/search_notes_tool.ts`

**内容:**
- 当 vector search 不可用或失败时，自动降级为关键字检索并返回标准结构。

**影响:**
- 搜索工具不再因向量服务不可用而直接报错。

---

### 新增工具: list_notes
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/tools/list_notes_tool.ts`, `apps/server/src/services/llm/tools/tool_initializer.ts`

**内容:**
- 新增 `list_notes` 工具用于列出某父节点下的子笔记（默认 root）。
- 支持 `maxResults`、`includeArchived`、`includeHidden` 参数。

**影响:**
- 支持“看下我有什么笔记？”类查询。

---

## 待研究
- [ ] MiniMax 是否在流式中返回 `content_block` 事件（非 start）
- [ ] tool_choice 默认值对 MiniMax 工具触发率的影响

---

## MiniMax AI 工具调用流优化分析

**日期:** 2026-01-22
**来源:** 综合分析 `apps/server/src/services/llm/` 目录下多个核心文件

### 分析范围

| 文件 | 行数 | 功能 |
|------|------|------|
| `providers/minimax_service.ts` | 656 | MiniMax Provider 实现（超过500行限制） |
| `pipeline/chat_pipeline.ts` | 1100+ | Pipeline 主编排器 |
| `pipeline/stages/tool_calling_stage.ts` | 682 | 工具执行阶段 |

### 当前信息流架构

```
用户输入
    ↓
┌─────────────────────────────────────────────────────────────┐
│ LLMCompletionStage                                          │
│ - 工具定义注入                                               │
│ - provider 选择 + 流式控制 (stream=false for MiniMax)        │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│ MiniMax Provider (minimax_service.ts:656)                   │
│ - chat() / stream() 入口                                    │
│ - 流式解析: content_block_start → tool_use                   │
│ - 兜底解析: 从 activeToolCalls 构建 toolCalls                │
│ - 格式转换: MiniMax → OpenAI 格式                            │
└─────────────────────────────────────────────────────────────┘
    ↓
response.tool_calls (Array) OR response.text (String)
    ↓
┌─────────────────────────────────────────────────────────────┐
│ ChatPipeline (chat_pipeline.ts)                             │
│ - tool_calls 检测 (50+ 行 workaround)                        │
│ - ToolCallingStage 编排                                      │
│ - follow-up 非流式请求                                        │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│ ToolCallingStage (tool_calling_stage.ts:682)                │
│ - 工具发现与参数解析                                          │
│ - 执行工具逻辑                                               │
│ - 结果注入回 conversation                                    │
└─────────────────────────────────────────────────────────────┘
```

### 识别的架构问题

#### 问题 1: Provider 响应契约不统一

**位置:** `providers/minimax_service.ts:656`

**现象:** 各 Provider 输出格式不一致，导致 Pipeline 层需要大量兼容逻辑。

```typescript
// 当前情况：不同 Provider 返回不同格式
// OpenAI/Anthropic: response.tool_calls (标准格式)
// MiniMax: 可能返回 text 或 tool_calls，格式不统一
```

**影响:**
- Pipeline 需要 50+ 行代码检测 `tool_calls` 存在性
- getter 劫持检测 + 直接属性检测混用

#### 问题 2: 流式控制逻辑分散

**位置:** 多处硬编码

```typescript
// chat_pipeline.ts
stream: providerName === 'minimax' && useTools ? false : ...

// llm_completion_stage.ts
if (providerName === 'minimax' && toolsEnabled) {
    stream = false;  // 硬编码
}
```

**影响:**
- 逻辑分散在 3+ 处
- 新增 Provider 需要重复添加兼容逻辑
- 违反 DRY 原则

#### 问题 3: minimax_service.ts 违反文件长度规范

**位置:** `providers/minimax_service.ts`

**数据:** 656 行，超过 500 行限制 (31% 超标)

**功能耦合:**
- HTTP 请求封装 (chat/stream)
- 流式事件解析
- 格式转换 (MiniMax → OpenAI)
- 兜底逻辑
- 错误处理

#### 问题 4: ToolCallingStage 复杂性

**位置:** `pipeline/stages/tool_calling_stage.ts`

**问题:**
- 3 层 try-catch 参数解析
- 工具指导信息硬编码
- 错误处理与重试逻辑耦合

```typescript
// 当前实现
try {
    args = JSON.parse(arguments);
} catch {
    try {
        const cleaned = arguments.replace(...);
        args = JSON.parse(cleaned);
    } catch {
        args = { text: arguments };  // 兜底
    }
}
```

### 建议的优化方案

#### P0: 统一 Provider 响应契约

**目标:** 定义 `NormalizedChatResponse` 接口，各 Provider 适配到统一格式。

```typescript
// 建议接口
interface NormalizedChatResponse {
    text: string;
    tool_calls: NormalizedToolCall[] | null;
    usage?: TokenUsage;
    stop_reason?: string | null;
}

interface NormalizedToolCall {
    id: string;
    type: 'function';
    function: {
        name: string;
        arguments: string;
    };
}
```

**实施:**
1. 定义 `NormalizedChatResponse` 接口
2. 各 Provider 实现 `toNormalizedResponse()` 方法
3. Pipeline 层统一使用 normalized 格式

#### P1: 分离流式控制策略

**目标:** 使用策略模式管理流式行为。

```typescript
interface StreamingStrategy {
    shouldStreamInitialRequest(provider: string, hasTools: boolean): boolean;
    shouldStreamFollowUp(provider: string): boolean;
}

class DefaultStreamingStrategy implements StreamingStrategy {
    shouldStreamInitialRequest(provider, hasTools) {
        if (hasTools && provider === 'minimax') {
            return false;  // MiniMax 工具调用禁用流式
        }
        return true;
    }
}
```

**实施:**
1. 抽取 `StreamingStrategy` 接口
2. Pipeline/CompletionStage 注入策略
3. 移除各处硬编码

#### P2: 拆分 minimax_service.ts

**目标:** 拆分为 4-5 个专注模块。

```
providers/minimax/
├── index.ts                    # 主入口 (<100行)
├── minimax_client.ts           # HTTP 请求封装
├── stream_handler.ts           # 流式事件解析
├── tool_adapter.ts             # 工具格式转换
└── response_normalizer.ts      # 响应标准化
```

**预估行数:**
- index.ts: ~80 行
- minimax_client.ts: ~150 行
- stream_handler.ts: ~200 行
- tool_adapter.ts: ~120 行
- response_normalizer.ts: ~100 行

#### P3: 简化 ToolCallingStage

**目标:** 移除参数解析复杂性，使用元数据驱动。

```typescript
// 建议：工具元数据 + 统一的参数解析器
interface ToolMetadata {
    name: string;
    description: string;
    parameters: JSONSchema;
    parseArguments(raw: string): object;
}

// 统一的解析器
function parseToolArguments(
    raw: string,
    schema: JSONSchema
): object {
    return validate(JSON.parse(raw), schema);
}
```

**实施:**
1. 定义 ToolMetadata 接口
2. 抽取统一参数解析器
3. 工具注册时附带 parseArguments 方法
4. 移除 3 层 try-catch

### 优化优先级与预估工作量

| 优先级 | 优化项 | 预估时间 | 影响范围 |
|--------|--------|----------|----------|
| P0 | 统一 Provider 契约 | 1-2 天 | Pipeline + 所有 Provider |
| P1 | 分离流式控制策略 | 1 天 | Pipeline + CompletionStage |
| P2 | 拆分 minimax_service.ts | 2 天 | MiniMax Provider |
| P3 | 简化 ToolCallingStage | 1 天 | ToolCallingStage |

### 风险与注意事项

1. **向后兼容:** 修改 Provider 接口可能影响现有功能，建议逐步迁移
2. **测试覆盖:** 大规模重构需要补充单元测试
3. **MiniMax 特殊性:** MiniMax 禁用流式的 workaround 是临时方案，长期需要调研 MiniMax 流式工具调用的正确方式

### 后续行动

- [ ] 定义 `NormalizedChatResponse` 接口
- [ ] 实现 `StreamingStrategy` 接口
- [ ] 创建 minimax/ 子目录结构
- [ ] 逐步迁移 minimax_service.ts 功能
- [ ] 更新 Pipeline 层使用 normalized 格式

---

*更新提示: 每次有新发现时更新此文件*

---

### 工具白名单/默认拒绝机制排查
**日期:** 2026-01-22
**来源:** `apps/server/src/services/llm/tools/tool_registry.ts`, `apps/server/src/services/llm/pipeline/stages/tool_calling_stage.ts`

**内容:**
- 未发现面向工具调用的显式白名单/权限拒绝规则。
- 工具唯一“允许”来源是 `tool_registry` 注册表；未注册或校验失败的工具会被过滤/拒绝（等同默认拒绝未注册工具）。
- `tool_calling_stage` 中仅做“是否存在 + execute 方法 + 校验通过”的检查，无权限/白名单策略。
- `formatter_constants` 有 HTML allowlist，但与工具调用无关。
- 证据定位: `apps/server/src/services/llm/tools/tool_registry.ts:57`, `apps/server/src/services/llm/tools/tool_registry.ts:93`, `apps/server/src/services/llm/tools/tool_registry.ts:114`, `apps/server/src/services/llm/tools/tool_registry.ts:139`, `apps/server/src/services/llm/pipeline/stages/tool_calling_stage.ts:132`, `apps/server/src/services/llm/pipeline/stages/tool_calling_stage.ts:535`, `apps/server/src/services/llm/tools/tool_initializer.ts:31`, `apps/server/src/services/llm/constants/formatter_constants.ts:9`.

**影响:**
- 工具调用失败更可能来自“未生成 tool_calls / 流式解析缺失 / tool_choice 不触发”，而不是白名单策略阻断。

---

### MiniMax Anthropic 兼容性文档要点
**日期:** 2026-01-22
**来源:** https://platform.minimax.io/docs/api-reference/text-anthropic-api

**内容:**
- Anthropic 兼容接口支持 MiniMax-M2.1 / MiniMax-M2.1-lightning / MiniMax-M2。
- `tool_choice` 与 `tools` 标记为“Fully supported”，消息字段支持 `text` / `tool_use` / `tool_result`。
- `messages` 为“Partial support”（不支持 image/document 输入）。
- `temperature` 范围为 (0.0, 1.0]，超出会报错。
- `top_k` / `stop_sequences` / `service_tier` / `mcp_servers` / `context_management` / `container` 被标注为 ignored。

**影响:**
- 请求参数需避免超范围 temperature 与非支持内容类型，否则可能触发 `invalid params`。

---

### 笔记类型与基础特性文档入口
**日期:** 2026-01-22
**来源:** `docs/User Guide/User Guide/Basic Concepts and Features/Notes.md`

**内容:**
- 文档指向各类笔记类型（Text、Canvas、Mermaid、Saved Search、Render Note 等）。
- Trilium 无“文件夹”专用类型，任何笔记都可作为父节点。

**影响:**
- 生成/读取工具提示中需要强调“无 folder 类型，任意 note 可有子节点”。

---

### 双向链接/链接地图与关系图入口
**日期:** 2026-01-22
**来源:** 
- `docs/User Guide/User Guide/Basic Concepts and Features/UI Elements/New Layout.md`
- `docs/User Guide/User Guide/Basic Concepts and Features/UI Elements/New Layout/Status bar.md`
- `docs/User Guide/User Guide/Advanced Usage/Note Map (Link map, Tree map).md`
- `docs/User Guide/User Guide/Note Types/Relation Map.md`

**内容:**
- Backlinks 在状态栏显示，点击可查看列表（双向链接特性）。
- Link map 展示进入/离开某笔记的链接与关系，自动生成。
- Relation map 是独立 note type，需要手动构建关系。

**影响:**
- 工具提示需强调双向链接/关系图在 UI 可视化，但底层是 link/relations（非纯 HTML 格式）。

---

### 文本笔记内部链接与引用链接
**日期:** 2026-01-22
**来源:**
- `docs/User Guide/User Guide/Note Types/Text/Links.md`
- `docs/User Guide/User Guide/Note Types/Text/Links/Internal (reference) links.md`

**内容:**
- 内部链接分两类：引用链接（标题镜像、带图标）与可自定义标题的普通链接。
- 内部链接支持悬停预览与在 note map 中可视化。
- 内部链接可通过 `@` 快速插入。

**影响:**
- 生成提示需强调“引用链接应保持指向 noteId 的 reference link 结构，而非普通 URL”。

---

### 文本笔记 HTML 中的引用链接标记
**日期:** 2026-01-22
**来源:** `apps/server/src/assets/doc_notes/en/User Guide/User Guide/Note Types/Text/Links/Internal (reference) links.html`

**内容:**
- 文档 HTML 里内部链接使用 `<a class="reference-link" href="#root/<noteId>">...</a>` 形式（示例链接到帮助笔记）。

**影响:**
- 生成提示需要明确：内部链接用 reference-link + `#root/<noteId>` 路径，避免外部 URL 误用。

---

### Text/Code 笔记类型特性
**日期:** 2026-01-22
**来源:**
- `docs/User Guide/User Guide/Note Types/Text.md`
- `docs/User Guide/User Guide/Note Types/Code.md`

**内容:**
- Text note 支持富文本、表格、图片、引用块、提示块、脚注、链接、包含笔记、数学公式、Mermaid 等。
- Text note 由 CKEditor 渲染，支持 Markdown-like 输入，但存储为 HTML。
- Code note 用于程序/结构化文本，支持语法高亮与脚本执行，语言由 MIME 决定。

**影响:**
- 生成提示需区分 text/html 与 code/plain，并提示 code note 用 MIME/语言控制。

---

### File/Canvas 笔记类型特性
**日期:** 2026-01-22
**来源:**
- `docs/User Guide/User Guide/Note Types/File.md`
- `docs/User Guide/User Guide/Note Types/Canvas.md`

**内容:**
- File note 用于外部文件（图片/视频/PDF/音频等），通常由导入或拖拽创建，不能直接创建空白 File note。
- File note 不能改类型；图像可通过引用嵌入 Text，非图像可通过 Include Note 以只读控件形式嵌入。
- Canvas note 基于 Excalidraw，用于手绘/图形，支持只读切换。

**影响:**
- 生成提示需避免“直接创建 File note”，并说明 File/Canvas 内容不应当用 HTML 模拟。

---

### Mermaid/Mind Map 笔记类型特性
**日期:** 2026-01-22
**来源:**
- `docs/User Guide/User Guide/Note Types/Mermaid Diagrams.md`
- `docs/User Guide/User Guide/Note Types/Mind Map.md`

**内容:**
- Mermaid note 以 Mermaid 文本语法描述图，预览区实时渲染，可导出 SVG/PNG 或复制图像引用。
- Mind Map note 以节点结构编辑，支持导出 SVG/PNG 与图像引用。

**影响:**
- 生成提示需指明 Mermaid/Mind Map 内容是专用格式，不应生成 HTML 模拟。

---

### Note Map / Relation Map 笔记类型特性
**日期:** 2026-01-22
**来源:**
- `docs/User Guide/User Guide/Note Types/Note Map.md`
- `docs/User Guide/User Guide/Note Types/Relation Map.md`

**内容:**
- Note Map 是链接/关系自动可视化，受 `mapIncludeRelation`/`mapExcludeRelation` 标签过滤。
- Relation Map 是独立 note type，需要手动创建关系；关系可带逆向关系。

**影响:**
- 生成提示需强调“Link map/Relation map 是可视化，不是 HTML 结构”，关系来自属性/relations。

---

### Render Note / Saved Search 笔记类型特性
**日期:** 2026-01-22
**来源:**
- `docs/User Guide/User Guide/Note Types/Render Note.md`
- `docs/User Guide/User Guide/Note Types/Saved Search.md`

**内容:**
- Render Note 通过 `renderNote` 关系指向 HTML/JSX code note 并渲染其内容。
- Saved Search 是保存查询的 note type，结果作为子笔记显示；`#searchHome` 控制存放位置。

**影响:**
- 生成提示需强调 Render Note 依赖 relation，Saved Search 内容为搜索语法而非 HTML。

---

### Web View / Include Note 特性
**日期:** 2026-01-22
**来源:**
- `docs/User Guide/User Guide/Note Types/Web View.md`
- `docs/User Guide/User Guide/Note Types/Text/Include Note.md`

**内容:**
- Web View 通过 `#webViewSrc` label 指定 URL，渲染受浏览器/iframe 限制。
- Include Note 在 text note 内嵌另一 note 的只读小组件，依赖引用关系。

**影响:**
- 生成提示需强调 Web View 依赖 label 配置，Include Note 是嵌入组件而非纯 HTML 拼接。

---

### 图像引用 / Markdown-like 输入
**日期:** 2026-01-22
**来源:**
- `docs/User Guide/User Guide/Note Types/Text/Images/Image references.md`
- `docs/User Guide/User Guide/Note Types/Text/Markdown-like formatting.md`

**内容:**
- 图像引用可在 Text note 内嵌 Canvas/Mermaid/Mind Map 的图像预览。
- Text note 支持 Markdown-like 快捷输入，但本质仍为 HTML（非 Markdown 存储）。

**影响:**
- 生成提示需强调“Text note 存储为 HTML，Markdown 仅是输入快捷方式”。

---

### 内部链接 HTML/路径格式（代码线索）
**日期:** 2026-01-22
**来源:**
- `apps/client/src/services/link.ts`
- `apps/client/src/widgets/collections/presentation/model.spec.ts`

**内容:**
- 内部链接通过 `#root/<notePath>` 作为 href（若仅 noteId 也会补 root 前缀）。
- reference link 通过 `a.reference-link` 标识（图标/标题由客户端渲染）。

**影响:**
- 生成提示应使用 `<a class="reference-link" href="#root/<notePath>">标题</a>`，不要手写图标或复杂嵌套。

---

### 内置笔记类型清单（客户端）
**日期:** 2026-01-22
**来源:** `apps/client/src/services/note_types.ts`

**内容:**
- 常见类型：text/html、code/plain、canvas/json、mermaid/text、mindMap/json、relationMap/json、noteMap、render、search、webView。
- 保留类型：file、image、contentWidget、doc、launcher、aiChat（用户无法直接创建）。

**影响:**
- 生成提示应禁止模型直接创建 reserved 类型（file/image 等），并提醒使用正确类型/MIME。

---

### 代码规范审查：文件长度违规
**日期:** 2026-01-22
**来源:**
- `apps/server/src/services/llm/pipeline/chat_pipeline.ts`
- `apps/server/src/services/llm/pipeline/stages/tool_calling_stage.ts`

**内容:**
- `chat_pipeline.ts` 1160 行，超过服务文件 500 行限制。
- `tool_calling_stage.ts` 656 行，超过服务文件 500 行限制。

**影响:**
- 需要进一步拆分模块以符合代码规范（服务文件 <= 500 行）。

---

### CI/CD 发布现状（桌面）
**日期:** 2026-01-23
**来源:**
- `.github/workflows/release.yml`
- `.github/actions/build-electron/action.yml`

**内容:**
- 现有 release workflow 通过 tag `v*` 触发，构建 macOS/Linux/Windows（含 Linux x64/arm64）。
- build-electron action 负责 Electron Forge 构建，Linux 产物包含 deb/flatpak/rpm。

**影响:**
- 若需只发布 Linux x64/arm64 与 Windows x64，可新增独立 release workflow，避免与现有 tag 发布冲突。
