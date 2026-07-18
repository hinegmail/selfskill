# Mode Reference — Full Output Templates

> **📖 When to read this file**: Read the specific `### Mode N` section of this file when you are about to produce output for that mode for the **first time** in a conversation session. The compact IDE adapter only contains triggers and key rules — it does NOT contain the full output template format.
>
> **How to read efficiently**: Do NOT read the entire file. Use chapter-anchor navigation — search for `### Mode N:` heading, read only until the next `### Mode` or `##` heading.
>
> **Fallback**: If this file does not exist, the compact rules in the IDE adapter are sufficient for basic operation. Output will be simpler but functional.
>
> **Mandatory read trigger**: Mode 2 (Task Planning) **requires** reading this file's §Mode 2 section before producing the Three Confirmations output. See skill.md §4 Mode 2 Action 0.

---

## 4. Seven-Mode Execution Engine

You must follow these modes sequentially unless the user explicitly requests a specific mode. Do not skip modes. Do not jump from implementation to the next task.

### Mode 0: Initialization

**Trigger**: Any of the following:
- `.ai/STATUS.md` or `.ai/NEXT.md` is **missing**
- `.ai/STATUS.md` or `.ai/STEERING.md` contains **template placeholders** (detect by scanning for: `{待`, `{待AI`, `{待填写`, `{待更新`, `{待提取`, `Milestone 1]` with `(未开始)`, `0 / 0 任务`, `项目名称` as literal text)
- User says "启动项目 / 初始化项目 / setup / initialize / init"

**Actions**:
1. Read `.ai/requirements.md`, `.ai/DESIGN.md`, `.ai/TASKS.md` (if they exist).
2. **Placeholder Detection Scan**: For each `.ai/` runtime file (STATUS.md, STEERING.md, NEXT.md, TASKS.md), scan its content for template placeholder patterns. Classify each file as:
   - **✅ Populated** — contains real project data, no placeholders
   - **⚠️ Template** — still contains placeholder text (e.g., `{待...}`, `项目名称`, `Milestone 1]` with no real name, `0 / 0`)
   - **❌ Missing** — file does not exist
3. If `requirements.md`, `DESIGN.md`, `TASKS.md` exist and contain real project data (not placeholders):
   - **Auto-extract and populate** all ⚠️/❌ runtime files:
     - **STEERING.md**: Extract project name, core value, tech stack from `requirements.md`. Extract architecture modules from `DESIGN.md`. Extract milestones from `TASKS.md`. Build the INDEX chapter mapping. Write complete content.
     - **STATUS.md**: Extract project name. Count tasks in TASKS.md → set `项目整体进度`. Extract current phase/milestone from TASKS.md → set `当前开发阶段`. Set `当前活跃任务` from the first `[ ]` task. Populate `## 📈 里程碑执行状态` with all milestones from TASKS.md and their task counts. Set `last_audit_timestamp` to current UTC. Write TL;DR summary.
     - **NEXT.md**: Find the first `[ ]` task in TASKS.md. Write it as Active Task with its acceptance criteria. Ensure file paths reference the current project, not template source paths.
     - **TASKS.md** (if still template): Launch Interactive Setup Wizard (see step 5).
   - Write all populated files using file tools.
4. If `requirements.md`/`DESIGN.md`/`TASKS.md` are also placeholders or missing:
   - Proactively launch the **Interactive Setup Wizard (交互式初始化向导)**.
   - Ask the user 3 key design questions in the chat:
     - ① **项目名称**与核心商业价值定位是什么？
     - ② 核心**技术栈**与工程框架是什么？
     - ③ **核心功能职责与模块**如何规划？
   - Once the user answers, automatically generate the initial skeleton files for `requirements.md`, `DESIGN.md`, and `TASKS.md`, then execute step 3 to populate STEERING.md, STATUS.md, NEXT.md.
5. **Do not implement any code.** Wait for user confirmation.

**Output**:
```
## 🚀 Initialization

### Placeholder Detection Scan
| File | Status | Action |
|------|--------|--------|
| requirements.md | ✅ Populated / ⚠️ Template / ❌ Missing | (action taken) |
| DESIGN.md | ... | ... |
| TASKS.md | ... | ... |
| STEERING.md | ... | ... |
| STATUS.md | ... | ... |
| NEXT.md | ... | ... |

### Auto-Extracted Content
（summary of what was extracted and written）

### Files Requiring User Input
（if wizard was launched, list questions）

### Recommended Next Step
Confirm the auto-extracted content (or answer the wizard questions), then enter Context Audit mode.
```

---

### Mode 1: Context Audit（上下文审计）

**Trigger**: Every conversation start; user says "继续项目 / continue project / 继续开发 / continue / 同步状态 / sync".

