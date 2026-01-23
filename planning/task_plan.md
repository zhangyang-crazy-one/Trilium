# Task Plan: 笔记特性调研 + LLM 工具提示强化

## 目标
系统梳理 Trilium 笔记类型与渲染特性，将关键规则写入“生成/读取笔记”的工具提示，确保模型按类型与 HTML 规范输出。

## 当前阶段
Phase 4

## 阶段

### Phase 1: 需求与发现
- [x] 明确范围：笔记类型、双向链接、渲染规则
- [x] 从用户指南收集主要 note type 行为
- [x] 在 findings.md 记录来源与要点
- **状态:** complete

### Phase 2: 规划与结构
- [x] 定义需要写入工具提示的“统一规则清单”
- [x] 确定要修改的工具定义（create/update/read）
- **状态:** complete

### Phase 3: 实施
- [x] 更新 create_note / update_note / read_note 工具提示
- [x] 补充系统 prompt 中的 HTML/类型约束
- **状态:** complete

### Phase 4: 验证
- [x] 复核提示是否覆盖：HTML、内部链接、关系/渲染型 note
- [x] 确认无与现有工具参数冲突
- **状态:** complete

## 关键问题
1. 哪些 note 类型必须非 HTML 内容？
2. 内部链接/引用链接应该如何表达？
3. 哪些渲染特性依赖 attributes/relations 而非 HTML？

## 已做决策
| 决策 | 理由 |
|------|------|
| 以用户指南为权威来源 | 避免猜测与误导 |
| 工具提示强制区分 note type | 避免用 HTML 模拟非文本类型 |

## 注意事项
- 提示需简洁但强约束（“必须/禁止/否则”）
- 不能破坏现有工具行为与参数结构

---

# Task Plan: CI/Release 执行（当前状态）

## 目标
基于当前代码变更补充单元测试，推送 main 触发 CI，并启动 Release 流程。

## 当前阶段
Phase 1

## 阶段

### Phase 1: 提交准备
- [x] 确认单元测试已补充（LLM/MiniMax/Chat 存储相关）
- [x] 确认需要纳入发布的文件范围（排除 planning）
- **状态:** complete

### Phase 2: 触发 CI
- [x] 提交并推送 main，触发 dev.yml
- **状态:** complete

### Phase 3: 触发 Release
- [ ] 确认 Release tag 名称
- [ ] 触发 Release Desktop workflow（x64）
- **状态:** in_progress

## 注意事项
- Release Desktop 为手动 workflow，需要 tag 输入
- 现有 release.yml 对 v* tag 自动触发（如需避免需用 workflow_dispatch）

---

# Task Plan: 工具调用稳定性 + 流式消息持久化

## 目标
修复工具调用循环在流式场景下“无最终文本/工具调用丢失”的问题，确保完成任务后才结束，并在无向量搜索时自动降级。

## 当前阶段
Phase 3

## 阶段

### Phase 1: 诊断与策略
- [x] 复核 tool loop 路径（chat_pipeline）
- [x] 复核流式消息保存路径（server/client）
- [x] 识别无最终文本导致 UI 丢消息的触发条件
- **状态:** complete

### Phase 2: 实施修复
- [x] 工具 follow-up 禁用流式，避免 tool_calls 丢失
- [x] 兜底生成最终文本（必要时再请求一次 LLM）
- [x] stream done 无内容时客户端完成收尾
- [x] search_notes 无向量服务时自动降级关键字检索
- [x] MiniMax 工具场景禁用流式请求
- [x] 无 tool_calls 时强制 MiniMax 触发首个工具
- [x] 新增 move_note 工具以支持整理/移动笔记
- **状态:** complete

### Phase 3: 验证
- [x] 运行 `lsp_diagnostics`
- [x] 运行相关单测（如需要）
- **状态:** complete

---

# Task Plan: CI/CD Release（Linux x64 + Windows x64）

## 目标
新增可手动触发的 Release 流水线，仅发布 Linux x64 与 Windows x64 桌面包。

## 当前阶段
Phase 3 (完成)

## 阶段

### Phase 1: 方案与边界
- [x] 确认触发方式（workflow_dispatch + tag 输入）
- [x] 明确产物范围（Linux x64，Windows x64）
- **状态:** complete

### Phase 2: 实施
- [x] 新增 Release workflow
- [x] 产物上传与发布步骤
- [x] Release notes 处理策略
- **状态:** complete

### Phase 3: 验证
- [x] 运行 `lsp_diagnostics`（命令不存在，已记录）
- [x] 记录触发方式与验证点
- **状态:** complete

