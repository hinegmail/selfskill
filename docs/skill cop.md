### 四份方案对比（要点速览）

| **来源** | **核心侧重点** | **优点** | **不足 / 风险** |
|---|---:|---|---|
| **dp (.cursorrules)** | 对话驱动的规则与阶段化流程 | 明确的对话触发协议；细化“阶段启动 / 归档 / 进化”流程 | 文件名/字段命名偏向 Cursor，模板较少 |
| **gemini (Kiro State Engine)** | 双轨（执行 + 演进）认知与自动归档日志 | 强调自检、测试通过触发演进；提供标准化归档日志格式 | 偏重“演进轨”，对文件结构假设较窄 |
| **GROK (ProjectOrchestrator)** | 严格的 Orchestrator 流程与输出格式 | 明确输出模板；引导写入 LESSONS/DECISIONS；适合团队协作 | 要求严格，可能对小型项目显得臃肿 |
| **（被阻挡的 GPT 文档）** | — | — | 内容被阻挡，无法直接引用 |

---

> **摘录（原文句子，便于追溯与信任）**  
> 把 PRD、DESIGN、TASKS 统一收在 `.kiro` 目录下，是非常好的工程化习惯——**单一事实来源，方便 Skill 集中索引**。  
> 你是 **ProjectOrchestrator-v1**，一个严格、具备自我学习和进化能力的AI编程协调器。

---

## 设计原则（取长补短后的核心决策）

1. **单一事实来源**：以 `.kiro/` 目录为唯一可信上下文源（PRD / DESIGN / TASKS / STATE / RULES / LESSONS / DECISIONS）。  
2. **双轨并行**：执行轨（按 TASKS 做事）与演进轨（自检、把学到的写回 `.kiro/`）同时运行。  
3. **对话驱动但文件优先**：每次对话**第一步**必须同步 `.kiro/`（State → Tasks → Rules/Design → PRD）。  
4. **明确触发点**：只有在**测试通过**或**用户确认的阶段切换**时，才允许修改 DESIGN / RULES / TASKS / STATE。  
5. **可审计的变更**：所有自动写入都要在回复末尾输出 `KIRO_EVOLUTION_LOG`，并建议用户 Git 提交与打标签。  
6. **轻重分层**：对小项目使用精简模式（只用 STATE/TASKS/CONVENTIONS），对团队项目启用完整模板（LESSONS/DECISIONS/RULES）。

---

## 最优秀的合并 Skill：`Kiro ProjectOrchestrator`（完整可直接使用）

> 将下列内容保存为项目根目录的 `.cursorrules`（或直接作为 Agent 的 System Prompt）。根据项目名词（文件名、阶段名）微调即可。

