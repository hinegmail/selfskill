<#
.SYNOPSIS
    ProjectOrchestrator initialization script (Windows PowerShell)

.DESCRIPTION
    Creates .ai/ directory structure in target project and installs IDE adapters.

.PARAMETER Path
    Target project path. Default: current directory.

.PARAMETER IDE
    IDE adapters to install. Default: auto (detect existing IDE configs in target project).
    Options: auto, cursor, cursor-legacy, cline, windsurf, claude, gemini, agents, antigravity, kiro, all

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
    [string]$IDE = "auto",
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
# Auto-fill RULES.md placeholders from design.md
# ============================================================

$rulesPath = Join-Path $AiDir "RULES.md"
if ((Test-Path $rulesPath) -and -not $Micro) {
    $rulesContent = Get-Content $rulesPath -Raw -Encoding UTF8

    # Check if placeholders exist
    $hasPlaceholders = $rulesContent -match '\{auth_middleware_name\}' -or $rulesContent -match '\{语言 1\}' -or $rulesContent -match '\{spaces / tabs\}'
    if ($hasPlaceholders) {
        # Read design.md for tech stack inference
        $designPath = Join-Path $AiDir "design.md"
        $designContent = ""
        if (Test-Path $designPath) {
            $designContent = Get-Content $designPath -Raw -Encoding UTF8
        }
        # Also check DESIGN.md (uppercase)
        if ([string]::IsNullOrEmpty($designContent)) {
            $designPathUpper = Join-Path $AiDir "DESIGN.md"
            if (Test-Path $designPathUpper) {
                $designContent = Get-Content $designPathUpper -Raw -Encoding UTF8
            }
        }

        # Heuristic: detect primary language from design content
        $lang = "Python"; $style = "PEP 8 + mypy 类型检查"; $indent = "4 spaces"
        if ($designContent -match "TypeScript|React|Vue|Angular") {
            $lang = "TypeScript"; $style = "ESLint + Prettier"; $indent = "2 spaces"
        } elseif ($designContent -match "(?m)\bGo\b|Golang") {
            $lang = "Go"; $style = "gofmt + go vet"; $indent = "tabs"
        } elseif ($designContent -match "Rust") {
            $lang = "Rust"; $style = "rustfmt + clippy"; $indent = "4 spaces"
        } elseif ($designContent -match "Java|Spring") {
            $lang = "Java"; $style = "Google Java Style + Checkstyle"; $indent = "4 spaces"
        }

        # Heuristic: detect auth middleware from design content
        $authMiddleware = "无（基于 user_id 隔离）"
        if ($designContent -match "JWT|json.web.token") {
            $authMiddleware = "JWT"
        } elseif ($designContent -match "OAuth") {
            $authMiddleware = "OAuth 2.0"
        } elseif ($designContent -match "Session|session.based") {
            $authMiddleware = "Session"
        }

        # Perform replacements
        $rulesContent = $rulesContent -replace '\{auth_middleware_name\}', $authMiddleware
        $rulesContent = $rulesContent -replace '\{语言 1\}', $lang
        $rulesContent = $rulesContent -replace '\{风格指南，如 PEP 8 / ESLint \+ Prettier\}', $style
        $rulesContent = $rulesContent -replace '\{spaces / tabs\}', $indent
        $rulesContent = $rulesContent -replace '\{e\.g\., 120\}', '120'

        Set-Content $rulesPath -Value $rulesContent -Encoding UTF8 -NoNewline
        Write-Host "  [+] RULES.md placeholders auto-filled (lang=$lang, auth=$authMiddleware)" -ForegroundColor Green
    }
}

# ============================================================
# Install IDE adapters
# ============================================================

Write-Host ""
Write-Host "[AI] Installing IDE adapters" -ForegroundColor Cyan

