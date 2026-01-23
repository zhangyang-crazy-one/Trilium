#!/bin/bash
# skill-forced-eval.sh - 强制技能评估钩子 (Linux版)
# 触发时机: UserPromptSubmit（每次用户提交时）
# 功能: 评估并激活相关技能，检查是否需要查询外部文档

# 设置 UTF-8 编码
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 从环境变量或 stdin 读取用户输入
user_prompt=""

# 尝试从 stdin 读取
if [ ! -t 0 ]; then
    user_prompt=$(cat)
fi

# 如果 stdin 为空，尝试从参数读取
if [ -z "$user_prompt" ] && [ $# -gt 0 ]; then
    user_prompt="$1"
fi

# 跳过斜杠命令
if [[ "$user_prompt" =~ ^/[a-zA-Z]+ ]]; then
    echo "[Hook] 检测到斜杠命令，跳过技能评估: ${user_prompt%% *}"
    exit 0
fi

if [ -z "$user_prompt" ]; then
    exit 0
fi

# 转换为小写进行匹配
prompt_lower=$(echo "$user_prompt" | tr '[:upper:]' '[:lower:]')

# Trilium 技能定义 - 按优先级排序
declare -A SKILLS
SKILLS=(
    ["trilium-general"]="Trilium 通用开发 - 项目结构、缓存架构、实体模型"
    ["trilium-backend"]="Trilium 后端开发 - Becca 缓存、SQLite、ETAPI、服务层"
    ["trilium-frontend"]="Trilium 前端开发 - Widget 架构、jQuery/Preact、Froca 同步"
    ["trilium-ckeditor"]="Trilium CKEditor5 - 富文本编辑器、插件开发"
    ["trilium-sync"]="Trilium 同步系统 - WebSocket、EntityChange、冲突解决"
    ["trilium-database"]="Trilium 数据库 - SQLite Schema、迁移、EntityChange 跟踪"
    ["trilium-electron"]="Trilium Electron - 主进程、IPC 通信、桌面应用"
    ["ai-integration"]="AI 服务集成 - Gemini, Ollama, OpenAI API"
    ["context7"]="Context7 官方文档查询 - 第三方库文档"
    ["planning-with-files"]="Manus 风格的文件规划和任务管理"
    ["ui-ux-pro-max"]="UI/UX 设计智能"
    ["bug-debug"]="Bug 调试和排查"
    ["spec-interview"]="需求规格访谈"
    ["platform-build"]="平台构建和打包"
)

# Trilium 技能关键词
declare -A SKILL_KEYWORDS
SKILL_KEYWORDS["trilium-general"]="trilium project structure cache architecture entity model widget backend frontend server client"
SKILL_KEYWORDS["trilium-backend"]="backend server becca etapi api services sqlite database entitychange migration"
SKILL_KEYWORDS["trilium-frontend"]="frontend client widget jquery preact froca ui components frontend services api keyboard"
SKILL_KEYWORDS["trilium-ckeditor"]="ckeditor editor rich text wysiwyg contenteditable ckeditor5 plugin ckeditor"
SKILL_KEYWORDS["trilium-sync"]="sync synchronization websocket entitychange conflict conflict resolution real-time sync"
SKILL_KEYWORDS["trilium-database"]="database sqlite schema migration better-sqlite3 sql entitychange db"
SKILL_KEYWORDS["trilium-electron"]="electron desktop main process ipc preload renderer app tray menu native"
SKILL_KEYWORDS["ai-integration"]="ai llm gemini ollama openai api chat generate"
SKILL_KEYWORDS["context7"]="context7 official docs api docs library docs use context7 query docs"
SKILL_KEYWORDS["planning-with-files"]="plan planning task project scope requirements manus structure"
SKILL_KEYWORDS["ui-ux-pro-max"]="ui ux design style color typography font landing dashboard glassmorphism minimalism dark mode tailwind css responsive animation hover layout"
SKILL_KEYWORDS["bug-debug"]="bug error exception debug troubleshoot problem"
SKILL_KEYWORDS["spec-interview"]="spec specification interview requirements clarify scope define"
SKILL_KEYWORDS["platform-build"]="package build app electron-builder installer dmg exe deb publish"

# Trilium 特定库关键词 - 触发相关技能
TRILIUM_LIBRARY_KEYWORDS=(
    "trilium" "becca" "froca" "shaca" "entitychange"
    "ckeditor5" "codemirror" "excalidraw" "mermaid"
    "fancytree" "leaflet" "jsplumb" "tabulator"
    "better-sqlite3" "express" "ws" "websocket"
)

# 检查 Trilium 库提及
check_trilium_libraries() {
    local mentioned=()
    for lib in "${TRILIUM_LIBRARY_KEYWORDS[@]}"; do
        if [[ "$prompt_lower" == *"$lib"* ]]; then
            mentioned+=("$lib")
        fi
    done
    echo "${mentioned[@]}"
}

# 外部库关键词 - 触发 Context7 查询
LIBRARY_KEYWORDS=(
    "react-query" "tanstack" "zustand" "jotai" "recoil" "redux"
    "next.js" "nextjs" "nuxt" "svelte" "vue" "angular"
    "tailwindcss" "shadcn" "radix" "chakra" "antd" "material-ui" "mui"
    "zod" "yup" "formik" "react-hook-form"
    "axios" "swr" "trpc" "graphql"
    "vite" "webpack" "esbuild" "rollup" "turbopack"
    "express" "fastify" "nest" "koa"
    "prisma" "drizzle" "typeorm" "sequelize"
    "vitest" "jest" "playwright" "cypress"
)

# 检查库提及
check_library_mentions() {
    local mentioned=()
    for lib in "${LIBRARY_KEYWORDS[@]}"; do
        if [[ "$prompt_lower" == *"$lib"* ]]; then
            mentioned+=("$lib")
        fi
    done
    echo "${mentioned[@]}"
}

# 评估技能相关性
evaluate_skills() {
    local relevant_skills=()

    for skill in "${!SKILLS[@]}"; do
        keywords="${SKILL_KEYWORDS[$skill]}"
        match_count=0

        for keyword in $keywords; do
            if [[ "$prompt_lower" == *"$keyword"* ]]; then
                match_count=$((match_count + 1))
            fi
        done

        if [ "$match_count" -gt 0 ]; then
            relevant_skills+=("$skill")
        fi
    done

    echo "${relevant_skills[@]}"
}

mentioned_trilium_libraries=($(check_trilium_libraries))
mentioned_libraries=($(check_library_mentions))
relevant_skills=($(evaluate_skills))

echo "## 指令: 强制技能激活 (必须执行)"
echo ""

# ============================================
# Trilium 库检测
# ============================================
if [ ${#mentioned_trilium_libraries[@]} -gt 0 ]; then
    echo "### Trilium 组件检测"
    echo ""
    echo "检测到以下 Trilium 特定组件:"
    echo ""
    for lib in "${mentioned_trilium_libraries[@]}"; do
        echo "- **$lib**"
    done
    echo ""
    echo "这些组件将激活相应的 Trilium 专业技能:"
    echo ""
fi

# ============================================
# Context7 查询检查
# ============================================
if [ ${#mentioned_libraries[@]} -gt 0 ]; then
    echo "### 外部库检测 (Context7 查询)"
    echo ""
    echo "检测到以下外部库/框架:"
    echo ""
    for lib in "${mentioned_libraries[@]}"; do
        echo "- **$lib**"
    done
    echo ""
    echo "根据 \`.claude/rules/06-context7-query.md\` 规则："
    echo ""
    echo "1. 如果你对这些库**不熟悉**，**必须**先查询官方文档"
    echo "2. 查询优先级: Context7 → deepwiki.com → GitHub"
    echo "3. 查询前告知用户，查询后引用来源"
    echo ""
fi

# ============================================
# 技能评估
# ============================================
echo "### 步骤 1 - 评估技能"
echo "对每个技能，说明: [技能名] - 是/否 - [原因]"
echo ""
echo "可用技能 (Trilium 专用技能优先):"
for skill in "${!SKILLS[@]}"; do
    echo "  - $skill: ${SKILLS[$skill]}"
done
echo ""
echo "用户输入: $user_prompt"
echo ""

# 如果检测到 Trilium 特定库，优先显示 trilium-general
echo "### 步骤 2 - 激活技能"

if [ ${#relevant_skills[@]} -gt 0 ]; then
    echo "检测到相关技能:"
    for skill in "${relevant_skills[@]}"; do
        # 找出匹配的关键词
        keywords="${SKILL_KEYWORDS[$skill]}"
        matched=""
        for keyword in $keywords; do
            if [[ "$prompt_lower" == *"$keyword"* ]]; then
                matched="$matched $keyword"
            fi
        done
        echo "- $skill: 是 - 匹配关键词:$matched"
    done
    echo ""

    echo "### 技能激活通知"
    for skill in "${relevant_skills[@]}"; do
        case "$skill" in
            "trilium-general")
                echo "[Skill Activated] trilium-general skill activated - Trilium 通用开发模式"
                ;;
            "trilium-backend")
                echo "[Skill Activated] trilium-backend skill activated - Trilium 后端开发模式"
                ;;
            "trilium-frontend")
                echo "[Skill Activated] trilium-frontend skill activated - Trilium 前端开发模式"
                ;;
            "trilium-ckeditor")
                echo "[Skill Activated] trilium-ckeditor skill activated - Trilium CKEditor5 开发模式"
                ;;
            "trilium-sync")
                echo "[Skill Activated] trilium-sync skill activated - Trilium 同步系统模式"
                ;;
            "trilium-database")
                echo "[Skill Activated] trilium-database skill activated - Trilium 数据库模式"
                ;;
            "trilium-electron")
                echo "[Skill Activated] trilium-electron skill activated - Trilium Electron 桌面模式"
                ;;
            "spec-interview")
                echo "[Skill Activated] Spec Interview skill activated - 需求规格访谈模式"
                ;;
            "planning-with-files")
                echo "[Skill Activated] Planning-with-Files skill activated - Manus 风格文件规划模式"
                ;;
            "ui-ux-pro-max")
                echo "[Skill Activated] UI/UX Pro Max skill activated - UI/UX 设计智能模式"
                ;;
            *)
                echo "[Skill Activated] $skill skill activated - ${SKILLS[$skill]}"
                ;;
        esac
    done
    echo ""

    echo "激活命令:"
    for skill in "${relevant_skills[@]}"; do
        echo "> Skill($skill)"
    done
else
    echo "所有技能评估为 '否'，说明 '不需要技能' 并继续"
fi

echo ""
echo "### 步骤 3 - 实现"
echo "只有完成步骤 1 和 2 后，才开始实现用户请求。"
echo ""
echo "### 重要提示"
echo "- 必须在步骤 3 之前完成步骤 1 和 2"
echo "- 使用 \`Skill()\` 工具激活相关技能"
echo "- 如果没有相关技能，解释原因并直接回答"
echo "- **Trilium 开发优先使用 trilium-* 系列技能**"
