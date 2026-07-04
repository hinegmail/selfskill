#!/usr/bin/env bash
#
# ProjectOrchestrator 一键初始化脚本 (macOS / Linux)
#
# 用法:
#   ./init.sh [OPTIONS]
#
# 选项:
#   -p, --path PATH       目标项目路径 (默认: 当前目录)
#   -i, --ide IDES        IDE列表, 逗号分隔 (默认: all)
#                          可选: cursor, cursor-legacy, cline, windsurf, claude, gemini, agents, all
#   -l, --lite            轻量模式 (仅创建5个核心文件)
#   -f, --force           强制覆盖已存在的 .ai/ 模板文件
#   -s, --source PATH     SelfSkill 源目录 (默认: 脚本所在目录)
#   -h, --help            显示帮助
#
# 示例:
#   ./init.sh -p ~/Projects/MyApp -i cursor,cline --lite
#   ./init.sh -p . -i all --force
#   ./init.sh

set -euo pipefail

# ============================================================
# 默认值
# ============================================================

TARGET_PATH="."
IDE_LIST="all"
LITE_MODE=false
FORCE_MODE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SOURCE="$SCRIPT_DIR"

# ============================================================
# 参数解析
# ============================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--path)
            TARGET_PATH="$2"
            shift 2
            ;;
        -i|--ide)
            IDE_LIST="$2"
            shift 2
            ;;
        -l|--lite)
            LITE_MODE=true
            shift
            ;;
        -f|--force)
            FORCE_MODE=true
            shift
            ;;
        -s|--source)
            SKILL_SOURCE="$2"
            shift 2
            ;;
        -h|--help)
            head -n 17 "$0" | tail -n 15
            exit 0
            ;;
        *)
            echo "❌ 未知参数: $1"
            exit 1
            ;;
    esac
done

# ============================================================
# 验证
# ============================================================

TEMPLATES_DIR="$SKILL_SOURCE/templates/ai"
ADAPTERS_DIR="$SKILL_SOURCE/adapters"

if [[ ! -f "$SKILL_SOURCE/skill.md" ]]; then
    echo "❌ 未找到 skill.md。请确认源目录: $SKILL_SOURCE"
    exit 1
fi

TARGET_PATH="$(cd "$TARGET_PATH" 2>/dev/null && pwd || echo "$TARGET_PATH")"
AI_DIR="$TARGET_PATH/.ai"

echo ""
echo "🚀 ProjectOrchestrator 初始化"
echo "   目标项目: $TARGET_PATH"
echo "   模式: $([ "$LITE_MODE" = true ] && echo '轻量 (Lite)' || echo '完整 (Full)')"
echo "   IDE: $IDE_LIST"
echo ""

# ============================================================
# 创建 .ai/ 目录
# ============================================================

mkdir -p "$AI_DIR"
echo "📁 .ai/ 目录就绪"

# 核心文件
CORE_FILES=("requirements.md" "DESIGN.md" "TASKS.md" "STATUS.md" "NEXT.md" "STEERING.md")
FULL_FILES=("RULES.md" "TEST_LOG.md" "DECISIONS.md" "LESSONS.md" "EVOLUTION_PROPOSALS.md")

# 复制模板文件函数，如果指定了 --force 则强制覆盖已存在的文件
copy_template_file() {
    local src="$1"
    local dst="$2"
    local name="$3"
    if [[ -f "$dst" ]]; then
        if [[ "$FORCE_MODE" = true ]]; then
            if [[ -f "$src" ]]; then
                cp "$src" "$dst"
                echo "  *️⃣  $name (已覆盖)"
            else
                echo "  ⚠️  模板不存在: $name"
            fi
        else
            echo "  ⏭️  $name (已存在，跳过)"
        fi
    else
        if [[ -f "$src" ]]; then
            cp "$src" "$dst"
            echo "  ✅ $name"
        else
            echo "  ⚠️  模板不存在: $name"
        fi
    fi
}