# IDE detection map: IDE name -> { configDir, adapterFile, dstPath, label }
$ideConfigs = [ordered]@{
    "cursor"      = @{ Dst = ".cursor\rules\project-orchestrator.mdc";          Src = "cursor.mdc";             Label = ".cursor/rules/project-orchestrator.mdc" }
    "cursor-legacy"= @{ Dst = ".cursorrules";                                        Src = "cursorrules";            Label = ".cursorrules" }
    "cline"       = @{ Dst = ".clinerules\project-orchestrator.md";                Src = "clinerules.md";          Label = ".clinerules/project-orchestrator.md" }
    "windsurf"    = @{ Dst = ".windsurfrules";                                     Src = "windsurfrules.md";        Label = ".windsurfrules" }
    "claude"      = @{ Dst = "CLAUDE.md";                                           Src = "CLAUDE.md";              Label = "CLAUDE.md" }
    "gemini"      = @{ Dst = ".gemini\styleguide.md";                              Src = "gemini_styleguide.md";   Label = ".gemini/styleguide.md" }
    "agents"      = @{ Dst = "AGENTS.md";                                           Src = "AGENTS.md";              Label = "AGENTS.md" }
    "antigravity" = @{ Dst = "ANTIGRAVITY.md";                                     Src = "ANTIGRAVITY.md";         Label = "ANTIGRAVITY.md" }
    "kiro"        = @{ Dst = "KIRO_AGENT.md";                                      Src = "KIRO_AGENT.md";          Label = "KIRO_AGENT.md" }
}

# Detect which IDEs already have config directories in the target project
# This helps "auto" mode install only relevant adapters
$ideDetectMap = [ordered]@{
    "cursor"      = ".cursor"
    "cursor-legacy" = ".cursorrules"
    "cline"       = ".clinerules"
    "windsurf"    = ".windsurfrules"
    "gemini"      = ".gemini"
}

# All selectable IDE names (order matters for menu numbering)
$ideNames = @("cursor", "cursor-legacy", "cline", "windsurf", "claude", "gemini", "agents", "antigravity", "kiro")

