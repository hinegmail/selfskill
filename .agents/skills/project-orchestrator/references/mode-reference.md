# Mode Reference — 完整模式输出模板

> **何时阅读此文件**: 在会话中首次需要为某个模式生成输出时，阅读对应的 `### Mode N` 章节。SKILL.md 仅包含触发器和关键规则，不包含完整输出模板格式。
>
> **高效读取方式**: 不要全文阅读。使用章节锚点导航 — 搜索 `### Mode N:` 标题，仅读取到下一个 `### Mode` 或 `##` 标题为止。
>
> **回退策略**: 如果此文件不存在，SKILL.md 中的精简规则足以进行基本操作。输出会更简单但功能可用。
>
> **强制读取触发器**: Mode 2（任务规划）在生成三项确认输出前**必须**阅读本文档 §Mode 2 章节。

---

## 目录

- [Mode 0: Initialization](#mode-0-initialization)
- [Mode 1: Context Audit](#mode-1-context-audit)
- [Mode 2: Task Planning](#mode-2-task-planning)
- [Mode 3: Task Implementation](#mode-3-task-implementation)
- [Mode 4: Validation & Test Repair](#mode-4-validation--test-repair)
- [Mode 4.5: Document Sync Check](#mode-45-document-sync-check)
- [Mode 5: Phase Closeout](#mode-5-phase-closeout)
- [Mode 6: Skill Evolution Proposal](#mode-6-skill-evolution-proposal)
- [Mode 6.5: Apply Approved Proposal](#mode-65-apply-approved-proposal)

---

## Mode 0: Initialization

**触发条件**:
- `.ai/STATUS.md` 或 `.ai/NEXT.md` 缺失
- `.ai/STATUS.md` 或 `.ai/STEERING.md` 包含模板占位符
- 用户说"启动项目 / 初始化项目 / setup / initialize / init"

**动作**:
1. 读取 `.ai/requirements.md`、`.ai/DESIGN.md`、`.ai/TASKS.md`（如存在）。
2. **占位符检测扫描**: 扫描每个 `.ai/` 运行时文件，分类为:
   - **✅ 已填充** — 包含真实项目数据，无占位符
   - **⚠️ 模板** — 仍含占位符文本
   - **❌ 缺失** — 文件不存在
3. 若源文档有真实数据 → **自动提取并填充**所有 ⚠️/❌ 运行时文件:
   - **STEERING.md**: 从 requirements.md 提取项目名/核心价值/技术栈，从 DESIGN.md 提取架构模块，从 TASKS.md 提取里程碑，构建 INDEX 章节映射。
   - **STATUS.md**: 提取项目名，统计任务数设置进度，提取当前阶段，设置活跃任务，填充里程碑执行状态，设置时间戳，写 TL;DR。
   - **NEXT.md**: 找到第一个 `[ ]` 任务写入，确保文件路径引用当前项目。
   - **RULES.md**: 用 DESIGN.md 和 TASKS.md 数据填充占位符。
4. 若源文档也为占位符或缺失 → 启动**交互式设置向导**（3 个问题）:
   - ① 项目名称与核心商业价值定位
   - ② 核心技术栈与工程框架
   - ③ 核心功能职责与模块规划
5. 不实现代码，等待用户确认。

**输出格式**:
```
## 🚀 Initialization

### Placeholder Detection Scan
| File | Status | Action |
|------|--------|--------|
| requirements.md | ✅ / ⚠️ / ❌ | (action) |
| DESIGN.md | ... | ... |
| TASKS.md | ... | ... |
| STEERING.md | ... | ... |
| STATUS.md | ... | ... |
| NEXT.md | ... | ... |

### Auto-Extracted Content
（提取和写入内容摘要）

### Files Requiring User Input
（如启动向导，列出问题）

### Recommended Next Step
确认自动提取内容（或回答向导问题），然后进入 Context Audit 模式。
```

---

## Mode 1: Context Audit

**触发条件**: 每次会话开始；用户说"继续项目 / continue / sync"。

**动作**:
1. **TL;DR 优先读取**: 先读 STATUS.md `## TL;DR`（前 5 行）。若指示"无变更"且时间戳较新，跳过完整读取。
   - **Micro 模式**: 仅 NEXT.md + STATUS.md 存在时，跳过 STEERING.md 和时间戳检查。
2. **时间戳智能加载**: 读取 `last_audit_timestamp`，获取 requirements.md/DESIGN.md 的 mtime，差异 ≤ 60 秒则跳过。STEERING.md 始终读取（Micro 除外）。Shell 命令失败则回退完整重审。
3. **占位符检测**: 若 STEERING.md/STATUS.md/NEXT.md 含模板占位符 → 重定向到 Mode 0。
4. **规则热加载**: 若 RULES.md 存在且含自定义规则，读取并合并到活跃上下文。
5. **收口完整性校验**: 交叉验证 TASKS.md ↔ STATUS.md ↔ NEXT.md:
   - **Check A**: NEXT.md 活跃任务在 TASKS.md 中已标记 `[x]` → 上次 Mode 5 未更新 NEXT.md。
   - **Check B**: TASKS.md 最近完成任务未在 STATUS.md 中提及 → 上次 Mode 5 未更新 STATUS.md。
   - **Check C**: NEXT.md 处于空闲态（空/占位符/"no active task"/非任务文本如"就绪中"）但 TASKS.md 有未完成任务 → 上次 Mode 5 未设置下一任务。
   - 任一检查失败 → 输出警告并进入**恢复协议**（完成缺失的 Mode 5 更新后再继续）。
6. **空闲态任务选定**: 若 NEXT.md 空闲且 TASKS.md 有未完成任务 → 选定第一个未完成任务写入 NEXT.md（阻塞操作，完成前不进入 Mode 2）。
7. 验证 NEXT.md 闸门。
8. **Micro 模式自动升级检测**: 任务有 ≥ 3 验收标准或涉及 > 5 文件 → 建议升级到 Lite 模式。
9. 输出审计报告。不修改代码文件。

**输出格式**:
```
## 🧭 Context Audit

### 当前产品目标
（1-2 句来自 PRD）

### 当前阶段与状态
（阶段、已完成/总数、测试状态）

### STATUS.md 实况
（关键事实）

### 唯一允许执行的下一任务
（来自 NEXT.md — Task ID + 名称）

### 相关设计约束
（相关 DESIGN.md 章节）

### 涉及文件
- 需检查：...
- 预计修改：...

### 已知约束与风险
（来自 RULES.md、LESSONS.md、STATUS.md）

### 本次不会做的事（Non-goals）
（明确范围边界）

### 文档冲突或警告
（如有）

### 推荐下一模式
Task Planning
```

---

## Mode 2: Task Planning

**触发条件**: 上下文审计完成且用户确认；用户说"规划 / plan / start task"。

**前置条件**: 上下文审计已完成，NEXT.md 闸门通过。

**动作**:
0. **强制模式模板加载**: 若本会话尚未读取 MODE_REFERENCE.md，在生成任何 Mode 2 输出前**必须**读取 §Mode 2 章节。
1. 规划 NEXT.md 单任务的实现。
2. **强制历史教训检索**: 用 grep_search 搜索 LESSONS.md 的 `### 模块/关键词` 字段，使用当前任务的模块名和关键词。匹配的教训必须在"历史避坑经验"中引用。
3. 执行**三项确认协议**:
   - ① 任务目标理解（1-2 行）
   - ② 技术实现路径 + 涉及文件/接口（结合 LESSONS.md 发现）
   - ③ 首个最小可交付物
4. 列出验收标准、风险和非目标。不修改代码，等待用户确认。

**Micro 模式**: 跳过三项确认，输出 3 行快速计划（① 目标 ② 修改文件 ③ 首步），等待"执行"。

**输出格式**:
```
## 📋 Task Plan

### 任务
（Task ID + 名称）

### 历史避坑经验（如有）
（引用自 LESSONS.md 的教训）

### 目标理解（三项确认 ①）
（1-2 行）

### 技术路径与涉及文件（三项确认 ②）
- 需检查文件：...
- 预计修改文件：...

### 首个最小可交付物（三项确认 ③）
（首个交付物）

### 验收标准
（逐行来自 TASKS.md / NEXT.md）

### 实现步骤
1. ...
2. ...

### 需求来源
（引用 requirements.md 章节）

### 设计依据
（引用 DESIGN.md 章节）

### 风险
（潜在问题）

### 本次不会做的事（Non-goals）
（明确边界）

---

🚀 **规划完成，准备就绪！**

以上规划已完成检查，技术路径清晰，验收标准明确。

您现在可以：
① 说 **"执行"** 或 **"开始"** → 立即进入实现模式开始编码
② 提出 **疑问或建议** → 调整规划
③ 要求 **重新规划** → 重新分析任务

等待您的下一步指令...
```

---

## Mode 3: Task Implementation

**触发条件**: 收到 §Mode 2→3 自动转换触发器的肯定信号，或用户提出实现相关技术问题。

**前置条件**: Mode 2 输出已生成，NEXT.md 闸门有效。

**铁律**:
1. 仅实现 NEXT.md 中的活跃任务。
2. 不执行未来任务。
3. 不扩大 requirements.md 之外的需求。
4. 不重构无关模块。
5. 不重写已测试模块（除非当前任务需要）。
6. 不更改公共接口（除非当前任务需要或用户批准）。
7. 不引入新依赖（除非当前任务需要或用户批准）。
8. 文档与代码冲突时**停止并报告**。
9. 任务描述模糊时**停止并询问**。

**输出格式**:
```
## 🛠️ Task Implementation

### 任务
（Task ID + 名称）

### 当前进度
✓ Mode 1: Context Audit 完成
✓ Mode 2: Task Planning 完成
▶️ Mode 3: Task Implementation 进行中

### 执行说明
- 开始实现 Task 中的功能需求
- 实现完成后自动进入 Mode 4: Validation & Test
- 如需中止，可随时说"停止"或"暂停"

---

### 修改的文件
（逐文件列表）

### 变更说明
（每个文件的变更内容和原因）

### 验收标准检查
- [x] Criterion 1 — satisfied
- [x] Criterion 2 — satisfied
- [ ] Criterion 3 — needs testing

### 建议测试命令
（要运行的命令）

### 需要更新的文档（Mode 5 时执行）
- TASKS.md: 标记本任务为 [x]
- STATUS.md: 追加阶段总结，更新 last_audit_timestamp
- NEXT.md: 设置下一活跃任务
- [DESIGN.md]: 如有设计偏离，需对齐
- [LESSONS.md]: 如有新教训，需记录
- [TEST_LOG.md]: 如有测试记录，需追加结论

**请确保测试通过后进入 Mode 5 完成文档更新。**

### 推荐下一模式
Validation
```

不自动开始下一任务。

---

## Mode 4: Validation & Test Repair

**触发条件**: 实现完成；或用户提供测试结果/错误日志。

**动作**:
1. 运行或推荐最小相关测试集。
2. 记录所有测试活动到 TEST_LOG.md。
3. **上下文健康检查**: 以下信号 2+ 触发时输出健康警告并建议新对话:

   | 信号 | 检查 |
   |--------|-------|
   | 🔴 修复迭代 | 当前测试-修复-复测循环 ≥ `mitigation_threshold`（默认 3） |
   | 🟠 对话轮次 | 当前会话估计 > 30 轮 |
   | 🟠 错误日志量 | 本次会话处理的错误/traceback > 200 行 |
   | 🟡 记忆引用 | AI 引用不在 `.ai/` 文件中的细节 |
   | 🟡 范围漂移 | 当前工作触及 NEXT.md 之外的文件或任务 |

4. **上下文模糊缓解协议**: 超过 `mitigation_threshold` 时:
   - 汇总分析连续失败的根因
   - 写"根因诊断反思"到 TEST_LOG.md
   - 输出通知请求用户开启新会话
   - 日志压缩器: 不处理超过 50 行的原始终端输出，仅列出失败文件/测试名/错误消息/行号
5. 测试失败时: 仅修复当前任务相关失败，不添加新功能，不重构无关模块，不改变任务范围。

**输出格式**:
```
## ✅ Validation Result

### 任务
（Task ID + 名称）

### 测试命令
（执行的命令）

### 结果
（通过/失败摘要）

### 失败项（如有）
| # | 失败命令 | 错误摘要 | 根因 | 修复文件 | 复测结果 |
|---|---------|---------|------|---------|---------|
| 1 | ... | ... | ... | ... | ✅ Pass |

### 最终验证状态
✅ 全部通过 / ❌ 仍有未解决项

### 推荐下一模式
Phase Closeout（如全部通过）
```

全部通过时自动进入 Mode 4.5。

---

## Mode 4.5: Document Sync Check

**触发条件**: Mode 4 测试通过；自动进入。

**动作**:
1. 检查文档更新需求:
   - TASKS.md 需标记任务为 `[x]`?
   - STATUS.md 需追加阶段总结?
   - TEST_LOG.md 需追加测试结论?
   - DESIGN.md 需对齐设计偏离?
   - LESSONS.md 需记录新教训?
2. 如有文档需更新 → 自动进入 Mode 5。
3. 若所有文档已最新 → 跳过 Mode 5，建议新对话。

**输出格式**:
```
## 📋 Document Sync Check

### Current Task
（Task ID + 名称）

### Documents Requiring Update
- [ ] TASKS.md - 需要标记 Task X 为 [x]
- [ ] STATUS.md - 需要追加阶段总结
- [ ] TEST_LOG.md - 需要追加测试结论
- [ ] DESIGN.md - 无设计偏离（或：需要对齐）
- [ ] LESSONS.md - 无新教训（或：需要记录）

### Recommended Action
进入 Mode 5: Phase Closeout 完成文档更新
```

---

## Mode 5: Phase Closeout

**触发条件**: 验证通过；用户说"测试通过 / closeout / phase complete"。

**必须更新（阻塞 — 下一任务前必须完成）**:
1. **TASKS.md** — 标记完成任务为 `[x]`
2. **STATUS.md** — 更新**所有**以下章节:
   - **`## TL;DR`**: 一句话状态摘要
   - **元数据字段**: `更新时间`、`项目整体进度`、`当前开发阶段`、`当前活跃任务`、`当前测试状态`、`last_audit_timestamp`
   - **`## 📈 里程碑执行状态`**: 从 TASKS.md 读取所有里程碑，统计 `[x]`/总数，更新每行（名称+计数+状态），移除占位符
   - **`## 📂 历史审计日志`**: 追加阶段总结（完成功能、关键文件、技术决策、已知问题）
   - **`## 🛑 风险、阻塞`**: 如有新阻塞或设计偏离则更新
3. **NEXT.md** — 重新生成下一个活跃任务；若无则写**确切** `no active task`（唯一合法空闲态文本）
4. **TEST_LOG.md** — 追加结构化测试记录（命令/结果/失败/根因/修复/复测/结论）

**Micro 模式**: 仅更新 NEXT.md、STATUS.md（TL;DR + 时间戳）、LESSONS.md。

**条件更新（可选但推荐）**:
5. DECISIONS.md — 如有设计偏离或重要决策
6. LESSONS.md — **强制知识捕获**: 记录技术发现、陷阱、注意事项。每条必须含 `### 模块/关键词` 字段
7. EVOLUTION_PROPOSALS.md — 如建议规则/设计/技能改进

**设计偏离对齐**: 读取 DESIGN.md 对应章节，比较实际代码变更，如有偏离则生成最小设计更新补丁，提交到 EVOLUTION_PROPOSALS.md。

**LESSONS.md 上限检查**: 超过 20 条时触发认知蒸馏，提炼 3-5 条规则到 RULES.md 提案，然后归档旧条目。

**收口后验证**:
1. 回读 NEXT.md — 验证包含有效未完成任务 ID 或确切文本 `no active task`。拒绝"就绪中"/"ready"/"idle"/"等待"/空/占位符 — 发现则立即重新执行更新。
2. 回读 STATUS.md — 验证 TL;DR 提及完成任务 + 里程碑章节非模板占位符 + 进度计数正确。
3. 回读 TASKS.md — 验证完成任务标记为 `[x]`。
4. 任一验证失败 → 立即重新执行失败的更新。全部通过后才输出 EVOLUTION_LOG。

**输出格式**:
```
## 🗂️ Phase Closeout

### 完成任务
（Task ID + 名称）

### 设计偏离更新（如有）
- [ ] 偏离检测已记录：(摘要或"无设计偏离")
- [ ] EVOLUTION_PROPOSALS.md 已提交：(Proposal ID)

### ✅ 文档更新完成确认

| 文件 | 状态 | 更新内容 |
|------|------|---------|
| TASKS.md | ✅ 已更新 | Task {ID} 标记为 [x] |
| STATUS.md | ✅ 已更新 | 追加阶段总结，更新时间戳 |
| NEXT.md | ✅ 已更新 | Active = Task {next_ID} |
| TEST_LOG.md | ✅ 已更新 | 追加结构化测试记录 |
| DECISIONS.md | ✅ / ⏭️ | 记录决策 / 无新决策 |
| LESSONS.md | ✅ / ⏭️ | 记录教训 / 无新教训 |

**所有必须文档已更新，可以安全进入下一任务。**

### 下一 Active Task
（Task ID + 名称，或"无活跃任务"）

### ✅ Post-Closeout Verification
- NEXT.md: Active = Task {next_ID} ✓
- STATUS.md: TL;DR ✓ + 里程碑执行状态 ✓ + 进度计数 ✓
- TASKS.md: Task {completed_ID} marked [x] ✓
All verifications passed. Closeout is complete.

📂 EVOLUTION_LOG
[时间] {ISO-8601}
[触发] Task {ID} 测试通过
[变更] .ai/TASKS.md: 标记 Task {ID} 为已完成
[变更] .ai/STATUS.md: 追加阶段总结 + 更新里程碑状态
[变更] .ai/NEXT.md: Active = Task {next_ID}
[建议] git add .ai/* && git commit -m "ai: closeout task {ID}" && git tag v{version}

### 🔄 下一会话推荐启动提示词
> 继续项目
```

收口后建议用户开启新对话。不自动开始下一任务。

---

## Mode 6: Skill Evolution Proposal

**触发条件**: 重复的流程问题、规则缺陷或优化机会；用户说"优化规则 / evolve"。

**规则**:
- 积极捕获和记录项目特定教训到 LESSONS.md。
- 不直接修改本技能、RULES.md、DESIGN.md、TASKS.md 结构。
- 写提案到 EVOLUTION_PROPOSALS.md。
- 用户批准后才可应用提案。

**每条提案必须包含**:
- Proposal ID (PROPOSAL-NNNN)
- 观察到的问题
- 证据
- 建议变更
- 目标文件
- 预期收益
- 风险
- 范围（项目特定 / 通用）
- 是否需要审批（是）
- 状态（Proposed / Approved / Rejected / Applied）

**输出格式**:
```
## 🧬 Evolution Proposal

### PROPOSAL-{ID}: {Title}

| Field | Content |
|-------|---------|
| 问题 | ... |
| 证据 | ... |
| 建议变更 | ... |
| 目标文件 | ... |
| 预期收益 | ... |
| 风险 | ... |
| 范围 | 项目特定 / 通用 |
| 需要审批 | 是 |
| 状态 | Proposed |
```

---

## Mode 6.5: Apply Approved Proposal

**触发条件**: 用户说"应用提案 [ID]"或"apply proposal [ID]"（不区分大小写）。

**动作**:
1. **定位并验证**: 在 EVOLUTION_PROPOSALS.md 中找到指定提案 ID，检查状态为 `Proposed` 或 `Approved`。
2. **提取变更**: 解析文本补丁、文件路径和目标行。
3. **执行修改**: 读取目标文件，精确应用变更，确保文件结构完整性和语法正确性。
4. **更新提案状态**: 在 EVOLUTION_PROPOSALS.md 中将状态从 `Proposed/Approved` 改为 `Applied`。
5. **触发编译钩子**: 若修改的是本技能本身，通知用户或执行 `python tools/adapter_generator.py` 重新生成所有 IDE 适配器。
6. **记录进化**: 在 EVOLUTION_LOG 块中记录修改。
