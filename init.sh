#!/usr/bin/env bash
#
# ProjectOrchestrator 一键初始化脚本 (macOS / Linux)
#
# 用法:
#   ./init.sh [OPTIONS]
#
# 选项:
#   -p, --path PATH       目标项目路径 (默认: 当前目录)
#   -i, --ide IDES        IDE列表, 逗号分隔 (默认: auto)
#                          可选: auto, cursor, cursor-legacy, cline, windsurf, claude, gemini, agents, antigravity, kiro, all
#                          auto = 自动检测目标项目中已有的 IDE 配置目录
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
IDE_LIST="auto"
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
ALWAYS_FILES=("MODE_REFERENCE.md" "README.md")

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

# 总是安装 MODE_REFERENCE.md (compact 适配器依赖它) — 强制覆盖
# MODE_REFERENCE.md 是生成的技能模板（非项目数据），必须始终保持同步
for file in "${ALWAYS_FILES[@]}"; do
    if [[ -f "$TEMPLATES_DIR/$file" ]]; then
        if [[ -f "$AI_DIR/$file" ]]; then
            cp "$TEMPLATES_DIR/$file" "$AI_DIR/$file"
            echo "  *️⃣  .ai/$file (updated)"
        else
            cp "$TEMPLATES_DIR/$file" "$AI_DIR/$file"
            echo "  ✅ .ai/$file"
        fi
    else
        echo "  ⚠️  模板不存在: $file"
    fi
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
# Auto-fill RULES.md placeholders from design.md
# ============================================================

RULES_PATH="$AI_DIR/RULES.md"
if [[ -f "$RULES_PATH" && "$MICRO_MODE" = false ]]; then
    # Check if placeholders exist
    if grep -qE '\{auth_middleware_name\}|\{语言 1\}|\{spaces / tabs\}' "$RULES_PATH"; then
        # Read design.md for tech stack inference (try lowercase then uppercase)
        DESIGN_CONTENT=""
        if [[ -f "$AI_DIR/design.md" ]]; then
            DESIGN_CONTENT=$(cat "$AI_DIR/design.md")
        elif [[ -f "$AI_DIR/DESIGN.md" ]]; then
            DESIGN_CONTENT=$(cat "$AI_DIR/DESIGN.md")
        fi

        # Heuristic: detect primary language from design content
        LANG_NAME="Python"; STYLE="PEP 8 + mypy 类型检查"; INDENT="4 spaces"
        if echo "$DESIGN_CONTENT" | grep -qE "TypeScript|React|Vue|Angular"; then
            LANG_NAME="TypeScript"; STYLE="ESLint + Prettier"; INDENT="2 spaces"
        elif echo "$DESIGN_CONTENT" | grep -qE "Go\b|Golang"; then
            LANG_NAME="Go"; STYLE="gofmt + go vet"; INDENT="tabs"
        elif echo "$DESIGN_CONTENT" | grep -q "Rust"; then
            LANG_NAME="Rust"; STYLE="rustfmt + clippy"; INDENT="4 spaces"
        elif echo "$DESIGN_CONTENT" | grep -qE "Java|Spring"; then
            LANG_NAME="Java"; STYLE="Google Java Style + Checkstyle"; INDENT="4 spaces"
        fi

        # Heuristic: detect auth middleware from design content
        AUTH_MW="无（基于 user_id 隔离）"
        if echo "$DESIGN_CONTENT" | grep -qE "JWT|json.web.token"; then
            AUTH_MW="JWT"
        elif echo "$DESIGN_CONTENT" | grep -q "OAuth"; then
            AUTH_MW="OAuth 2.0"
        elif echo "$DESIGN_CONTENT" | grep -qE "Session|session.based"; then
            AUTH_MW="Session"
        fi

        # Perform replacements (use temp file for macOS compatibility)
        sed \
            -e "s/{auth_middleware_name}/$(printf '%s' "$AUTH_MW" | sed 's/[&/\]/\\&/g')/g" \
            -e "s/{语言 1}/$(printf '%s' "$LANG_NAME" | sed 's/[&/\]/\\&/g')/g" \
            -e "s/{风格指南，如 PEP 8 \/ ESLint + Prettier}/$(printf '%s' "$STYLE" | sed 's/[&/\]/\\&/g')/g" \
            -e "s/{spaces \/ tabs}/$(printf '%s' "$INDENT" | sed 's/[&/\]/\\&/g')/g" \
            -e "s/{e.g., 120}/120/g" \
            "$RULES_PATH" > "$RULES_PATH.tmp" && mv "$RULES_PATH.tmp" "$RULES_PATH"

        echo "  ✅ RULES.md placeholders auto-filled (lang=$LANG_NAME, auth=$AUTH_MW)"
    fi