for file in "${CORE_FILES[@]}"; do
    copy_template_file "$TEMPLATES_DIR/$file" "$AI_DIR/$file" ".ai/$file"
done

if [[ "$LITE_MODE" = false ]]; then
    for file in "${FULL_FILES[@]}"; do
        copy_template_file "$TEMPLATES_DIR/$file" "$AI_DIR/$file" ".ai/$file"
    done
fi

# ============================================================
# 安装 IDE 适配器
# ============================================================

echo ""
echo "🔌 安装 IDE 适配器"

if [[ "$IDE_LIST" = "all" ]]; then
    IDES=("cursor" "cline" "windsurf" "claude" "gemini" "agents" "antigravity" "kiro")
else
    IFS=',' read -ra IDES <<< "$IDE_LIST"
fi

# 安装 IDE 适配器函数，适配器（规则文件）在存在时总是强制覆盖更新
install_adapter() {
    local src="$1"
    local dst="$2"
    local label="$3"
    if [[ -f "$src" ]]; then
        local parentDir
        parentDir=$(dirname "$dst")
        mkdir -p "$parentDir"
        if [[ -f "$dst" ]]; then
            cp "$src" "$dst"
            echo "  *️⃣  $label (已更新)"
        else
            cp "$src" "$dst"
            echo "  ✅ $label"
        fi
    else
        echo "  ⚠️  适配器模板不存在: $label"
    fi
}

for ide in "${IDES[@]}"; do
    ide=$(echo "$ide" | xargs) # trim whitespace
    case "$ide" in
        cursor)
            install_adapter "$ADAPTERS_DIR/cursor.mdc" "$TARGET_PATH/.cursor/rules/project-orchestrator.mdc" ".cursor/rules/project-orchestrator.mdc"
            ;;
        cursor-legacy)
            install_adapter "$ADAPTERS_DIR/cursorrules" "$TARGET_PATH/.cursorrules" ".cursorrules"
            ;;
        cline)
            install_adapter "$ADAPTERS_DIR/clinerules.md" "$TARGET_PATH/.clinerules/project-orchestrator.md" ".clinerules/project-orchestrator.md"
            ;;
        windsurf)
            install_adapter "$ADAPTERS_DIR/windsurfrules.md" "$TARGET_PATH/.windsurfrules" ".windsurfrules"
            ;;
        claude)
            install_adapter "$ADAPTERS_DIR/CLAUDE.md" "$TARGET_PATH/CLAUDE.md" "CLAUDE.md"
            ;;
        gemini)
            install_adapter "$ADAPTERS_DIR/gemini_styleguide.md" "$TARGET_PATH/.gemini/styleguide.md" ".gemini/styleguide.md"
            ;;
        agents)
            install_adapter "$ADAPTERS_DIR/AGENTS.md" "$TARGET_PATH/AGENTS.md" "AGENTS.md"
            ;;
        antigravity)
            install_adapter "$ADAPTERS_DIR/ANTIGRAVITY.md" "$TARGET_PATH/ANTIGRAVITY.md" "ANTIGRAVITY.md"
            ;;
        kiro)
            install_adapter "$ADAPTERS_DIR/KIRO_AGENT.md" "$TARGET_PATH/KIRO_AGENT.md" "KIRO_AGENT.md"
            ;;
        *)
            echo "  ⚠️  未知 IDE: $ide"
            ;;
    esac
done

# ============================================================
# 完成
# ============================================================

echo ""
echo "✨ 初始化完成！"
echo ""
echo "📌 下一步："
echo "   1. 编辑 .ai/requirements.md 填写产品需求"
echo "   2. 编辑 .ai/DESIGN.md 填写技术设计"
echo "   3. 编辑 .ai/TASKS.md 填写任务清单"
echo "   4. 编辑 .ai/NEXT.md 设置第一个活跃任务"
echo "   5. 在 AI IDE 中新开对话，输入："
echo ""
echo '   "使用 ProjectOrchestrator。进入 Context Audit 模式，'
echo '    读取 .ai/ 全部文件并输出审计报告。"'
echo ""
