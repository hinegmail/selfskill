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
#                          可选: cursor, cursor-legacy, cline, windsurf, claude, gemini, agents, antigravity, kiro, all
#   -l, --lite            轻量模式 (仅创建6个核心文件)
#   -m, --micro           微型模式 (仅创建3个核心文件: NEXT.md, STATUS.md, LESSONS.md)
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
MICRO_MODE=false
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
        -m|--micro)
            MICRO_MODE=true
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
echo "   模式: $( [ "$MICRO_MODE" = true ] && echo '微型 (Micro)' || ([ "$LITE_MODE" = true ] && echo '轻量 (Lite)' || echo '完整 (Full)'))"
echo "   IDE: $IDE_LIST"
echo ""

# ============================================================
# 创建 .ai/ 目录
# ============================================================

mkdir -p "$AI_DIR"
echo "📁 .ai/ 目录就绪"

# 微型模式: 仅 3 个核心文件 + MODE_REFERENCE.md
MICRO_FILES=("NEXT.md" "STATUS.md" "LESSONS.md" "MODE_REFERENCE.md")

# 核心文件
CORE_FILES=("requirements.md" "DESIGN.md" "TASKS.md" "STATUS.md" "NEXT.md" "STEERING.md")
FULL_FILES=("RULES.md" "TEST_LOG.md" "DECISIONS.md" "LESSONS.md" "EVOLUTION_PROPOSALS.md")

# MODE_REFERENCE.md 总是安装 (compact 适配器依赖它)
ALWAYS_FILES=("MODE_REFERENCE.md")

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

# 总是安装 MODE_REFERENCE.md (compact 适配器依赖它)
for file in "${ALWAYS_FILES[@]}"; do
    copy_template_file "$TEMPLATES_DIR/$file" "$AI_DIR/$file" ".ai/$file"
done

if [[ "$MICRO_MODE" = true ]]; then
    # 微型模式: 仅核心运行时文件
    for file in "${MICRO_FILES[@]}"; do
        copy_template_file "$TEMPLATES_DIR/$file" "$AI_DIR/$file" ".ai/$file"
    done
else
    for file in "${CORE_FILES[@]}"; do
        copy_template_file "$TEMPLATES_DIR/$file" "$AI_DIR/$file" ".ai/$file"
    done

    if [[ "$LITE_MODE" = false ]]; then
        for file in "${FULL_FILES[@]}"; do
            copy_template_file "$TEMPLATES_DIR/$file" "$AI_DIR/$file" ".ai/$file"
        done
    fi
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
echo "ProjectOrchestrator Skill: 7-Mode自动化运作流程"
echo ""
echo "├─ MODE 1: Context Audit        (加载项目状态)"
echo "├─ MODE 2: Task Planning        (规划当前任务，自动)"
echo "├─ MODE 3: Implementation       (执行编码，您说'执行'→自动启动)"
echo "├─ MODE 4: Validation & Test    (运行测试，自动)"
echo "├─ MODE 5: Phase Closeout       (更新.ai/文件，自动 ✅)"
echo "├─ MODE 6: Skill Evolution      (提案改进，按需)"
echo "└─ New Conversation             (收口后推荐新开对话，切断上下文污染)"
echo ""
echo "🚀 快速开始 (3步):"
echo ""
echo "  1️⃣  在您的IDE (Cursor/Cline/Windsurf/Claude/Kiro等) 打开对话"
echo ""
echo "  2️⃣  说这条命令:"
echo ""
echo '      继续项目'
echo ""
echo "  3️⃣  AI会自动执行 Mode 1 → Mode 2 → 等待您说'执行' → 自动进入 Mode 3-5"
echo ""
echo "💡 提示:"
echo "  • 任何肯定回复（'开始','好的','OK'等）都会触发实现"
echo "  • 无需记住特殊命令，自然表达即可"
echo "  • 如要调整规划，说'改一下'或'重新规划'"
echo ""
