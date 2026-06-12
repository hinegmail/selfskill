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
| 📋**Three Confirmations**      | Mandatory pre-coding validation: Objective alignment + Technical path/file plan + Minimum deliverable.                                    |
| 🧬**Proposal-Based Evolution** | AI automatically accumulates lessons, and rule/convention changes require explicit user approval (applied via Mode 6.5). |
| 📂**`.ai/` Source of Truth** | All project context is persisted in files, allowing perfect session state recovery upon starting a new chat.                              |
| 🔌**Multi-IDE Adapter Suite**  | Out-of-the-box support for Cursor, Cline, Windsurf, Claude Code, Gemini Code Assist, and Agentic workflows.                               |
| ⚖️**Flexible Layering**      | Choose between a 5-file Lite Mode (solo/small projects) and a 10-file Full Mode (large/team projects).                                    |

---

## 🚀 Quick Start

### 1. Initialize Your Project

**Windows (PowerShell)**:

```powershell
# Initialize with Full Mode and all IDE adapters in the target folder
.\init.ps1 -Path "D:\Projects\YourProject" -IDE "all"

# Initialize with Lite Mode and only Cursor adapter
.\init.ps1 -Path "D:\Projects\YourProject" -IDE "cursor" -Lite

# Initialize in the current directory
.\init.ps1
```

**macOS / Linux (Bash)**:

```bash
# Initialize with Full Mode and all IDE adapters in the target folder
./init.sh -p ~/Projects/YourProject -i all

# Initialize with Lite Mode and only Cline adapter
./init.sh -p ~/Projects/YourProject -i cline --lite

# Initialize in the current directory
./init.sh
```

### 2. Configure the `.ai/` Brain Files

After initialization, edit the following files to match your project specifications:

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

```test
SelfSkill/
├── skill.md                  # Core Skill instructions (Single Source of Truth)
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
│  (init)         (audit)         (plan+3conf)   (code)      │
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
| **EVOLUTION_LOG Output**           | ✅ Enabled                        | ✅ Enabled                  |
| **Anti-Bloat & DRY constraints**   | ✅ Enabled                        | ✅ Enabled                  |
| **Context Compactor & Safeguards** | ✅ Enabled                        | ✅ Enabled                  |
| **RULES / TEST_LOG / DECISIONS**   | ✅ Enabled                        | ❌ Omitted                  |
| **LESSONS / PROPOSALS**            | ✅ Enabled                        | ❌ Omitted                  |

*Note: Lite Mode preserves the core workflow discipline and anti-drift rules, omitting only the long-term knowledge accumulation files.*

---

## 🧬 Design Philosophy

This Skill is built upon key agentic design paradigms:

* **File-based memory over chat memory**: Prevents cognitive context degradation over long chats.
* **Rigorous process over raw intelligence**: Strict constraints outperform unconstrained LLM reasoning.
* **Defensive context control**: Mandatory 3-iteration test-fix limit ensures absolute focus by clearing chat history when bloated.
* **Cyborg developer symmetry**: Clear separation of roles—Human as the architect (blueprint guardian) and AI as the execution engine (checklists & implementation scribe).

---

## 📜 License

MIT — Feel free to use, modify, and distribute.texttext