**Actions**:
1. **TL;DR First Read (Token Economy)**:
   - Read the `## TL;DR` section of `.ai/STATUS.md` first (first 5 lines only).
   - If TL;DR indicates "no changes since last session" and `last_audit_timestamp` is recent, skip the full STATUS.md read.
   - **Micro Mode shortcut**: If only `NEXT.md` + `STATUS.md` exist in `.ai/`, skip STEERING.md, skip timestamp check. Read STATUS.md TL;DR only.
2. **Timestamp-based Smart Load (时间戳智能审计过滤)**:
   - Read `.ai/STATUS.md` full content if TL;DR check above determined a full read is needed. Retrieve the `last_audit_timestamp` value (format: `YYYY-MM-DDTHH:MM:SSZ`).
   - **Attempt to read file modification time** of `.ai/requirements.md` and `.ai/DESIGN.md`:
     - On Unix/macOS: execute `stat -c %Y <file>` (returns epoch seconds) or `date -r <file> +%s`
     - On Windows (PowerShell): execute `(Get-Item <file>).LastWriteTimeUtc.ToString('o')`
     - If the shell tool is unavailable or returns an error: **fall back to full re-audit** (treat as timestamps not matching). Do not guess or assume files are unchanged.
   - **Timestamp comparison logic**:
     - Convert `last_audit_timestamp` from STATUS.md to epoch seconds for comparison.
     - Compare with the file's mtime. If the difference is **≤ 60 seconds** (tolerance for filesystem precision):
       - **Skip reading** these two large files. Load roadmap and chapter index from `STEERING.md` only.
     - If the difference exceeds 60 seconds, mtime is unreadable, or `last_audit_timestamp` is missing/empty/placeholder:
       - Perform a full re-audit by reading `requirements.md` and `DESIGN.md`. Prepare to update `last_audit_timestamp` during Mode 5.
   - **STEERING.md reading is mandatory in all cases** — it is never skipped regardless of timestamp result.
3. **Placeholder Detection (占位符检测)**: If `.ai/STEERING.md` or `.ai/STATUS.md` or `.ai/NEXT.md` contain template placeholder text (scan for: `{待`, `{待AI`, `{待填写`, `{待更新}`, `{待提取}`, `Milestone 1]` with `(未开始)` and no real name, `0 / 0`, `项目名称` as literal text, or `就绪中`):
   - **Do NOT proceed with normal audit.** Output a warning and redirect to **Mode 0: Initialization** to execute auto-extraction.
   - > ⚠️ [Template Placeholder Detected] The following files still contain template placeholders: {list files}. Redirecting to Mode 0 for auto-extraction and population.
4. **Adaptive Rule Reload (扩展规则热加载)**:
   - Check if `.ai/RULES.md` exists. If it exists and contains custom guidelines or evolved conventions:
     - **Must read** `.ai/RULES.md` and merge its rules/conventions into the active context instructions. This ensures that even in non-compiled environments, the AI dynamically adapts to evolved instructions.
5. **Closeout Integrity Check (收口完整性校验)**:
   - Cross-validate consistency between TASKS.md, STATUS.md, and NEXT.md to detect an incomplete Mode 5 from the previous session:
     - **Check A (NEXT.md vs TASKS.md)**: Read the active task ID in NEXT.md. Search for that task in TASKS.md. If the task is already marked `[x]` (completed), this means the previous session's Mode 5 updated TASKS.md but failed to update NEXT.md.
     - **Check B (TASKS.md vs STATUS.md)**: Find the most recently completed task (latest `[x]`) in TASKS.md. Check if STATUS.md's phase summary or TL;DR mentions that task. If not, the previous session's Mode 5 updated TASKS.md but failed to update STATUS.md.
     - **Check C (NEXT.md idle-state detection)**: NEXT.md is in an idle state if it is empty, contains placeholder text, says "no active task", OR **has content but does not contain a valid task ID** (e.g., says "就绪中", "ready", "idle", "等待", or any other free-form non-task text). If NEXT.md is in idle state but TASKS.md has uncompleted tasks (`[ ]`), the previous session's Mode 5 failed to set the next active task.
   - **If any check fails**: Output a prominent warning and enter **Recovery Protocol**:
     > ⚠️ [Closeout Integrity Alert] Previous session's Mode 5 (Phase Closeout) was not fully completed. Detected issue: {describe which check failed}.
     > 
     > **Recovery Protocol**: I will now complete the missing Mode 5 updates before proceeding:
     > 1. Update STATUS.md with the completed task's phase summary + TL;DR + timestamp.
     > 2. Regenerate NEXT.md with the next uncompleted task from TASKS.md.
     > 3. Output EVOLUTION_LOG for the recovery.
     > 
     > After recovery, I will re-run the NEXT.md gate validation.
   - **Micro Mode**: Skip Check B (no TASKS.md). Only perform Check A (if NEXT.md task is done, set next task) and Check C.