if ($IDE -eq "auto" -or $IDE -eq "all") {
    # Detect which IDEs already have config directories in the target project
    $ideDetectMap = @{
        "cursor"        = ".cursor"
        "cursor-legacy" = ".cursorrules"
        "cline"         = ".clinerules"
        "windsurf"      = ".windsurfrules"
        "gemini"        = ".gemini"
        "claude"        = "CLAUDE.md"
        "agents"        = "AGENTS.md"
        "antigravity"   = "ANTIGRAVITY.md"
        "kiro"          = "KIRO_AGENT.md"
    }
    $detectedIdes = @()
    foreach ($name in $ideNames) {
        $checkPath = Join-Path $TargetPath $ideDetectMap[$name]
        if (Test-Path $checkPath) {
            $detectedIdes += $name
        }
    }

    # If user explicitly passed -IDE all, skip the menu and install everything
    if ($IDE -eq "all") {
        $ideList = $ideNames
    }
    else {
        # Interactive multi-select menu
        Write-Host ""
        Write-Host "  Select IDE adapters to install:" -ForegroundColor Cyan
        Write-Host "  (Enter numbers separated by commas/space, e.g. 1,3,5 — or 'all' — or press Enter for detected only)" -ForegroundColor DarkGray
        Write-Host ""
        for ($i = 0; $i -lt $ideNames.Count; $i++) {
            $n = $i + 1
            $name = $ideNames[$i]
            $marker = if ($detectedIdes -contains $name) { " ✓ (detected)" } else { "" }
            $color = if ($detectedIdes -contains $name) { "Green" } else { "Gray" }
            Write-Host "  [$n] $name$marker" -ForegroundColor $color
        }
        Write-Host ""
        
        $ideInput = Read-Host "  Choice"
        $ideInput = $ideInput.Trim()
        
        if ([string]::IsNullOrWhiteSpace($ideInput)) {
            # Default: detected IDEs only (or all if none detected)
            if ($detectedIdes.Count -gt 0) {
                $ideList = $detectedIdes
            } else {
                Write-Host "  No IDE detected. Installing all adapters." -ForegroundColor Yellow
                $ideList = $ideNames
            }
        }
        elseif ($ideInput -eq "all") {
            $ideList = $ideNames
        }
        else {
            # Parse number selections
            $ideList = @()
            $nums = $ideInput -split "[,\s]+" | Where-Object { $_ -match '^\d+$' }
            foreach ($n in $nums) {
                $idx = [int]$n - 1
                if ($idx -ge 0 -and $idx -lt $ideNames.Count) {
                    $ideList += $ideNames[$idx]
                }
            }
            if ($ideList.Count -eq 0) {
                Write-Host "  No valid selection. Installing detected IDEs only." -ForegroundColor Yellow
                $ideList = if ($detectedIdes.Count -gt 0) { $detectedIdes } else { $ideNames }
            }
        }
    }
}
else {
    # User explicitly specified IDE list
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

$installedAdapters = @()
foreach ($ideItem in $ideList) {
    $key = $ideItem.ToLower()
    if ($ideConfigs.Contains($key)) {
        $cfg = $ideConfigs[$key]
        $src = Join-Path $AdaptersDir $cfg.Src
        $dst = Join-Path $TargetPath $cfg.Dst
        Install-Adapter $src $dst $cfg.Label
        $installedAdapters += $key
    }
    else {
        Write-Host "  [!] Unknown IDE: $ideItem" -ForegroundColor Yellow
    }
}

# Clean up adapters that exist in target but were NOT selected this run
# Only in auto mode (interactive menu) — not when user explicitly passed -IDE
if ($IDE -eq "auto") {
    foreach ($key in $ideConfigs.Keys) {
        if ($installedAdapters -notcontains $key) {
            $cfg = $ideConfigs[$key]
            $dst = Join-Path $TargetPath $cfg.Dst
            # Only remove if it's a ProjectOrchestrator adapter
            if (Test-Path $dst) {
                $content = Get-Content $dst -Raw -ErrorAction SilentlyContinue
                # Match by content signature OR by filename pattern
                if ($content -match "ProjectOrchestrator" -or $cfg.Label -match "project-orchestrator") {
                    Remove-Item $dst -Force
                    Write-Host "  [-] $($cfg.Label) (removed — not selected)" -ForegroundColor DarkGray
                }
            }
        }
    }
    # Clean up empty IDE config directories left behind (e.g. .cursor/rules/, .clinerules/, .gemini/)
    $ideDirsToCheck = @(
        ".cursor\rules",
        ".clinerules",
        ".gemini"
    )
    foreach ($dir in $ideDirsToCheck) {
        $dirPath = Join-Path $TargetPath $dir
        if (Test-Path $dirPath) {
            $remaining = Get-ChildItem $dirPath -Recurse -File -ErrorAction SilentlyContinue
            if ($remaining.Count -eq 0) {
                Remove-Item $dirPath -Force -Recurse
                Write-Host "  [-] $dir/ (removed — empty directory)" -ForegroundColor DarkGray
            }
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
Write-Host "ProjectOrchestrator Skill v1.1: 7-Mode自动化运作流程" -ForegroundColor Cyan
Write-Host ""
Write-Host "├─ MODE 1: Context Audit        (加载项目状态)" -ForegroundColor Gray
Write-Host "├─ MODE 2: One-Card Gate         (单卡开工契约，批准后冻结)" -ForegroundColor Gray
Write-Host "├─ MODE 3: Implementation       (执行编码 → Hard Stop 物理停机)" -ForegroundColor Yellow
Write-Host "├─ MODE 4: Tiered Validation    (分级验证 + 防同谋自验检查)" -ForegroundColor Gray
Write-Host "├─ MODE 5: Iron Triangle Gate   (铁三角门禁: 代码变更+Exit Code 0+Git Commit)" -ForegroundColor Green
Write-Host "├─ MODE 6: Skill Evolution      (提案改进，按需)" -ForegroundColor Gray
Write-Host "└─ New Conversation             (收口后推荐新开对话，切断上下文污染)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "🚀 快速开始 (3步):" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1️⃣  在您的IDE (已安装: $($installedAdapters -join ', ')) 打开对话" -ForegroundColor White
Write-Host ""
Write-Host "  2️⃣  说这条命令:" -ForegroundColor White
Write-Host ""
Write-Host '      继续项目' -ForegroundColor Yellow
Write-Host ""
Write-Host "  3️⃣  AI会自动执行 Mode 1 → Mode 2 (单卡契约) → 等待您说'执行' → Mode 3 (编码+硬停机) → Mode 4-5" -ForegroundColor White
Write-Host ""
Write-Host "💡 提示:" -ForegroundColor Green
Write-Host "  • Mode 2 生成单卡开工契约，批准后验收断言冻结，不可篡改" -ForegroundColor DarkGray
Write-Host "  • Mode 3 编码完成后物理硬停机，必须人工确认才进入验证" -ForegroundColor DarkGray
Write-Host "  • Mode 5 铁三角门禁: 需 Git Commit + Exit Code 0 才能收口" -ForegroundColor DarkGray
Write-Host "  • 如要调整规划，说'改一下'或'重新规划'" -ForegroundColor DarkGray
Write-Host ""