fi

# ============================================================
# 安装 IDE 适配器
# ============================================================

echo ""
echo "🔌 安装 IDE 适配器"

# All selectable IDE names (order matters for menu numbering)
IDE_NAMES=("cursor" "cursor-legacy" "cline" "windsurf" "claude" "gemini" "agents" "antigravity" "kiro")

if [[ "$IDE_LIST" = "auto" || "$IDE_LIST" = "all" ]]; then
    # Detect which IDEs already have config directories/files in the target project
    declare -A IDE_DETECT_MAP=(
        ["cursor"]=".cursor"
        ["cursor-legacy"]=".cursorrules"
        ["cline"]=".clinerules"
        ["windsurf"]=".windsurfrules"
        ["gemini"]=".gemini"
        ["claude"]="CLAUDE.md"
        ["agents"]="AGENTS.md"
        ["antigravity"]="$TARGET_PATH/.agents/skills/project-orchestrator/SKILL.md"
        ["kiro"]="KIRO_AGENT.md"
    )
    DETECTED_IDES=()
    for name in "${IDE_NAMES[@]}"; do
        check_path="$TARGET_PATH/${IDE_DETECT_MAP[$name]}"
        if [[ -e "$check_path" ]]; then
            DETECTED_IDES+=("$name")
        fi
    done

    # If user explicitly passed --ide all, skip the menu and install everything
    if [[ "$IDE_LIST" = "all" ]]; then
        IDES=("${IDE_NAMES[@]}")
    else
        # Interactive multi-select menu
        echo ""
        echo "  Select IDE adapters to install:"
        echo "  (Enter numbers separated by commas/space, e.g. 1,3,5 — or 'all' — or press Enter for detected only)"
        echo ""
        for i in "${!IDE_NAMES[@]}"; do
            n=$((i + 1))
            name="${IDE_NAMES[$i]}"
            marker=""
            color="\033[37m" # Gray
            for det in "${DETECTED_IDES[@]}"; do
                if [[ "$det" == "$name" ]]; then
                    marker=" ✓ (detected)"
                    color="\033[32m" # Green
                    break
                fi
            done
            echo -e "  [$n] $name$marker" "$color"
        done
        echo -e "\033[0m"
        echo ""
        
        read -p "  Choice: " IDE_INPUT
        IDE_INPUT=$(echo "$IDE_INPUT" | xargs)
        
        if [[ -z "$IDE_INPUT" ]]; then
            # Default: detected IDEs only (or all if none detected)
            if [[ ${#DETECTED_IDES[@]} -gt 0 ]]; then
                IDES=("${DETECTED_IDES[@]}")
            else
                echo "  No IDE detected. Installing all adapters."
                IDES=("${IDE_NAMES[@]}")
            fi
        elif [[ "$IDE_INPUT" = "all" ]]; then
            IDES=("${IDE_NAMES[@]}")
        else
            # Parse number selections
            IDES=()
            # Split by comma or space
            IFS=', ' read -ra NUMS <<< "$IDE_INPUT"
            for n in "${NUMS[@]}"; do
                if [[ "$n" =~ ^[0-9]+$ ]]; then
                    idx=$((n - 1))
                    if [[ $idx -ge 0 && $idx -lt ${#IDE_NAMES[@]} ]]; then
                        IDES+=("${IDE_NAMES[$idx]}")
                    fi
                fi
            done
            if [[ ${#IDES[@]} -eq 0 ]]; then
                echo "  No valid selection. Installing detected IDEs only."
                if [[ ${#DETECTED_IDES[@]} -gt 0 ]]; then
                    IDES=("${DETECTED_IDES[@]}")
                else
                    IDES=("${IDE_NAMES[@]}")
                fi
            fi
        fi
    fi
else
    # User explicitly specified IDE list
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

INSTALLED_ADAPTERS=""
for ide in "${IDES[@]}"; do
    ide=$(echo "$ide" | xargs) # trim whitespace
    case "$ide" in
        cursor)
            install_adapter "$ADAPTERS_DIR/cursor.mdc" "$TARGET_PATH/.cursor/rules/project-orchestrator.mdc" ".cursor/rules/project-orchestrator.mdc"
            INSTALLED_ADAPTERS="$INSTALLED_ADAPTERS cursor"
            ;;
        cursor-legacy)
            install_adapter "$ADAPTERS_DIR/cursorrules" "$TARGET_PATH/.cursorrules" ".cursorrules"
            INSTALLED_ADAPTERS="$INSTALLED_ADAPTERS cursor-legacy"
            ;;
        cline)
            install_adapter "$ADAPTERS_DIR/clinerules.md" "$TARGET_PATH/.clinerules/project-orchestrator.md" ".clinerules/project-orchestrator.md"
            INSTALLED_ADAPTERS="$INSTALLED_ADAPTERS cline"
            ;;
        windsurf)
            install_adapter "$ADAPTERS_DIR/windsurfrules.md" "$TARGET_PATH/.windsurfrules" ".windsurfrules"
            INSTALLED_ADAPTERS="$INSTALLED_ADAPTERS windsurf"
            ;;
        claude)
            install_adapter "$ADAPTERS_DIR/CLAUDE.md" "$TARGET_PATH/CLAUDE.md" "CLAUDE.md"
            INSTALLED_ADAPTERS="$INSTALLED_ADAPTERS claude"
            ;;
        gemini)
            install_adapter "$ADAPTERS_DIR/gemini_styleguide.md" "$TARGET_PATH/.gemini/styleguide.md" ".gemini/styleguide.md"
            INSTALLED_ADAPTERS="$INSTALLED_ADAPTERS gemini"
            ;;
        agents)
            install_adapter "$ADAPTERS_DIR/AGENTS.md" "$TARGET_PATH/AGENTS.md" "AGENTS.md"
            INSTALLED_ADAPTERS="$INSTALLED_ADAPTERS agents"
            ;;
        antigravity)
            install_adapter "$ADAPTERS_DIR/ANTIGRAVITY.md" "$TARGET_PATH/.agents/skills/project-orchestrator/SKILL.md" ".agents/skills/project-orchestrator/SKILL.md"
            INSTALLED_ADAPTERS="$INSTALLED_ADAPTERS antigravity"
            ;;
        kiro)
            install_adapter "$ADAPTERS_DIR/KIRO_AGENT.md" "$TARGET_PATH/KIRO_AGENT.md" "KIRO_AGENT.md"
            INSTALLED_ADAPTERS="$INSTALLED_ADAPTERS kiro"
            ;;
        *)
            echo "  ⚠️  未知 IDE: $ide"
            ;;
    esac
done
INSTALLED_ADAPTERS=$(echo "$INSTALLED_ADAPTERS" | xargs)

# Clean up adapters that exist in target but were NOT selected this run
# Only in auto mode (interactive menu) — not when user explicitly passed --ide
if [[ "$IDE_LIST" = "auto" ]]; then
    # Map: IDE name -> adapter destination path
    declare -A CLEANUP_MAP=(
        ["cursor"]="$TARGET_PATH/.cursor/rules/project-orchestrator.mdc"
        ["cursor-legacy"]="$TARGET_PATH/.cursorrules"
        ["cline"]="$TARGET_PATH/.clinerules/project-orchestrator.md"
        ["windsurf"]="$TARGET_PATH/.windsurfrules"
        ["claude"]="$TARGET_PATH/CLAUDE.md"
        ["gemini"]="$TARGET_PATH/.gemini/styleguide.md"
        ["agents"]="$TARGET_PATH/AGENTS.md"
        ["antigravity"]="$TARGET_PATH/.agents/skills/project-orchestrator/SKILL.md"
        ["kiro"]="$TARGET_PATH/KIRO_AGENT.md"
    )
    for clean_key in "${!CLEANUP_MAP[@]}"; do
        # Check if this key was installed
        is_installed=false
        for inst in $INSTALLED_ADAPTERS; do
            if [[ "$inst" == "$clean_key" ]]; then
                is_installed=true
                break
            fi
        done
        if [[ "$is_installed" = false ]]; then
            clean_dst="${CLEANUP_MAP[$clean_key]}"
            if [[ -f "$clean_dst" ]]; then
                # Only remove if it's a ProjectOrchestrator adapter (by content or filename)
                if grep -qE "ProjectOrchestrator" "$clean_dst" 2>/dev/null || \
                   echo "$clean_dst" | grep -qE "project-orchestrator"; then
                    rm -f "$clean_dst"
                    echo "  ➖ $clean_dst (removed — not selected)"
                fi
            fi
        fi
    done
    # Also clean up legacy ANTIGRAVITY.md (old install path, now moved to .agents/skills/)
    legacy_antigravity="$TARGET_PATH/ANTIGRAVITY.md"
    if [[ -f "$legacy_antigravity" ]]; then
        if grep -qE "ProjectOrchestrator" "$legacy_antigravity" 2>/dev/null; then
            rm -f "$legacy_antigravity"
            echo "  ➖ ANTIGRAVITY.md (removed — legacy path, migrated to .agents/skills/)"
        fi
    fi
    # Clean up empty IDE config directories left behind
    for clean_dir in "$TARGET_PATH/.cursor/rules" "$TARGET_PATH/.cursor" "$TARGET_PATH/.clinerules" "$TARGET_PATH/.gemini" \
                     "$TARGET_PATH/.agents/skills/project-orchestrator" "$TARGET_PATH/.agents/skills" "$TARGET_PATH/.agents"; do
        if [[ -d "$clean_dir" ]]; then
            if [[ -z "$(find "$clean_dir" -type f 2>/dev/null)" ]]; then
                rm -rf "$clean_dir"
                echo "  ➖ $clean_dir/ (removed — empty directory)"
            fi
        fi
    done
fi

# ============================================================
# Post-init: Detect unpopulated template files
# ============================================================

REQ_FILE="$AI_DIR/requirements.md"
DESIGN_FILE="$AI_DIR/DESIGN.md"
TASKS_FILE="$AI_DIR/TASKS.md"
STATUS_FILE="$AI_DIR/STATUS.md"
STEERING_FILE="$AI_DIR/STEERING.md"

has_real_req=false
has_real_design=false
has_real_tasks=false
status_is_template=false
steering_is_template=false

# Template detection patterns (same logic as init.ps1):
# - "# 项目名称 -" appears in all three source template H1 headings
# - "{待" appears in STATUS.md and STEERING.md templates
# - "预计总周期" appears in TASKS.md template
# - "[简述" appears in requirements.md and DESIGN.md templates
# - "[如 " appears in DESIGN.md template
if [[ -f "$REQ_FILE" ]] && ! grep -qE '\{待|# 项目名称 -|\[简述' "$REQ_FILE" 2>/dev/null; then
    has_real_req=true
fi
if [[ -f "$DESIGN_FILE" ]] && ! grep -qE '\{待|# 项目名称 -|\[简述|\[如 ' "$DESIGN_FILE" 2>/dev/null; then
    has_real_design=true
fi
if [[ -f "$TASKS_FILE" ]] && ! grep -qE '# 项目名称 -|预计总周期' "$TASKS_FILE" 2>/dev/null; then
    has_real_tasks=true
fi
if [[ -f "$STATUS_FILE" ]] && grep -qE '\{待|0 / 0 任务' "$STATUS_FILE" 2>/dev/null; then
    status_is_template=true
fi
if [[ -f "$STEERING_FILE" ]] && grep -qE '\{待填写\}|\{项目名称\}|\{待提取\}' "$STEERING_FILE" 2>/dev/null; then
    steering_is_template=true
fi

# All three source docs must have real content to use auto-extraction.
all_sources_real=false
if [[ "$has_real_req" = true && "$has_real_design" = true && "$has_real_tasks" = true ]]; then
    all_sources_real=true
fi

if [[ "$all_sources_real" = true ]] && { [[ "$status_is_template" = true ]] || [[ "$steering_is_template" = true ]]; }; then
    echo ""
    echo "⚠️ [Template Placeholder Detected]"
    echo "  Source documents (requirements.md, DESIGN.md, TASKS.md) have real content,"
    echo "  but STATUS.md and/or STEERING.md are still template placeholders."
    echo ""
    echo "📋 Copy this command to your AI assistant:"
    echo ""
    echo "  执行 Mode 0 初始化：检测到 STATUS.md 和 STEERING.md 仍是模板占位符。"
    echo "  请从 requirements.md、DESIGN.md 和 TASKS.md 提取真实内容，填充："
    echo "  1. STEERING.md — 提取项目名称、核心价值、技术栈、架构模块、里程碑"
    echo "  2. STATUS.md — 填充 TL;DR、项目进度、里程碑执行状态、当前活跃任务"
    echo "  3. NEXT.md — 从 TASKS.md 找第一个未完成任务 [ ]，修正文件路径"
    echo "  完成后输出初始化报告。"
    echo ""
elif [[ "$all_sources_real" = false ]] && { [[ "$status_is_template" = true ]] || [[ "$steering_is_template" = true ]]; }; then
    echo ""
    echo "⚠️ [Template Placeholder Detected]"
    echo "  Source documents (requirements.md, DESIGN.md, TASKS.md) are still templates."
    echo "  Runtime files (STATUS.md, STEERING.md) are also templates."
    echo ""
    echo "📋 Copy this command to your AI assistant:"
    echo ""
    echo "  启动项目"
    echo ""
    echo "  (触发 Mode 0 交互式初始化向导，AI 将询问 3 个问题后"
    echo "   自动生成 requirements.md、DESIGN.md、TASKS.md，"
    echo "   再填充 STEERING.md、STATUS.md、NEXT.md)"
    echo ""
elif [[ "$status_is_template" = true || "$steering_is_template" = true ]]; then
    echo ""
    echo "⚠️ STATUS.md/STEERING.md contain template placeholders."
    echo "  In your IDE, say: 启动项目  (to launch the Interactive Setup Wizard)"
    echo ""
fi

# ============================================================
# 完成
# ============================================================

echo ""
echo "✨ 初始化完成！"
echo ""
echo "ProjectOrchestrator Skill v1.1: 7-Mode自动化运作流程"
echo ""
echo "├─ MODE 1: Context Audit        (加载项目状态)"
echo "├─ MODE 2: One-Card Gate         (单卡开工契约，批准后冻结)"
echo "├─ MODE 3: Implementation       (执行编码 → Hard Stop 物理停机)"
echo "├─ MODE 4: Tiered Validation    (分级验证 + 防同谋自验检查)"
echo "├─ MODE 5: Iron Triangle Gate   (铁三角门禁: 代码变更+Exit Code 0+Git Commit)"
echo "├─ MODE 6: Skill Evolution      (提案改进，按需)"
echo "└─ New Conversation             (收口后推荐新开对话，切断上下文污染)"
echo ""
echo "🚀 快速开始 (3步):"
echo ""
echo "  1️⃣  在您的IDE (已安装: $INSTALLED_ADAPTERS) 打开对话"
echo ""
echo "  2️⃣  说这条命令:"
echo ""
echo '      继续项目'
echo ""
echo "  3️⃣  AI会自动执行 Mode 1 → Mode 2 (单卡契约) → 等待您说'执行' → Mode 3 (编码+硬停机) → Mode 4-5"
echo ""
echo "💡 提示:"
echo "  • Mode 2 生成单卡开工契约，批准后验收断言冻结，不可篡改"
echo "  • Mode 3 编码完成后物理硬停机，必须人工确认才进入验证"
echo "  • Mode 5 铁三角门禁: 需 Git Commit + Exit Code 0 才能收口"
echo "  • 如要调整规划，说'改一下'或'重新规划"
echo ""