### 遇到的错误
| 错误 | 尝试 | 解决方案 |
|------|------|----------|
| `lsp_diagnostics` command not found | 1 | 记录到 progress，等待环境提供或替代命令 |

## 注意事项
- 以"稳定完成任务"为优先，允许牺牲部分流式体验
- 不能破坏现有聊天存储结构

---

# Task Plan: MiniMax AI 工具调用流优化

## 目标
分析 Trilium MiniMax AI Provider 的工具调用实现，对比行业最佳实践，给出并实施架构层面的优化建议。

## 当前阶段
Phase 5 (完成)

## 阶段

### Phase 1: 分析与规划
- [x] 分析 minimax_service.ts (656行)
- [x] 分析 chat_pipeline.ts (1100+行)
- [x] 分析 tool_calling_stage.ts (682行)
- [x] 对比 OpenAI/Anthropic/Vercel AI SDK 最佳实践
- [x] 在 findings.md 记录详细优化建议
- **状态:** complete

### Phase 2: 统一 Provider 响应契约
- [x] 定义 `NormalizedChatResponse` 接口
- [x] 实现各 Provider `toNormalizedResponse()` 方法
- [x] 更新 Pipeline 层使用 normalized 格式
- **状态:** complete

### Phase 3: 分离流式控制策略
- [x] 定义 `StreamingStrategy` 接口
- [x] 实现 `DefaultStreamingStrategy`
- [x] 移除 Pipeline/CompletionStage 硬编码
- **状态:** complete

### Phase 4: 拆分 minimax_service.ts
- [x] 创建 `providers/minimax/` 子目录
- [x] 抽取 minimax_client.ts
- [x] 抽取 stream_handler.ts
- [x] 抽取 tool_adapter.ts
- [x] 抽取 response_normalizer.ts
- [x] 保留 index.ts 主入口 (<200行)
- **状态:** complete

### Phase 5: 简化 ToolCallingStage
- [x] 定义 `ToolMetadata` 接口
- [x] 抽取统一参数解析器
- [x] 移除 3 层 try-catch
- [x] 工具注册时附带 parseArguments 方法
- **状态:** complete

## 优化优先级

| 优先级 | 优化项 | 预估工作量 | 影响范围 |
|--------|--------|------------|----------|
| P0 | 统一 Provider 契约 | 1-2 天 | Pipeline + 所有 Provider |
| P1 | 分离流式控制策略 | 1 天 | Pipeline + CompletionStage |
| P2 | 拆分 minimax_service.ts | 2 天 | MiniMax Provider |
| P3 | 简化 ToolCallingStage | 1 天 | ToolCallingStage |

## 风险与注意事项
- 向后兼容: 修改 Provider 接口可能影响现有功能，建议逐步迁移
- 测试覆盖: 大规模重构需要补充单元测试
- MiniMax 特殊性: 禁用流式的 workaround 是临时方案，长期需要调研 MiniMax 流式工具调用的正确方式

---

# Task Plan: 优化建议落地（chat_storage + MiniMax）

## 目标
落实用户优化建议：getChat 软删除过滤、MiniMax tool_choice 格式、工具完成回调完整性、温度范围校验，并补充关键单测。

## 当前阶段
Phase 3

## 阶段

### Phase 1: 代码修改
- [x] getChat SQL 添加 `notes.isDeleted = 0` 过滤
- [x] MiniMax tool_choice 默认对象格式 `{ type: "any" }`
- [x] MiniMax 工具完成回调使用完整 tool 信息
- [x] MiniMax temperature 超范围回落默认值
- **状态:** complete

### Phase 2: 测试补充
- [x] chat_storage_service 软删除过滤断言
- [x] minimax_service tool_choice 默认/温度范围测试
- **状态:** complete

### Phase 3: 验证
- [x] 运行 `lsp_diagnostics`
- [x] 运行相关单测（如需要）
- **状态:** complete

---

# Task Plan: Pipeline 文件长度合规

## 目标
拆分 `chat_pipeline.ts` 与 `tool_calling_stage.ts`，确保服务文件长度 <= 500 行，并保持功能不变。

## 当前阶段
Phase 1

## 阶段

### Phase 1: 拆分方案与边界
- [x] 明确可抽离的职责模块（流式控制、消息准备、工具执行循环等）
- [x] 拟定新文件结构与导出边界
- **状态:** complete

### Phase 2: 实施拆分
- [x] 抽离 `chat_pipeline.ts` 逻辑到子模块
- [x] 抽离 `tool_calling_stage.ts` 逻辑到子模块
- [x] 更新 imports/exports 与类型
- **状态:** complete

### Phase 3: 验证
- [x] 运行 `lsp_diagnostics`
- [x] 运行相关单测（如需要）
- **状态:** complete