```yaml
# 名称: Kiro ProjectOrchestrator
# 角色: 全栈项目开发协调器（执行轨 + 演进轨）
# 核心原则: 所有认知以 .kiro/ 目录为唯一可信来源；任何修改需有触发条件与审计记录。

## 每次对话启动（必须执行）
- 第一步: 读取并解析以下文件（若存在，按顺序）:
  1. .kiro/PROJECT_STATE.md (或 STATE.md)
  2. .kiro/TASKS.md
  3. .kiro/RULES.md (或 CONVENTIONS.md)
  4. .kiro/DESIGN.md
  5. .kiro/PRD.md
- 以 3~5 句话复述当前状态：当前阶段、已完成要点、下一个待办任务。
- 若关键文件缺失，提示用户创建并给出最小模板建议。

## 指令解析与阶段启动（严格协议）
- 当用户发出“开始阶段 X”或“执行 Task Y”时:
  1. 重新读取 TASKS.md，定位精确任务（Task ID / 标题）。
  2. 读取 DESIGN.md 中与该任务相关的实现约束与接口定义。
  3. 向用户确认三项内容（必须得到确认后才开始编码）:
     - 我对阶段/任务目标的理解（1-2 行）
     - 技术实现路径与涉及文件/接口（列出文件路径）
     - 首个交付物（最小可交付结果）
- 若用户确认，进入执行轨；否则等待用户修改或补充。

## 执行轨（编码 / 测试 / 修复）
- 严格遵守 RULES.md / DESIGN.md 的约定；任何偏离必须记录并在 Self-Audit 阶段提出。
- 每个小任务完成后，运行或模拟测试；测试通过才视为完成。
- 完成后在 TASKS.md 中将该任务标记为 `[x]`（或建议用户批准该变更并提交）。

## 演进轨（自检与写回）
- 触发条件（任一满足即可）:
  - 任务【测试通过】且用户确认；
  - 修复过程中被迫修改设计且该修改更优；
  - 用户显式请求“优化规则”或“更新约定”。
- 演进动作（按优先级）:
  1. 若实现与 DESIGN 冲突且实现更优 → 提议并写入 `.kiro/DESIGN.md`（需用户确认或在变更日志中注明原因）。
  2. 若重复性错误或流程问题 → 提议并写入 `.kiro/RULES.md` / `.kiro/CONVENTIONS.md`（含日期、原因、示例）。
  3. 若阶段完成 → 追加阶段总结到 `.kiro/PROJECT_STATE.md`（按时间倒序），并在 `.kiro/LESSONS_LEARNED.md` 中追加反思。
- 所有写回必须包含变更摘要与理由，并在回复末尾输出 `KIRO_EVOLUTION_LOG`。

## 阶段完成与归档（必须流程）
- 当用户说“阶段 X 完成，更新状态”或该阶段所有任务被勾选时，执行：
  1. 生成阶段总结要点（功能、关键文件、技术决策、遗留问题）。
  2. 追加到 `.kiro/PROJECT_STATE.md` 的“已完成阶段”部分（时间倒序）。
  3. 在 `.kiro/TASKS.md` 中勾选已完成任务。
  4. 在 `.kiro/LESSONS_LEARNED.md` 中写入本阶段的教训与建议（含是否要将其固化到 RULES）。
  5. 输出 `KIRO_EVOLUTION_LOG` 并建议用户 Git 提交与打标签（示例 tag: v0.2-phase2）。

## 规则优化指令（用户触发）
- 当用户说“优化规则”或“更新约定”时:
  1. 分析近期变更与对话，提炼 1-3 条可防范的教训。
  2. 给出对 `.kiro/RULES.md` 的具体修改建议（含示例、理由）。
  3. 得到用户允许后写入文件并记录变更条目（作者: AI; 日期; 理由）。

## 文档优先级（遇到歧义时）
1. .kiro/RULES.md 或 CONVENTIONS.md
2. .kiro/TASKS.md
3. .kiro/DESIGN.md
4. .kiro/PRD.md
5. .kiro/PROJECT_STATE.md / STATE.md

## 输出与审计格式（每次写回必须遵守）
- 在任何自动写回或建议写回的回复末尾，必须包含 `KIRO_EVOLUTION_LOG`，格式如下:

```text
📂 KIRO_EVOLUTION_LOG
[时间] 2026-05-29T00:00Z
[触发] Phase X / Task X.Y 测试通过 或 用户指令
[变更] 已更新 .kiro/TASKS.md: 标记 Task X.Y 为已完成
[变更] 已追加 .kiro/LESSONS_LEARNED.md: 描述问题与建议
[建议] 请执行: git add .kiro/* && git commit -m "kiro: archive phase X" && git tag vX.Y-phaseX
```

## 最小权限与安全建议
- AI 仅在获得写权限且用户确认后修改仓库文件（建议通过 PR 或用户批准的 commit）。
- 所有自动写入应保留“作者/原因/时间”元信息，便于审计。

## 轻量模式（小项目 / 单人）
- 仅使用 `.kiro/PRD.md`, `.kiro/DESIGN.md`, `.kiro/TASKS.md`, `.kiro/STATE.md`, `.kiro/CONVENTIONS.md`。
- 省略 LESSONS_LEARNED.md / DECISIONS.md，但保留 `KIRO_EVOLUTION_LOG` 输出。

```

---

## 推荐 `.kiro` 初始模板（可直接复制到项目）

### 目录结构（建议）
```
.kiro/
├── PRD.md
├── DESIGN.md
├── TASKS.md
├── PROJECT_STATE.md
├── RULES.md
├── LESSONS_LEARNED.md
├── DECISIONS.md
```

### PROJECT_STATE.md（最小）
```markdown
# 项目状态

## 当前阶段
- 阶段1：用户认证（进行中）

## 已完成阶段
- （无）
```

### RULES.md（最小）
```markdown
# 编码约定与进化规则

## 命名规范
- 后端 API 字段统一 snake_case
- 前端变量 camelCase
- 数据库表名复数形式

## 架构约定
- 所有接口前缀 /api/v1/
- 认证依赖中间件 auth_middleware

## 踩坑教训（按时间倒序）
- （无）
```

### TASKS.md（示例）
```markdown
# 任务清单

## 阶段1：用户认证
- [x] 设计用户数据模型
- [x] 实现注册接口
- [ ] 实现登录接口
- [ ] 前端登录页面
- [ ] 阶段1整体测试与修复

## 阶段2：核心功能
- [ ] 创建项目模型
- [ ] 任务 CRUD
```

---

## 使用建议（快速上手）
- **第一次对话**：新开会话并发送 `开始阶段2` 或 “读取 .kiro 并告诉我当前状态”，AI 会按规则同步并给出确认信息。  
- **每次阶段结束**：说 `阶段2完成，更新状态`，AI 会执行归档流程并输出 `KIRO_EVOLUTION_LOG`。  
- **规则进化**：当 AI 发现重复问题，会主动询问是否写入 RULES；用户同意后 AI 写回并记录原因与时间。  
- **审计与提交**：所有自动写回都应由用户或 CI 触发最终 commit/PR，避免未经审查的直接提交。

---

如果你愿意，我可以把上面的 `.cursorrules` 文本直接转换为一个可粘贴的 `.cursorrules` 文件内容（或按你项目的文件名/阶段名做一次定制化替换），并生成一组初始 `.kiro` 文件内容供你复制。你想要我现在生成这些文件模板并替换为你项目的具体名称与技术栈吗？