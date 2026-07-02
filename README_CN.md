# 简体中文 | [English](README.md)

# 🧭 ProjectOrchestrator

**一个具备双轨认知与自进化能力的通用 AI 编程协调器 Skill**

让 AI 不再是「盲目写代码的工具人」，而是一个严格遵守流程、能自我学习、可审计的项目开发协调器。适配所有主流 AI IDE。

\---

## ✨ 核心特性

|特性|描述|
|-|-|
|🧠**双轨认知**|执行轨（写代码）+ 演进轨（自我反思和知识固化）同时运行|
|🚦**NEXT.md 硬闸门**|唯一活跃任务控制，彻底杜绝 AI 擅自扩展范围、跳任务|
|🔄**七模式引擎**|初始化 → 审计 → 规划 → 实现 → 验证 → 收口 → 进化，不可跳跃|
|📋**三项确认协议**|编码前强制确认：目标理解 + 技术路径 + 首个交付物|
|🧬**提案制进化**|LESSONS 可自动积累，规则与 Skill 进化经用户审批后可由 AI 自动应用（通过 Mode 6.5）|
|📂\*\*`.ai/` 单一事实来源\*\*|所有项目认知存文件，新对话即可完美恢复上下文|
|🔌**多 IDE 适配**|一份 Skill 适配 Cursor / Cline / Windsurf / Claude Code / Gemini 等|
|⚖️**轻重分层**|小项目 5 文件轻量模式，大项目 10 文件完整模式|

\---

## 🚀 快速上手

### 1\. 初始化项目

**Windows (PowerShell)**:

```powershell
# 在目标项目中初始化（完整模式 + 所有 IDE）

\#  .\\init.ps1 -Path "D:\\Projects\\CustomerServices-SAAS" -IDE "ANTIGRAVITY"
.\\init.ps1 -Path "D:\\Projects\\YourProject" -IDE "all"

# 轻量模式 + 仅 Cursor
.\\init.ps1 -Path "D:\\Projects\\YourProject" -IDE "cursor" -Lite

# 在当前目录初始化
.\\init.ps1
```

**macOS / Linux (Bash)**:

```bash
# 完整模式 + 所有 IDE
./init.sh -p \~/Projects/YourProject -i all

# 轻量模式 + 仅 Cline
./init.sh -p \~/Projects/YourProject -i cline --lite

# 在当前目录
./init.sh
```

### 2\. 编辑 `.ai/` 文件

初始化后，编辑以下文件填入你的项目信息：

```
.ai/
├── requirements.md        ← 填写产品需求
├── DESIGN.md     ← 填写技术设计
├── TASKS.md      ← 填写任务清单
├── STATUS.md     ← 设置当前状态
└── NEXT.md       ← 设置第一个活跃任务
```

### 3\. 开始使用

在 AI IDE 中新开对话，直接输入极简指令即可启动：

* **若为全新项目/首次迁移建档**：

> \*\*启动项目\*\*（英文：“\*\*init project\*\*” 或 “\*\*setup\*\*”）
  \*AI 将自动通过工具读取已有的原始文档（requirements/DESIGN/TASKS），自动提炼项目骨架并建立 Line-Range INDEX 索引，生成控制文件提案一键写入。\*

* **若为开发中的项目（同步最新进度）**：

> \*\*继续项目\*\*（英文：“\*\*continue project\*\*” 或 “\*\*continue\*\*”）
  \*AI 将通过工具快速读取舵盘等控制文件，进入 Context Audit 并输出审计报告。\*

\---

## 📁 项目结构

```
SelfSkill/
├── skill.md                     # 核心 Skill（完整版，唯一事实来源）
├── README.md                    # 本文件
├── init.ps1                     # Windows 初始化脚本
├── init.sh                      # macOS/Linux 初始化脚本
│
├── templates/ai/                # .ai/ 目录模板
│   ├── requirements.md          # 产品需求模板
│   ├── DESIGN.md                # 技术设计模板
│   ├── TASKS.md                 # 任务清单模板
│   ├── STATUS.md                # 项目状态模板
│   ├── NEXT.md                  # 活跃任务闸门模板
│   ├── RULES.md                 # AI 规则 + 编码约定模板
│   ├── TEST\_LOG.md              # 测试记录模板
│   ├── DECISIONS.md             # 架构决策模板
│   ├── LESSONS.md               # 经验教训模板
│   └── EVOLUTION\_PROPOSALS.md   # 进化提案模板
│
├── adapters/                    # IDE 适配器
│   ├── cursor.mdc               # Cursor 新格式 (.cursor/rules/)
│   ├── cursorrules              # Cursor 传统格式 (.cursorrules)
│   ├── clinerules.md            # Cline / RooCode (.clinerules/)
│   ├── guide.md                 # Gemini Code Assist (.gemini/)
│   ├── ANTIGRAVITY.md           # Antigravity Agent
│   ├── KIRO\_AGENT.md           # Kiro AI Agent (命名为 KIRO\_AGENT.md)
└───── AGENTS.md                # 通用格式 (AGENTS.md)
```