6. **Idle-State Task Selection (空闲态任务选定)**:
   - If Check C determined that NEXT.md is in idle state (including: says "no active task", has non-task content, or is empty) AND TASKS.md has uncompleted tasks (`[ ]`):
     - Select the **first uncompleted task** from TASKS.md (respecting task dependencies and phase order).
     - **Write it into NEXT.md** as the new active task (with Task ID, name, and acceptance criteria).
     - This update is **BLOCKING** — must be completed before proceeding to step 7.
     - Do NOT enter Mode 2 or produce any planning output until NEXT.md contains a valid active task.
   - If NEXT.md is in idle state AND all tasks in TASKS.md are completed: Proceed to audit report output. NEXT.md stays as "no active task".
   - **Micro Mode**: If NEXT.md is idle and no TASKS.md exists, ask the user what the next task should be and write it into NEXT.md.
7. Validate the NEXT.md gate (see §5).
8. **Micro Mode Auto-Upgrade Detection (微型模式自动升级检测)**:
   - If running in Micro Mode (only `NEXT.md` + `STATUS.md` + `LESSONS.md` exist), evaluate the active task's complexity:
     - **Upgrade signal**: The task description in NEXT.md contains **≥ 3 acceptance criteria** OR references **> 5 files** OR involves multi-step phases (e.g., "first do X, then do Y").
     - **Action when upgrade signal triggers**: Output a prominent recommendation:
       > ⚠️ [Mode Upgrade Suggestion] This task has grown beyond Micro Mode scope (N criteria, M files). Consider upgrading to Lite Mode by running: `init.ps1 -Lite -Force` (Windows) or `./init.sh --lite --force` (macOS/Linux). This will add planning files (requirements.md, DESIGN.md, TASKS.md, STEERING.md) without overwriting existing ones.
     - Do **not** force the upgrade — proceed with Micro Mode if the user confirms, but warn that planning files will be unavailable.
9. Output the audit report.
10. **Do not modify any code files.**

**Output**:
```
## 🧭 Context Audit

### 当前产品目标
（1-2 sentences from PRD）

### 当前阶段与状态
（phase, completed tasks count / total, test status）

### STATUS.md 实况
（key facts from STATUS.md）

### 唯一允许执行的下一任务
（from NEXT.md — Task ID + name）

### 相关设计约束
（relevant DESIGN.md sections）

### 涉及文件
- 需检查：...
- 预计修改：...

### 已知约束与风险
（from RULES.md, LESSONS.md, STATUS.md）

### 本次不会做的事（Non-goals）
（explicit scope boundaries）

### 文档冲突或警告
（if any）

### 推荐下一模式
Task Planning
```

**If `.ai/STATUS.md`, `.ai/NEXT.md`, or `.ai/STEERING.md` is missing, or contains default placeholder templates**: Enter Initialization mode instead.

---

### Mode 2: Task Planning（任务规划 + 三项确认）

**Trigger**: Context Audit completed and user confirms; or user says "开始阶段 X / 执行 Task Y / plan / start task".

**Precondition**: Context Audit must be completed. NEXT.md gate must pass.

**Actions**:
0. **Mandatory Mode Reference Load (强制模板加载)**:
   - If you have **NOT** read `.ai/MODE_REFERENCE.md` in this session, you **MUST** read it before producing any Mode 2 output. The compact adapter only contains triggers; the full output template is in MODE_REFERENCE.md §Mode 2.
   - Read only the `### Mode 2` section (not the entire file) using chapter-anchor navigation.
   - If `.ai/MODE_REFERENCE.md` does not exist, fall back to the compact rules in the adapter — output will be simpler but functional.
1. Plan implementation for the single active task in `.ai/NEXT.md`.
2. **Mandatory Lessons Query (历史避坑强制检索)**:
   - The AI **must** use `grep_search` to search `.ai/LESSONS.md` against the `### 模块/关键词` field, using module names and keywords extracted from the current task (e.g., database table names, API names, component names).
   - Search strategy: run `grep_search` for each key term from the current task against `LESSONS.md`. Prioritize matches in `### 模块/关键词` fields, then fall back to full-text matches.
   - If any matched lessons are found, they **must** be cited under "历史避坑经验" in the plan, including the LESSON ID and the recommended behavior.
3. Execute the **Three Confirmations Protocol** (三项确认):
   - ① My understanding of the task objective (1-2 lines)
   - ② Technical implementation path + involved files/interfaces (incorporating findings from LESSONS.md)
   - ③ First minimum deliverable
4. List acceptance criteria, risks, and non-goals.
5. **Do not modify any code files.** Wait for user confirmation.

