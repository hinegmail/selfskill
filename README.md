# [简体中文](README_CN.md) | English

# 🧭 ProjectOrchestrator

**A Universal AI Programming Orchestrator Skill with Dual-Track Cognition and Self-Evolution Capabilities**

Transform AI from a "blind code-writing tool" into a highly disciplined, self-learning, and fully auditable project orchestrator. Designed to be compatible with all major AI IDEs and Agentic coding assistants.

---

## ✨ Core Features

| Feature                              | Description                                                                                                                               |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| 🧠**Dual-Track Cognition**     | Runs two cognitive tracks simultaneously: the Execution Track (coding) and the Evolution Track (self-reflection & knowledge persistence). |
| 🚦**`NEXT.md` Hard Gate**    | Restricts coding to a single active task, preventing AI from expanding scope or jumping between tasks.                                    |
| 🔄**Seven-Mode Engine**        | Strict lifecycle flow: Init ➔ Context Audit ➔ Task Planning ➔ Implementation ➔ Validation ➔ Closeout ➔ Evolution.                   |
| 📋**One-Card Contract**      | Mandatory pre-coding structured contract: Objective + Impact scope + JIT Tiered Acceptance Assertions (frozen after approval).                                    |
| 🧬**Proposal-Based Evolution** | AI automatically accumulates lessons, and rule/convention changes require explicit user approval (applied via Mode 6.5). |
| 📂**`.ai/` Source of Truth** | All project context is persisted in files, allowing perfect session state recovery upon starting a new chat.                              |
| 🔌**Multi-IDE Adapter Suite**  | Out-of-the-box support for Cursor, Cline, Windsurf, Claude Code, Gemini Code Assist, and Agentic workflows.                               |
| ⚖️**Flexible Layering**      | Three-tier project modes: **Micro** (3 files, quick scripts), **Lite** (6 files, small projects), **Full** (11 files, team projects).                                    |

---

## 🚀 Quick Start

### Option A: Use as an On-Demand Skill (Recommended)

ProjectOrchestrator is configured as a standard skill at `.agents/skills/project-orchestrator/SKILL.md`. AI IDEs with skill discovery support (Codex, Cursor, etc.) will automatically detect and activate it.

**Skill structure:**

```
.agents/skills/project-orchestrator/
├── SKILL.md                  # Core skill (YAML frontmatter + compact instructions)
└── references/               # On-demand loaded references
    ├── mode-reference.md     # Full mode output templates (Mode 0-6.5)
    └── forbidden-behaviors.md # Forbidden behaviors + Git Hook scripts
```

Simply open a conversation and type a trigger keyword like **"继续项目"** / **"continue"** — the skill activates automatically based on the YAML `description` field.

See [docs/seflskill使用指南.md](docs/seflskill使用指南.md) for detailed usage.

---

### Option B: Initialize a Target Project

### 1. Initialize Your Project

**Windows (PowerShell)**:

```powershell
# Initialize with Full Mode and all IDE adapters in the target folder
.\init.ps1 -Path "D:\Projects\YourProject" -IDE "all"

# Initialize with Lite Mode and only Cursor adapter
.\init.ps1 -Path "D:\Projects\YourProject" -IDE "cursor" -Lite

# Initialize with Micro Mode (3 files only, for quick scripts)
.\init.ps1 -Path "." -Micro

# Initialize in the current directory
.\init.ps1
```

**macOS / Linux (Bash)**:

```bash
# Initialize with Full Mode and all IDE adapters in the target folder
./init.sh -p ~/Projects/YourProject -i all

# Initialize with Lite Mode and only Cline adapter
./init.sh -p ~/Projects/YourProject -i cline --lite

# Initialize with Micro Mode (3 files only, for quick scripts)
./init.sh --micro

# Initialize in the current directory
./init.sh
```

---

### 📊 Which Mode Should I Choose?

| Criteria | Micro | Lite | Full |
|----------|-------|------|------|
| **Code changes** | < 50 lines, single task | < 5k lines, short-term | > 5k lines, long-term |
| **Team size** | Solo, one-off | Solo or 1-2 people | Team (2+) |
| **Planning files needed?** | No (just the task) | Yes (requirements + design) | Yes (full suite) |
| **Need task traceability?** | No | Minimal | Yes (AUDIT/ADR) |
| **`.ai/` files** | 3 + MODE_REFERENCE | 6 + MODE_REFERENCE | 11 + MODE_REFERENCE |

