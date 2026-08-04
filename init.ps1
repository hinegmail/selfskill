<#
.SYNOPSIS
    ProjectOrchestrator initialization script (Windows PowerShell)

.DESCRIPTION
    Creates .ai/ directory structure in target project and installs IDE adapters.

.PARAMETER Path
    Target project path. Default: current directory.

.PARAMETER IDE
    IDE adapters to install, comma-separated.
    Options: cursor, cursor-legacy, cline, windsurf, claude, gemini, agents, antigravity, kiro, all
    Default: all

.PARAMETER Lite
    Enable lite mode (only 6 core .ai/ files).

.PARAMETER Micro
    Enable micro mode (only 3 core .ai/ files: NEXT.md, STATUS.md, LESSONS.md).

.PARAMETER SkillSource
    SelfSkill project root (containing skill.md, templates/, adapters/).
    Auto-detected by default.

.PARAMETER Force
    Force overwrite existing .ai/ files.

.EXAMPLE
    .\init.ps1 -Path "D:\Projects\MyApp" -IDE "cursor,cline" -Lite
    .\init.ps1 -Path "." -IDE "all" -Force
    .\init.ps1
#>

param(
    [string]$Path = ".",
    [string]$IDE = "all",
    [switch]$Lite,
    [switch]$Micro,
    [string]$SkillSource = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Detect SelfSkill source directory
if (-not $SkillSource) {
    $SkillSource = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$TemplatesDir = Join-Path $SkillSource "templates\ai"
$AdaptersDir = Join-Path $SkillSource "adapters"

# Validate source
if (-not (Test-Path (Join-Path $SkillSource "skill.md"))) {
    Write-Error "ERROR: skill.md not found. Check SkillSource path: $SkillSource"
    exit 1
}

# Resolve target path
$TargetPath = Resolve-Path $Path -ErrorAction SilentlyContinue
if (-not $TargetPath) {
    $TargetPath = $Path
}

$AiDir = Join-Path $TargetPath ".ai"

$modeLabel = "Full"
if ($Micro) { $modeLabel = "Micro" }
elseif ($Lite) { $modeLabel = "Lite" }

Write-Host ""
Write-Host "[AI] ProjectOrchestrator Init" -ForegroundColor Cyan
Write-Host "  Target: $TargetPath" -ForegroundColor Gray
Write-Host "  Mode:   $modeLabel" -ForegroundColor Gray
Write-Host "  IDE:    $IDE" -ForegroundColor Gray
Write-Host ""

# ============================================================
# Create .ai/ directory
# ============================================================

if (-not (Test-Path $AiDir)) {
    New-Item -ItemType Directory -Path $AiDir -Force | Out-Null
    Write-Host "[+] Created .ai/ directory" -ForegroundColor Green
}
else {
    Write-Host "[=] .ai/ directory exists, skipping existing files" -ForegroundColor Yellow
}

# Micro mode: only 3 essential files + MODE_REFERENCE.md
$microFiles = @("NEXT.md", "STATUS.md", "LESSONS.md", "MODE_REFERENCE.md")

# Core files (both Lite and Full)
$coreFiles = @("requirements.md", "DESIGN.md", "TASKS.md", "STATUS.md", "NEXT.md", "STEERING.md")

# Full mode extra files
$fullFiles = @("RULES.md", "TEST_LOG.md", "DECISIONS.md", "LESSONS.md", "EVOLUTION_PROPOSALS.md")

# MODE_REFERENCE.md is always installed (needed by compact adapters)
$alwaysFiles = @("MODE_REFERENCE.md")

# 复制模板文件函数，如果指定了 -Force 则强制覆盖已存在的文件
function Copy-TemplateFile {
    param([string]$FileName)
    $src = Join-Path $TemplatesDir $FileName
    $dst = Join-Path $AiDir $FileName
    $exists = Test-Path $dst
    if ($Force -or -not $exists) {
        if (Test-Path $src) {
            Copy-Item $src $dst -Force
            if ($exists) {
                Write-Host "  [*] .ai/$FileName (overwritten)" -ForegroundColor Green
            } else {
                Write-Host "  [+] .ai/$FileName" -ForegroundColor Green
            }
        }
        else {
            Write-Host "  [!] Template missing: $FileName" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  [=] .ai/$FileName (exists, skipped)" -ForegroundColor DarkGray
    }
}

# Always install MODE_REFERENCE.md (compact adapters reference it) — force overwrite
# MODE_REFERENCE.md is a generated skill template (not project data), must always stay in sync
foreach ($file in $alwaysFiles) {
    $src = Join-Path $TemplatesDir $file
    $dst = Join-Path $AiDir $file
    if (Test-Path $src) {
        $exists = Test-Path $dst
        Copy-Item $src $dst -Force
        if ($exists) {
            Write-Host "  [*] .ai/$file (updated)" -ForegroundColor Green
        } else {
            Write-Host "  [+] .ai/$file" -ForegroundColor Green
        }
    }
    else {
        Write-Host "  [!] Template missing: $file" -ForegroundColor Yellow
    }
}

if ($Micro) {
    # Micro mode: only essential runtime files
    foreach ($file in $microFiles) {
        Copy-TemplateFile $file
    }
}
else {
    foreach ($file in $coreFiles) {
        Copy-TemplateFile $file
    }

    if (-not $Lite) {
        foreach ($file in $fullFiles) {
            Copy-TemplateFile $file
        }
    }
}

# ============================================================
# Install IDE adapters
# ============================================================

Write-Host ""
Write-Host "[AI] Installing IDE adapters" -ForegroundColor Cyan

if ($IDE -eq "all") {
    $ideList = @("cursor", "cline", "windsurf", "claude", "gemini", "agents", "antigravity", "kiro")
}
else {
    $ideList = $IDE -split "," | ForEach-Object { $_.Trim() }
}

# 安装 IDE 适配器函数，适配器（规则文件）在存在时总是强制覆盖更新
function Install-Adapter {
    param([string]$SrcFile, [string]$DstFile, [string]$Label)
    if (Test-Path $SrcFile) {
        $parentDir = Split-Path -Parent $DstFile
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        $exists = Test-Path $DstFile
        Copy-Item $SrcFile $DstFile -Force
        if ($exists) {
            Write-Host "  [*] $Label (updated)" -ForegroundColor Green
        } else {
            Write-Host "  [+] $Label" -ForegroundColor Green
        }
    }
    else {
        Write-Host "  [!] Adapter template missing: $Label" -ForegroundColor Yellow
    }
}

foreach ($ideItem in $ideList) {
    switch ($ideItem.ToLower()) {
        "cursor" {
            $src = Join-Path $AdaptersDir "cursor.mdc"
            $dst = Join-Path $TargetPath ".cursor\rules\project-orchestrator.mdc"
            Install-Adapter $src $dst ".cursor/rules/project-orchestrator.mdc"
        }
        "cursor-legacy" {
            $src = Join-Path $AdaptersDir "cursorrules"
            $dst = Join-Path $TargetPath ".cursorrules"
            Install-Adapter $src $dst ".cursorrules"
        }
        "cline" {
            $src = Join-Path $AdaptersDir "clinerules.md"
            $dst = Join-Path $TargetPath ".clinerules\project-orchestrator.md"
            Install-Adapter $src $dst ".clinerules/project-orchestrator.md"
        }
        "windsurf" {
            $src = Join-Path $AdaptersDir "windsurfrules.md"
            $dst = Join-Path $TargetPath ".windsurfrules"
            Install-Adapter $src $dst ".windsurfrules"
        }
        "claude" {
            $src = Join-Path $AdaptersDir "CLAUDE.md"
            $dst = Join-Path $TargetPath "CLAUDE.md"
            Install-Adapter $src $dst "CLAUDE.md"
        }
        "gemini" {
            $src = Join-Path $AdaptersDir "gemini_styleguide.md"
            $dst = Join-Path $TargetPath ".gemini\styleguide.md"
            Install-Adapter $src $dst ".gemini/styleguide.md"
        }
        "agents" {
            $src = Join-Path $AdaptersDir "AGENTS.md"
            $dst = Join-Path $TargetPath "AGENTS.md"
            Install-Adapter $src $dst "AGENTS.md"
        }
        "antigravity" {
            $src = Join-Path $AdaptersDir "ANTIGRAVITY.md"
            $dst = Join-Path $TargetPath "ANTIGRAVITY.md"
            Install-Adapter $src $dst "ANTIGRAVITY.md"
        }
        "kiro" {
            $src = Join-Path $AdaptersDir "KIRO_AGENT.md"
            $dst = Join-Path $TargetPath "KIRO_AGENT.md"
            Install-Adapter $src $dst "KIRO_AGENT.md"
        }
        default {
            Write-Host "  [!] Unknown IDE: $ideItem" -ForegroundColor Yellow
        }
    }
}

# ============================================================
# Post-init: Detect unpopulated template files
# ============================================================

# Check if source documents have real content (not just templates)
# All three template files share the H1 pattern: "# 项目名称 - <type>"
# This is the strongest indicator that a file is an unfilled template
$reqFile = Join-Path $AiDir "requirements.md"
$designFile = Join-Path $AiDir "DESIGN.md"
$tasksFile = Join-Path $AiDir "TASKS.md"
$statusFile = Join-Path $AiDir "STATUS.md"
$steeringFile = Join-Path $AiDir "STEERING.md"

# Template detection patterns:
# - "# 项目名称 -" appears in all three source template H1 headings (real projects use actual names)
# - "{待" appears in STATUS.md and STEERING.md templates
# - "预计总周期" appears in TASKS.md template
# - "[简述" appears in requirements.md and DESIGN.md templates
# - "[如 " appears in DESIGN.md template
$reqTemplatePattern = '\{待|# 项目名称 -|\[简述'
$designTemplatePattern = '\{待|# 项目名称 -|\[简述|\[如 '
$tasksTemplatePattern = '# 项目名称 -|预计总周期'

$hasRealRequirements = (Test-Path $reqFile) -and -not ((Get-Content $reqFile -Raw -ErrorAction SilentlyContinue) -match $reqTemplatePattern)
$hasRealDesign = (Test-Path $designFile) -and -not ((Get-Content $designFile -Raw -ErrorAction SilentlyContinue) -match $designTemplatePattern)
$hasRealTasks = (Test-Path $tasksFile) -and -not ((Get-Content $tasksFile -Raw -ErrorAction SilentlyContinue) -match $tasksTemplatePattern)
$statusIsTemplate = (Test-Path $statusFile) -and ((Get-Content $statusFile -Raw -ErrorAction SilentlyContinue) -match '\{待|0 / 0 任务')
$steeringIsTemplate = (Test-Path $steeringFile) -and ((Get-Content $steeringFile -Raw -ErrorAction SilentlyContinue) -match '\{待填写\}|\{项目名称\}|\{待提取\}')

# All three source docs must have real content to use auto-extraction.
# If ANY source doc is a template, the Interactive Setup Wizard must be launched instead.
$allSourcesReal = $hasRealRequirements -and $hasRealDesign -and $hasRealTasks
$anySourceTemplate = -not $allSourcesReal

if ($allSourcesReal -and ($statusIsTemplate -or $steeringIsTemplate)) {
    Write-Host ""
    Write-Host "⚠️ [Template Placeholder Detected]" -ForegroundColor Yellow
    Write-Host "  Source documents (requirements.md, DESIGN.md, TASKS.md) have real content," -ForegroundColor Yellow
    Write-Host "  but STATUS.md and/or STEERING.md are still template placeholders." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📋 Copy the following command and send it to your AI assistant:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "  │ 执行 Mode 0 初始化：检测到 STATUS.md 和 STEERING.md 仍是模板占位符。 │" -ForegroundColor White
    Write-Host "  │ 请从 requirements.md、DESIGN.md 和 TASKS.md 提取真实内容，填充：     │" -ForegroundColor White
    Write-Host "  │ 1. STEERING.md — 提取项目名称、核心价值、技术栈、架构模块、里程碑    │" -ForegroundColor White
    Write-Host "  │ 2. STATUS.md — 填充 TL;DR、项目进度、里程碑执行状态、当前活跃任务     │" -ForegroundColor White
    Write-Host "  │ 3. NEXT.md — 从 TASKS.md 找第一个未完成任务 [ ]，修正文件路径        │" -ForegroundColor White
    Write-Host "  │ 完成后输出初始化报告。                                               │" -ForegroundColor White
    Write-Host "  └─────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
}
elseif ($anySourceTemplate -and ($statusIsTemplate -or $steeringIsTemplate)) {
    Write-Host ""
    Write-Host "⚠️ [Template Placeholder Detected]" -ForegroundColor Yellow
    Write-Host "  Source documents (requirements.md, DESIGN.md, TASKS.md) are still templates." -ForegroundColor Yellow
    Write-Host "  Runtime files (STATUS.md, STEERING.md) are also templates." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📋 Copy the following command and send it to your AI assistant:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "  │ 启动项目                                                             │" -ForegroundColor White
    Write-Host "  │                                                                       │" -ForegroundColor White
    Write-Host "  │ (触发 Mode 0 交互式初始化向导，AI 将询问 3 个问题后                   │" -ForegroundColor DarkGray
    Write-Host "  │  自动生成 requirements.md、DESIGN.md、TASKS.md，                     │" -ForegroundColor DarkGray
    Write-Host "  │  再填充 STEERING.md、STATUS.md、NEXT.md)                              │" -ForegroundColor DarkGray
    Write-Host "  └─────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
}
elseif ($statusIsTemplate -or $steeringIsTemplate) {
    Write-Host ""
    Write-Host "⚠️ STATUS.md/STEERING.md contain template placeholders." -ForegroundColor Yellow
    Write-Host "  In your IDE, say: 启动项目  (to launch the Interactive Setup Wizard)" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================
# Done
# ============================================================

Write-Host ""
Write-Host "[OK] Initialization complete!" -ForegroundColor Green
Write-Host ""
Write-Host "ProjectOrchestrator Skill: 7-Mode自动化运作流程" -ForegroundColor Cyan
Write-Host ""
Write-Host "├─ MODE 1: Context Audit        (加载项目状态)" -ForegroundColor Gray
Write-Host "├─ MODE 2: Task Planning        (规划当前任务，自动)" -ForegroundColor Gray
Write-Host "├─ MODE 3: Implementation       (执行编码，您说'执行'→自动启动)" -ForegroundColor Yellow
Write-Host "├─ MODE 4: Validation & Test    (运行测试，自动)" -ForegroundColor Gray
Write-Host "├─ MODE 5: Phase Closeout       (更新.ai/文件，自动 ✅)" -ForegroundColor Green
Write-Host "├─ MODE 6: Skill Evolution      (提案改进，按需)" -ForegroundColor Gray
Write-Host "└─ New Conversation             (收口后推荐新开对话，切断上下文污染)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "🚀 快速开始 (3步):" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1️⃣  在您的IDE (Cursor/Cline/Windsurf/Claude/Kiro等) 打开对话" -ForegroundColor White
Write-Host ""
Write-Host "  2️⃣  说这条命令:" -ForegroundColor White
Write-Host ""
Write-Host '      继续项目' -ForegroundColor Yellow
Write-Host ""
Write-Host "  3️⃣  AI会自动执行 Mode 1 → Mode 2 → 等待您说'执行' → 自动进入 Mode 3-5" -ForegroundColor White
Write-Host ""
Write-Host "💡 提示:" -ForegroundColor Green
Write-Host "  • 任何肯定回复（'开始','好的','OK'等）都会触发实现" -ForegroundColor DarkGray
Write-Host "  • 无需记住特殊命令，自然表达即可" -ForegroundColor DarkGray
Write-Host "  • 如要调整规划，说'改一下'或'重新规划'" -ForegroundColor DarkGray
Write-Host ""