**Micro Mode shortcut**: Skip Three Confirmations. Output a 3-line quick plan: ① Goal ② Files to modify ③ First step. Wait for "执行".

**Output**:
```
## 📋 Task Plan

### 任务
（Task ID + name）

### 历史避坑经验（如有）
（lessons cited from LESSONS.md）

### 目标理解（三项确认 ①）
（1-2 lines）

### 技术路径与涉及文件（三项确认 ②）
- 需检查文件：...
- 预计修改文件：...

### 首个最小可交付物（三项确认 ③）
（what will be delivered first）

### 验收标准
（line-by-line from TASKS.md / NEXT.md）

### 实现步骤
1. ...
2. ...

### 需求来源
（reference requirements.md sections）

### 设计依据
（reference DESIGN.md sections）

### 风险
（potential issues）

### 本次不会做的事（Non-goals）
（explicit boundaries）

---

🚀 **规划完成，准备就绪！**

以上规划已完成检查，技术路径清晰，验收标准明确。

您现在可以：
① 说 **"执行"** 或 **"开始"** → 我立即进入实现模式开始编码
② 提出 **疑问或建议** → 我调整规划
③ 要求 **重新规划** → 我重新分析任务

等待您的下一步指令...
```

---

### 3.1 Mode 2→Mode 3 Automatic Transition Triggers（自动转换触发器）

**Purpose**: Define the complete set of user expressions and patterns that automatically trigger Mode 3 entry.

**Key Principle**: User does NOT need to memorize special commands. Any natural affirmative response will work.

### Affirmative Triggers (肯定信号 - 任何一个都自动进入Mode 3)

**Direct Execution Commands**:
- "执行" / "执行这个" / "执行任务" / "执行规划"
- "开始" / "开始实现" / "开始编码" / "开始编写"
- "确认" / "批准" / "同意" / "认可"
- "可以" / "可以开始" / "没问题" / "没有问题"
- "好的" / "好" / "嗯" / "明白了"
- "OK" / "okay" / "好吧" / "走起"
- "继续" / "继续开发" / "我们继续"

**Affirmative Responses to "准备就绪" Prompt**:
- "是的" / "对" / "对的" / "对的吗" (positive confirmation)
- "很好" / "看起来不错" / "不错"
- 任何不含"不"、"改"、"重"的简短回复都视为肯定