**Quick rule of thumb**:
- 🐹 **Micro**: Fix a bug, tweak a config, write a utility function → `init.ps1 -Micro` / `init.sh --micro`
- 🐱 **Lite**: Personal project, prototype, weekend hack → `init.ps1 -Lite` / `init.sh --lite`
- 🐘 **Full**: Production project, team collaboration, long-term maintenance → `init.ps1` / `init.sh`

> 💡 You can start with Micro and upgrade later. The init scripts with `-Force` will add missing files without overwriting existing ones.

---

### 2. Configure the `.ai/` Brain Files

After initialization, edit the following files to match your project specifications. The v2.0 engine enforces physical evidence gates (Git Commit Hash + Exit Code 0) at Phase Closeout.

```
.ai/
├── requirements.md        ← Define product requirements & business logic
├── DESIGN.md     ← Outline system architecture & database schema
├── TASKS.md      ← Write down the task list & milestones
├── STATUS.md     ← Document the current project status
└── NEXT.md       ← Set the first active task to be executed
```

### 3. Trigger the Orchestrator

Open a new conversation in your preferred AI IDE and type the startup command:

> **Enter Context Audit mode. Read all .ai/ files and output the audit report. Do not modify any code until I confirm the task plan.**

---

## 📁 Project Structure

```
ProjectOrchestrator/
├── skill.md                  # Core Skill instructions (Single Source of Truth)
├── .agents/skills/            # Standard skill directory (on-demand activation)
│   └── project-orchestrator/
│       ├── SKILL.md           # Skill with YAML frontmatter (auto-discoverable)
│       └── references/        # On-demand loaded references
│           ├── mode-reference.md      # Full mode output templates
│           └── forbidden-behaviors.md # Forbidden behaviors + Git Hook
├── README.md                 # This file (English)
├── README_CN.md              # Chinese description (简体中文)
├── init.ps1                  # PowerShell initialization script (Windows)
├── init.sh                   # Bash initialization script (macOS/Linux)
│
├── templates/ai/             # .ai/ templates
│   ├── requirements.md       # Product Requirements Document template
│   ├── DESIGN.md             # Technical Design Document template
│   ├── TASKS.md              # Task list template ([ ]/[~]/[x]/[!] markers)
│   ├── STATUS.md             # Real project status log (highest reality truth)
│   ├── NEXT.md               # Single active task gate template
│   ├── RULES.md              # AI behavior rules & coding conventions
│   ├── TEST_LOG.md           # Automated test record log
│   ├── DECISIONS.md          # Architecture Decisions Records (ADR)
│   ├── LESSONS.md            # Accumulated lessons learned (auto-appendable)
│   └── EVOLUTION_PROPOSALS.md# Propose improvements to rules or architecture
│
└── adapters/                 # IDE & Agent Adapters
    ├── cursor.mdc            # Cursor MDC format (.cursor/rules/)
    ├── cursorrules           # Cursor legacy format (.cursorrules)
    ├── clinerules.md         # Cline / RooCode format (.clinerules/)
    ├── windsurfrules.md      # Windsurf format (.windsurfrules)
    ├── CLAUDE.md             # Claude Code format (CLAUDE.md)
    ├── gemini_styleguide.md  # Gemini Code Assist format (.gemini/)
    ├── ANTIGRAVITY.md        # Antigravity Agent (Google DeepMind Agent)
    ├── KIRO_AGENT.md         # Kiro AI Agent
    └── AGENTS.md             # Generic agent configuration
```

---

## 🔌 Supported AI IDEs & Agents

| IDE / Agent                  | Adapter File             | Installation Location                      |
| ---------------------------- | ------------------------ | ------------------------------------------ |
| **Skill-compatible IDEs**    | `.agents/skills/`        | `.agents/skills/project-orchestrator/SKILL.md` |
| **Cursor** (MDC)       | `cursor.mdc`           | `.cursor/rules/project-orchestrator.mdc` |
| **Cursor** (Legacy)    | `cursorrules`          | `.cursorrules` (Root)                    |
| **Cline / RooCode**    | `clinerules.md`        | `.clinerules/project-orchestrator.md`    |
| **Windsurf**           | `windsurfrules.md`     | `.windsurfrules` (Root)                  |
| **Claude Code**        | `CLAUDE.md`            | `CLAUDE.md` (Root)                       |
| **Gemini Code Assist** | `gemini_styleguide.md` | `.gemini/styleguide.md`                  |
| **Antigravity Agent**  | `ANTIGRAVITY.md`       | `ANTIGRAVITY.md` (Root)                  |
| **Kiro AI Agent**      | `KIRO_AGENT.md`        | `KIRO_AGENT.md` (Root)                   |
| **Generic Agent**      | `AGENTS.md`            | `AGENTS.md` (Root)                       |