\---

## 🔌 支持的 AI IDE

|IDE|适配器文件|安装位置|
|-|-|-|
|**Cursor** (新版)|`cursor.mdc`|`.cursor/rules/project-orchestrator.mdc`|
|**Cursor** (传统)|`cursorrules`|`.cursorrules`|
|**Cline / RooCode**|`clinerules.md`|`.clinerules/project-orchestrator.md`|
|**Windsurf**|`windsurfrules.md`|`.windsurfrules`|
|**Claude Code**|`CLAUDE.md`|`CLAUDE.md` (项目根目录)|
|**Gemini Code Assist**|`gemini\_styleguide.md`|`.gemini/styleguide.md`|
|**Antigravity** (Google DeepMind Agent)|`ANTIGRAVITY.md`|`ANTIGRAVITY.md` (项目根目录)|
|**Kiro AI Agent**|`KIRO\_AGENT.md`|`KIRO\_AGENT.md` (项目根目录)|
|**通用**|`AGENTS.md`|`AGENTS.md` (项目根目录)|

\---

## 🔄 工作流程

```
┌─────────────────────────────────────────────────────────────┐
│                    七模式执行引擎                              │
│                                                             │
│  Mode 0         Mode 1          Mode 2         Mode 3      │
│  初始化    →    上下文审计   →   任务规划    →   任务实现     │
│  (init)        (audit)       (plan+3确认)    (implement)   │
│                                                             │
│                Mode 4          Mode 5         Mode 6       │
│           →   验证与修复   →   阶段收口    →  进化提案      │
│               (validate)     (closeout)      (evolve)      │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 📂 .ai/ 文件系统   ← 所有认知持久化于此             │    │
│  │ 📋 NEXT.md 闸门    ← 唯一允许执行的任务              │    │
│  │ 🔍 EVOLUTION\_LOG   ← 每次写回的审计日志              │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

\---

## 💬 常用触发词速查

|你想做什么|说什么|
|-|-|
|继续开发会话|"继续项目" / "继续开发" / "continue" / "同步状态"|
|制定计划|"规划" / "plan" / "执行 Task 1.2"|
|开始编码|"确认" / "批准" / "approved"|
|运行测试|"运行测试" / "test" / "validate"|
|完成任务|"测试通过" / "收口" / "closeout"|
|优化规则|"优化规则" / "进化" / "evolve"|
|应用/执行提案|"应用提案" / "批准并执行" / "apply proposal"|
|启动/初始化项目|"启动项目" / "初始化项目" / "setup" / "init"|

\---

## ⚖️ 完整模式 vs 轻量模式

| | 完整模式 | 轻量模式 |
| |--|---------|
| **文件数** | 10 个 | 5 个 |
| **适合** | 团队项目、中大型项目 | 个人项目、小型项目 |
| **七模式引擎** | ✅ | ✅ |
| **NEXT.md 闸门** | ✅ | ✅ |
| **EVOLUTION\_LOG** | ✅ | ✅ |
| **RULES.md** | ✅ | ❌ |
| **TEST\_LOG.md** | ✅ | ❌ |
| **DECISIONS.md** | ✅ | ❌ |
| **LESSONS.md** | ✅ | ❌ |
| **EVOLUTION\_PROPOSALS** | ✅ | ❌ |

轻量模式保留了核心的「流程控制」和「防漂移」能力，只省略了「知识积累」相关文件。

\---

## 🧬 设计哲学

本 Skill 融合了多个方案的精华：

* **七模式状态机引擎** + **NEXT.md 硬闸门** + **提案制进化**
* **双轨认知**（执行轨 + 演进轨）+ **新对话切断上下文污染**
* **三项确认启动协议** + **轻重分层** + **对话自然度**
* **结构化输出格式** + **极简状态管理**

**核心理念**：AI 可以自动记录事实，但不能自动修改规则。项目认知持久化在文件系统中，而非对话历史中。

\---

## 📜 License

MIT — 自由使用、修改和分发。

