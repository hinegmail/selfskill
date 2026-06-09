<#
.SYNOPSIS
    ProjectOrchestrator initialization script (Windows PowerShell)

.DESCRIPTION
    Creates .ai/ directory structure in target project and installs IDE adapters.

.PARAMETER Path
    Target project path. Default: current directory.

.PARAMETER IDE
    IDE adapters to install, comma-separated.
    Options: cursor, cursor-legacy, cline, windsurf, claude, gemini, agents, all
    Default: all

.PARAMETER Lite
    Enable lite mode (only 5 core .ai/ files).

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
if ($Lite) { $modeLabel = "Lite" }

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

# Core files (both Lite and Full)
$coreFiles = @("requirements.md", "DESIGN.md", "TASKS.md", "STATUS.md", "NEXT.md", "STEERING.md")

# Full mode extra files
$fullFiles = @("RULES.md", "TEST_LOG.md", "DECISIONS.md", "LESSONS.md", "EVOLUTION_PROPOSALS.md")

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

foreach ($file in $coreFiles) {
    Copy-TemplateFile $file
}

if (-not $Lite) {
    foreach ($file in $fullFiles) {
        Copy-TemplateFile $file
    }
}

# ============================================================
# Install IDE adapters
# ============================================================

Write-Host ""
Write-Host "[AI] Installing IDE adapters" -ForegroundColor Cyan

if ($IDE -eq "all") {
    $ideList = @("cursor", "cline", "windsurf", "claude", "gemini", "agents", "antigravity")
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
# Done
# ============================================================

Write-Host ""
Write-Host "[OK] Initialization complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Edit .ai/requirements.md - fill in product requirements" -ForegroundColor White
Write-Host "  2. Edit .ai/DESIGN.md - fill in technical design" -ForegroundColor White
Write-Host "  3. Edit .ai/TASKS.md  - fill in task list" -ForegroundColor White
Write-Host "  4. Edit .ai/NEXT.md   - set the first active task" -ForegroundColor White
Write-Host "  5. In your AI IDE, start a new conversation with:" -ForegroundColor White
Write-Host ""
Write-Host '  "Enter Context Audit mode. Read all .ai/ files and output audit report."' -ForegroundColor Yellow
Write-Host ""