---

## 🔄 Execution Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    Seven-Mode Engine                        │
│                                                             │
│  Mode 0         Mode 1          Mode 2         Mode 3      │
│  Initialize ──➔ Context Audit ➔ Task Plan  ──➔ Implement   │
│  (init)         (audit)         (One-Card)     (code+Hard Stop) │
│                                                             │
│                Mode 4          Mode 5         Mode 6       │
│           ──➔  Validate   ──➔  Closeout   ──➔  Evolve      │
│                (run tests)     (log progress)  (proposal)  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 📂 .ai/ Directory  ➔ Cog memory persisted locally   │    │
│  │ 🚦 NEXT.md Gate    ➔ Strict single active task      │    │
│  │ 🗜️ EVOLUTION_LOG   ➔ Fully auditable git tags       │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 💬 Quick Trigger Keywords

| Intent                 | English Triggers                | 中文触发词                     |
| ---------------------- | ------------------------------- | ------------------------------ |
| Start New Chat / Sync  | "continue", "sync"              | "继续", "同步状态"             |
| Task Planning          | "plan", "start task"            | "规划", "执行 Task Y"          |
| Start Implementation   | "approved", "implement"         | "确认", "批准", "开始实现"     |
| Run Verification Tests | "test", "validate", "run tests" | "运行测试", "验证"             |
| Phase Closeout         | "closeout", "tests passed"      | "测试通过", "阶段完成", "收口" |
| Rules Evolution        | "evolve", "optimize rules"      | "优化规则", "进化"             |
| Apply Proposal         | "apply proposal", "execute"     | "应用提案", "批准并执行"       |
| Initialization         | "initialize", "setup", "init"   | "初始化", "创建项目"           |

---

## ⚖️ Full Mode vs. Lite Mode

| Feature                                  | Full Mode (10 files)              | Lite Mode (5 files)         |
| ---------------------------------------- | --------------------------------- | --------------------------- |
| **Recommended For**                | Team environments, large projects | Solo developers, small MVPs |
| **Seven-Mode Lifecycle**           | ✅ Enabled                        | ✅ Enabled                  |
| **NEXT.md Hard Gate**              | ✅ Enabled                        | ✅ Enabled                  |
| **One-Card Contract (v2.0)**       | ✅ Enabled                        | ✅ Enabled                  |
| **Hard Stop (v2.0)**              | ✅ Enabled                        | ✅ Enabled                  |
| **Iron Triangle Gate (v2.0)**     | ✅ Enabled                        | ✅ Enabled                  |
| **Anti-Collusion Guard (v2.0)**   | ✅ Enabled                        | ✅ Enabled                  |
| **EVOLUTION_LOG Output**           | ✅ Enabled                        | ✅ Enabled                  |
| **Anti-Bloat & DRY constraints**   | ✅ Enabled                        | ✅ Enabled                  |
| **Context Compactor & Safeguards** | ✅ Enabled                        | ✅ Enabled                  |
| **RULES / TEST_LOG / DECISIONS**   | ✅ Enabled                        | ❌ Omitted                  |
| **LESSONS / PROPOSALS**            | ✅ Enabled                        | ❌ Omitted                  |

*Note: v2.0 physical evidence gates (One-Card Contract, Hard Stop, Iron Triangle, Anti-Collusion) are enforced in all modes. Lite Mode preserves the core workflow discipline, omitting only long-term knowledge accumulation files.*

---

## 🧬 Design Philosophy

This Skill is built upon key agentic design paradigms:

* **File-based memory over chat memory**: Prevents cognitive context degradation over long chats.
* **Rigorous process over raw intelligence**: Strict constraints outperform unconstrained LLM reasoning.
* **Defensive context control**: Mandatory 3-iteration test-fix limit ensures absolute focus by clearing chat history when bloated.
* **Cyborg developer symmetry**: Clear separation of roles—Human as the architect (blueprint guardian) and AI as the execution engine (checklists & implementation scribe).

---

## 📜 License

MIT — Feel free to use, modify, and distribute.