**Emoji/Shorthand**:
- "👍" / ":+1:" / "✓" / "✅"
- "🚀" (rocket = let's go)

### Technical Question → Auto-Transition Pattern

**When user asks implementation-related questions**:
- "这里是不是应该用X技术?" 
- "需要考虑性能吗?"
- "用什么库?"
- "怎么处理Y场景?"
- 任何以 "?" 结尾且与实现相关的问题

**Behavior**: 
AI answers the question, then **automatically enters Mode 3** to proceed with implementation.

### Rejection/Modification Triggers (拒绝信号 - 回到Mode 2重新规划)

**Explicit Rejection**:
- "重新规划" / "改一下" / "改改" / "重来"
- "我不同意" / "有问题" / "不对" / "不行"
- "这样不行" / "不好" / "有问题"

**Modification Requests**:
- "改改XX部分"
- "XX改成Y"
- "不用这个库"

**When rejection detected**: AI stays in Mode 2 and asks "哪里有问题？请告诉我。"

### Auto-Detection Algorithm (自动检测算法)

```
if user_message in affirmative_triggers_list:
    ENTER_MODE_3()
    
elif contains_any(user_message, affirmative_patterns):
    ENTER_MODE_3()
    
elif contains_any(user_message, technical_question_patterns):
    AI_answers_question()
    ENTER_MODE_3()
    
elif contains_any(user_message, rejection_triggers):
    REMAIN_IN_MODE_2()
    ASK_CLARIFICATION("哪里需要调整？")
    
else:
    REQUEST_DIRECTION("您希望我: (1)执行规划, (2)调整规划, 还是(3)讨论细节?")
```

---

### Mode 3: Task Implementation（任务实现）

**Trigger**: User provides affirmative signal matching Mode 2→3 Automatic Transition Triggers (see §3.1 above), OR user begins asking implementation-related technical questions.

**Precondition**: Mode 2 output generated. NEXT.md gate valid.

**Auto-Entry Logic**:
- AI scans user's response for trigger words/patterns from the Transition Triggers list
- If match found: **AUTOMATICALLY ENTER MODE 3** (no explicit permission needed)
- If rejection words detected: remain in Mode 2, ask for clarification instead
- If ambiguous: request explicit direction

**Iron Rules**:
1. Only implement the active task in `.ai/NEXT.md`.
2. Do not execute future tasks.
3. Do not expand requirements beyond `.ai/requirements.md`.
4. Do not refactor unrelated modules.
5. Do not rewrite tested modules unless the current task requires it.
6. Do not change public interfaces unless the current task requires it or user approves.
7. Do not introduce new dependencies unless the current task requires it or user approves.
8. If documents and code conflict, **stop and report**.
9. If the task description is ambiguous, **stop and ask for clarification**.

**Output** (after implementation):
```
## 🛠️ Task Implementation

### 任务
（Task ID + name）

### 当前进度
✓ Mode 1: Context Audit 完成
✓ Mode 2: Task Planning 完成  
▶️ Mode 3: Task Implementation 进行中

### 执行说明
- 我现在开始实现Task中的功能需求
- 实现完成后自动进入Mode 4: Validation & Test
- 如需中止，您可以随时说"停止"或"暂停"

---

### 修改的文件
（file-by-file list）

### 变更说明
（what changed and why, per file）

### 验收标准检查
- [x] Criterion 1 — satisfied
- [x] Criterion 2 — satisfied
- [ ] Criterion 3 — needs testing

### 建议测试命令
（commands to run）

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

**Do not automatically start the next task.**

---

### Mode 4: Validation & Test Repair（验证与测试修复）

**Trigger**: Implementation completed; or user provides test results / error logs.

**Actions**:
1. Run or recommend the smallest relevant test set.
2. Record all test activity in `.ai/TEST_LOG.md`.
3. **Context Health Check (上下文健康度自检)**:
   Before starting any test-fix loop, evaluate the following signals. If **2 or more** are true, output a health warning and recommend starting a new conversation after the current task closes out:

   | Signal | Check |
   |--------|-------|
   | 🔴 Fix iterations | Current test-fix-retest cycle count ≥ `mitigation_threshold` (default: 3) |
   | 🟠 Conversation turns | Estimated turns in current chat session > 30 |
   | 🟠 Error log volume | Total error/traceback output processed this session > 200 lines |
   | 🟡 Memory references | AI is referencing details not in any `.ai/` file (relies on chat memory) |
   | 🟡 Scope drift | Current work is touching files or tasks beyond what `.ai/NEXT.md` specifies |

   **Output format when 2+ signals trigger**:
   > ⚠️ **[Context Health Warning]** {N}/5 health signals active: {list triggered signals}.
   > Recommend completing the current task, running Mode 5 Closeout, then starting a fresh conversation.
   > Files are up-to-date in `.ai/` — a new conversation will reload clean state automatically.

**Context Blurring Mitigation Protocol (Context Compression Safeguard)**:
- **Iteration Limit**: The AI must check the custom `mitigation_threshold` configuration in `.ai/RULES.md` (defaulting to 3 if the configuration is missing or empty). If the test-fix-retest loop in the current conversation session exceeds this threshold, the AI **must** halt development.
- **Action (Root Cause Compaction)**:
  - The AI **must** consolidate and analyze the root causes of the consecutive failures across these iterations (e.g., compile a brief post-mortem of why previous fixes failed and what is the core mismatch).
  - Write a **"Root Cause Analysis (根因诊断反思)"** list directly into `.ai/TEST_LOG.md`.
  - Output a prominent notice requesting the user to start a new clean session:
    > *⚠️ [Context Alert] Current test-fix cycle has exceeded the limit of {threshold} iterations. To prevent cognitive decay and save tokens, I have compiled a Root Cause Analysis and saved it to `.ai/TEST_LOG.md`. Please start a NEW conversation and say "继续项目" to reload clean memory.*
- **Log Compactor**: Never paste or process raw terminal output longer than 50 lines in chat. Compress terminal outputs to list only failing test files, test names, error messages, and line numbers.

**If tests fail**:
- Fix **only** current-task-related failures.
- Do not add new features.
- Do not refactor unrelated modules.
- Do not change task scope.
- Do not start the next task.

**For each failure, record**:
- Failing command
- Error summary
- Root cause analysis
- Files changed for fix
- Retest command
- Retest result

**Output**:
```
## ✅ Validation Result

### 任务
（Task ID + name）

### 测试命令
（commands executed）

### 结果
（pass / fail summary）

### 失败项（如有）
| # | 失败命令 | 错误摘要 | 根因 | 修复文件 | 复测结果 |
|---|---------|---------|------|---------|---------|
| 1 | ... | ... | ... | ... | ✅ Pass |

### 最终验证状态
✅ 全部通过 / ❌ 仍有未解决项

### 推荐下一模式
Phase Closeout（如全部通过）
```

**When all tests pass**: Automatically enter Mode 4.5: Document Sync Check. Do not start new development.

---

### Mode 4.5: Document Sync Check（文档同步检查）

**Trigger**: Tests pass in Mode 4; automatic entry.

**Actions**:
1. **Document Update Requirements Check**:
   - Check if `.ai/TASKS.md` needs task status marked as `[x]`
   - Check if `.ai/STATUS.md` needs phase summary appended
   - Check if `.ai/TEST_LOG.md` needs test conclusion appended
   - Check if `.ai/DESIGN.md` needs design deviation alignment
   - Check if `.ai/LESSONS.md` needs new lessons recorded
2. **Force Mode 5 Entry**: If any document needs updating, automatically enter Mode 5: Phase Closeout.
3. **Output Sync Report**: Display which documents need updates.

**Output**:
```
## 📋 Document Sync Check

### Current Task
（Task ID + name）

### Documents Requiring Update
- [ ] TASKS.md - 需要标记 Task X 为 [x]
- [ ] STATUS.md - 需要追加阶段总结
- [ ] TEST_LOG.md - 需要追加测试结论
- [ ] DESIGN.md - 无设计偏离（或：需要对齐设计偏离）
- [ ] LESSONS.md - 无新教训（或：需要记录新教训）

### Recommended Action
进入 Mode 5: Phase Closeout 完成文档更新

### 推荐下一模式
Phase Closeout
```

**If all documents are already up-to-date**: Skip Mode 5 and recommend starting a new conversation.

---

### Mode 5: Phase Closeout（阶段收口）

**Trigger**: Validation passes; or user says "测试通过 / 阶段完成 / 收口 / closeout / tests passed / phase complete".

**Precondition**: Current task or phase has passed validation.

**Actions & Document Alignments**:
1. **Design Deviation Alignment (设计偏离智能对齐)**:
   - Read the corresponding design section of `DESIGN.md` (via line range index in `steering.md`).
   - Compare the actual code changes against the design. If any architectural deviations exist (e.g., database schema changes, new endpoint interfaces, different variable styles):
     - The AI **must** generate a minimum design update patch.
     - Propose this patch in **`EVOLUTION_PROPOSALS.md`** (e.g., `PROPOSAL-DESIGN-UPDATE`) for user approval, instead of rewriting the entire DESIGN.md.
2. **Audit Timestamp Baseline**:
   - Update `last_audit_timestamp` in `.ai/STATUS.md` to the current UTC timestamp, establishing a successful baseline for the timestamp-based smart loading in the next session.

**Must update the following files (BLOCKING - required before next task)**:
1. `.ai/TASKS.md` — mark completed task as `[x]`
2. `.ai/STATUS.md` — Update **all** of the following sections:
   - **`## TL;DR`**: one-sentence status summary
   - **Metadata fields**: `更新时间`, `项目整体进度` (count `[x]` tasks in TASKS.md / total), `当前开发阶段`, `当前活跃任务`, `当前测试状态`, `last_audit_timestamp`
   - **`## 📈 里程碑执行状态`**: This section **must be updated** using the following procedure:
     1. Read `.ai/TASKS.md` and identify all milestones/phases and their tasks
     2. For each milestone, count tasks marked `[x]` (completed) vs total tasks
     3. Update each milestone line with actual name, count, and status:
        - `* **[Milestone X: 名称]** (未开始) — 0/N tasks` ← no tasks started
        - `* **[Milestone X: 名称]** (进行中) — M/N tasks` ← some but not all done
        - `* **[Milestone X: 名称]** (✅ 已完成) — N/N tasks` ← all done
     4. **Remove all placeholder text** (e.g., `{待提取}`, `Milestone 1`, `(未开始)`) and replace with actual project data
     5. If this is the first closeout and the section still has template placeholders, **populate it from scratch** using TASKS.md milestone/phase structure
   - **`## 📂 历史审计日志`**: Append phase summary (reverse chronological): completed features, key files, technical decisions, known issues
   - **`## 🛑 风险、阻塞`**: Update if any new blockers or design deviations occurred
3. `.ai/NEXT.md` — regenerate with exactly one next active task; if none, state **exactly** `no active task` (this is the **only** valid idle-state expression — do NOT use "就绪中", "ready", "idle", "等待" or any other free-form text)

**Micro Mode shortcut**: In Micro Mode, update only `NEXT.md`, `STATUS.md` (TL;DR + timestamp), `LESSONS.md`. Skip all other document updates.

**LESSONS.md Cap Check**: If `.ai/LESSONS.md` contains more than 20 entries, trigger Cognitive Distillation (see §6). Propose merging top 3-5 recurring lessons into `RULES.md`, then archive old entries.

**Conditionally update the following files (OPTIONAL - but recommended)**:
4. `.ai/TEST_LOG.md` — append final test conclusion (only if test records exist)
5. `.ai/DECISIONS.md` — if design deviations or important decisions were made
6. `.ai/LESSONS.md` — **Mandatory knowledge capture**: Record any technical findings, pitfalls, or notes from this task
   - **Each entry must include a `### 模块/关键词` field** listing the relevant module names and technical keywords (comma-separated), enabling precise grep retrieval in future Mode 2 sessions.
   - Even without errors, record:
     - New technical details discovered
     - API usage considerations
     - Special configuration requirements
     - Any information that may be valuable for future reference
   - Only skip if absolutely nothing worth recording exists (must provide reason)
7. `.ai/EVOLUTION_PROPOSALS.md` — if rule, design, or Skill improvements are recommended (including design sync patch)

**Output**:
```
## 🗂️ Phase Closeout

### 完成任务
（Task ID + name）

### 设计偏离更新（如有）
- [ ] 偏离检测已记录：(Brief summary or "无设计偏离")
- [ ] EVOLUTION_PROPOSALS.md 已提交：(Proposal ID)

### ✅ 文档更新完成确认

| 文件 | 状态 | 更新内容 |
|------|------|---------|
| TASKS.md | ✅ 已更新 | Task {ID} 标记为 [x] |
| STATUS.md | ✅ 已更新 | 追加阶段总结，更新时间戳 |
| NEXT.md | ✅ 已更新 | Active = Task {next_ID} |
| TEST_LOG.md | ✅ 已更新 / ⏭️ 跳过 | 追加测试结论 / 无测试记录 |
| DECISIONS.md | ✅ 已更新 / ⏭️ 跳过 | 记录关键决策 / 无新决策 |
| LESSONS.md | ✅ 已更新 / ⏭️ 跳过 | 记录新教训 / 无新教训 |

**所有必须文档已更新，可以安全进入下一任务。**

### 已更新文档详情
- STATUS.md: （what was updated, including audit baseline timestamp）
- TASKS.md: （what was marked）
- TEST_LOG.md: （final conclusion, if applicable）
- NEXT.md: （next active task）
- [DECISIONS.md]: （if applicable）
- [LESSONS.md]: （if applicable）

### 修改的代码文件
（summary list）

### 测试结果
（final pass/fail summary）

### 关键决策（如有）
（brief description）

### 经验教训（如有）
（brief description）

### 下一 Active Task
（Task ID + name, or "无活跃任务"）

📂 EVOLUTION_LOG
[时间] {ISO-8601}
[触发] Task {ID} 测试通过
[变更] .ai/TASKS.md: 标记 Task {ID} 为已完成
[变更] .ai/STATUS.md: 追加阶段总结 + 更新里程碑状态
[变更] .ai/NEXT.md: Active = Task {next_ID} (或 "no active task")
[建议] git add .ai/* && git commit -m "ai: closeout task {ID}" && git tag v{version}

### 🔄 下一会话推荐启动提示词
> 继续项目
```

**Post-Closeout Verification (收口后验证)**:
After writing all BLOCKING and conditional updates, the AI **must** perform a self-check before outputting the final EVOLUTION_LOG:
1. **Read back** `.ai/NEXT.md` — verify it contains either:
   - A **valid next task** (Task ID + name that exists in TASKS.md as `[ ]`), OR
   - The **exact text** `no active task` (only if ALL tasks in TASKS.md are `[x]`)
   - **REJECT** any other content: "就绪中", "ready", "idle", "等待", empty, placeholder, or any free-form text without a valid Task ID. If NEXT.md contains any such invalid content, **re-execute the NEXT.md update immediately** — either set the next uncompleted task from TASKS.md, or write exactly `no active task`.
2. **Read back** `.ai/STATUS.md` — verify ALL of the following:
   - TL;DR mentions the task just completed
   - `## 📈 里程碑执行状态` section is **NOT** still template placeholder (must not contain `{待提取}`, `(未开始)` with `Milestone 1`, or `0 / 0`)
   - Milestone section reflects updated task counts (the completed task's milestone shows incremented count)
   - `项目整体进度` field shows correct completed/total count
   - If any sub-check fails, re-execute the STATUS.md update
3. **Read back** `.ai/TASKS.md` — verify the completed task is marked `[x]`.
4. **If any verification fails**: Re-execute the failed update immediately. Do NOT output EVOLUTION_LOG until all three checks pass.
5. **If all verifications pass**: Output the EVOLUTION_LOG block below.

**Output the verification result**:
```
### ✅ Post-Closeout Verification
- NEXT.md: Active = Task {next_ID} ✓ (valid uncompleted task in TASKS.md) [或 "no active task" ✓ if all tasks done]
- STATUS.md: TL;DR ✓ + 📈 里程碑执行状态 populated (no template placeholders) ✓ + 项目整体进度 count ✓
- TASKS.md: Task {completed_ID} marked [x] ✓
All verifications passed. Closeout is complete.
```

**After closeout**: Recommend user to start a new conversation for a clean context.

**Do not automatically start the next task.**

---

### Mode 6: Skill Evolution Proposal（技能进化提案）

**Trigger**: Repeated process issues, rule defects, or optimization opportunities observed; or user says "优化规则 / 更新约定 / propose / 进化 / optimize rules / evolve".

**Rules**:
- You **must** actively capture and record project-specific lessons to `.ai/LESSONS.md` during development.
- Do not wait for "obvious" errors — record any technical insights, API behaviors, configuration quirks, or implementation details that could help future tasks.
- You **must not** directly modify this Skill, `.ai/RULES.md`, `.ai/DESIGN.md`, or `.ai/TASKS.md` structure.
- You must write proposals to `.ai/EVOLUTION_PROPOSALS.md`.
- Only after user approval may a proposal be applied.

**Each proposal must include**:
- Proposal ID (PROPOSAL-NNNN)
- Problem observed
- Evidence
- Proposed change
- Target file
- Expected benefit
- Risk
- Scope (project-specific / general)
- Approval required (Yes/No)
- Status (Proposed / Approved / Rejected / Applied)

**Output**:
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

---

### Mode 6.5: Apply Approved Proposal（应用已批准提案）

**Trigger**: User says "应用提案 [ID]" or "批准并执行 [ID]" or "apply proposal [ID]" (case-insensitive).

**Actions**:
1. **Locate & Verify**: Find the specified proposal ID (e.g., `PROPOSAL-NNNN`) in `.ai/EVOLUTION_PROPOSALS.md`. Check that its current status is `Proposed` or `Approved`.
2. **Extract Changes**: Parse the exact text patches, file paths, and target lines defined in the proposal.
3. **Execute modifications**: Read the target file, apply the changes precisely, and ensure file structural integrity and syntax correctness.
4. **Update Proposal Status**: Modify the proposal's status field in `.ai/EVOLUTION_PROPOSALS.md` from `Proposed/Approved` to `Applied`.
5. **Trigger Compile Hook**: If the modified file is this Skill itself (within the `selfskill` codebase), proactively notify the user or execute `python tools/adapter_generator.py` to regenerate all IDE-specific adapters, keeping rules in sync.
6. **Log Evolution**: Document the modification in the required `EVOLUTION_LOG` block.
```

---

---

## 12. Security & Audit

- AI should only modify repository files after user authorization. Prefer PR-based or user-approved commits.
- All automated write-backs must include author/reason/timestamp metadata.
- After phase closeout, recommend Git commit with descriptive message and tag (e.g., `v0.2-phase2`).
- The AI must not execute destructive operations (database drops, production deployments) without explicit user instruction.
- **Git Hook State Linter (AI 状态强校验钩子)**:
  Recommend the user to create a Git pre-commit hook `.git/hooks/pre-commit` to prevent AI state hallucinations (e.g., claiming to update state but failing).
  
  Pre-commit Hook Script (`.git/hooks/pre-commit`):
  ```bash
  #!/bin/sh
  # ProjectOrchestrator Enhanced Integrity Linter - Git pre-commit hook

  # Check NEXT.md and TASKS.md consistency
  if [ -f ".ai/NEXT.md" ] && [ -f ".ai/TASKS.md" ]; then
    ACTIVE_TASK=$(grep -oE "Task [0-9]+\.[0-9]+" .ai/NEXT.md | head -n 1)
    if [ ! -z "$ACTIVE_TASK" ]; then
      # If task is marked complete [x] in TASKS.md but is still listed as Active in NEXT.md
      if grep -q "\[x\] $ACTIVE_TASK" .ai/TASKS.md && grep -q "Active = $ACTIVE_TASK" .ai/NEXT.md; then
        echo "❌ [ProjectOrchestrator Linter] Integrity Error: $ACTIVE_TASK is marked complete [x] in TASKS.md but is still set as Active in NEXT.md!"
        echo "Please update NEXT.md to set the next active task before committing."
        exit 1
      fi
    fi
  fi

  # Check STATUS.md timestamp update
  if [ -f ".ai/STATUS.md" ]; then
    LAST_UPDATE=$(grep "上次全局审计时间" .ai/STATUS.md | cut -d':' -f2 | xargs)
    if [ "$LAST_UPDATE" = "{待AI审计更新}" ] || [ "$LAST_UPDATE" = "{待更新}" ] || [ -z "$LAST_UPDATE" ]; then
      echo "⚠️ [ProjectOrchestrator Linter] Warning: STATUS.md last_audit_timestamp not updated"
      echo "Consider running Mode 5: Phase Closeout to update the timestamp."
    fi
  fi

  echo "✅ [ProjectOrchestrator Linter] Document integrity check passed"
  ```
