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

### ⚠️ Pre-Flight Check (预检 — 在所有模式之前执行，不可跳过)

**Before entering any mode (including Mode 0 or Mode 1), you MUST perform this check FIRST:**

1. Read `.ai/STATUS.md` and `.ai/STEERING.md` (first 10 lines each is enough).
2. Scan for template placeholder patterns: `{待`, `0 / 0 任务`, `项目名称` as literal text, `{待填写}`, `{待提取}`, `[Milestone 1]` with no real name, `{auth_middleware_name}`, `{语言`, `{spaces`, `{e.g.`. Scan across STATUS.md, STEERING.md, NEXT.md, **and RULES.md**.
3. **If ANY placeholder is found** → Immediately enter **Mode 0: Initialization** (auto-extraction). Do NOT proceed to Mode 1 or any other mode. Do NOT output an audit report. Do NOT ask "what would you like to do?" — just execute Mode 0 auto-extraction directly.
4. **If NO placeholders found** → Continue to the normal mode flow below.

> This check is **mandatory and non-negotiable**. It must run every time a conversation starts, before anything else. If you skip this check, all downstream modes will operate on empty/template data and produce incorrect results.

### Mode 0: Initialization

**Trigger**: Any of the following:
- `.ai/STATUS.md` or `.ai/NEXT.md` is **missing**
- `.ai/STATUS.md` or `.ai/STEERING.md` contains **template placeholders** (detect by scanning for: `{待`, `{待AI`, `{待填写`, `{待更新`, `{待提取`, `[Milestone 1]` with `(未开始)`, `0 / 0 任务`, `项目名称` as literal text)
- User says "启动项目 / 初始化项目 / setup / initialize / init"

**Actions**:
1. Read `.ai/requirements.md`, `.ai/DESIGN.md`, `.ai/TASKS.md` (if they exist).
2. **Placeholder Detection Scan**: For each `.ai/` runtime file (STATUS.md, STEERING.md, NEXT.md, TASKS.md), scan its content for template placeholder patterns. Classify each file as:
   - **✅ Populated** — contains real project data, no placeholders
   - **⚠️ Template** — still contains placeholder text (e.g., `{待...}`, `项目名称`, `[Milestone 1]` with no real name, `0 / 0`)
   - **❌ Missing** — file does not exist
3. If `requirements.md`, `DESIGN.md`, `TASKS.md` exist and contain real project data (not placeholders):
   - **Auto-extract and populate** all ⚠️/❌ runtime files:
     - **STEERING.md**: Extract project name, core value, tech stack from `requirements.md`. Extract architecture modules from `DESIGN.md`. Extract milestones from `TASKS.md`. Build the INDEX chapter mapping. Write complete content.
     - **STATUS.md**: Extract project name. Count tasks in TASKS.md → set `项目整体进度`. Extract current phase/milestone from TASKS.md → set `当前开发阶段`. Set `当前活跃任务` from the first `[ ]` task. Populate `## 📈 里程碑执行状态` with all milestones from TASKS.md and their task counts. Set `last_audit_timestamp` to current UTC. Write TL;DR summary.
     - **NEXT.md**: Find the first `[ ]` task in TASKS.md. Write it as Active Task with its acceptance criteria. Ensure file paths reference the current project, not template source paths.
     - **RULES.md**: Fill template placeholders using data extracted from `DESIGN.md` and `TASKS.md`:
       - `{auth_middleware_name}`: Extract from DESIGN.md auth/login section. If no formal middleware exists, write `无（基于 user_id 隔离）`.
       - `{语言 1}`: Extract primary language from DESIGN.md tech stack (e.g., `Python`).
       - `{风格指南，如 PEP 8 / ESLint + Prettier}`: Extract from TASKS.md coding standards section (e.g., `PEP 8 + mypy 类型检查`).
       - `{spaces / tabs}`: Infer from language convention (Python → `4 spaces`, Go → `tabs`, JS/TS → `2 spaces`).
       - `{e.g., 120}`: Set to `120` (universal default) or extract from project conventions if specified.
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
3. **Placeholder Detection (占位符检测)**: If `.ai/STEERING.md` or `.ai/STATUS.md` or `.ai/NEXT.md` contain template placeholder text (scan for: `{待`, `{待AI`, `{待填写`, `{待更新}`, `{待提取}`, `[Milestone 1]` with `(未开始)` and no real name, `0 / 0`, `项目名称` as literal text, or `就绪中`):
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

### Mode 2: Task Planning（任务规划与单卡开工契约 One-Card Gate）

**Trigger**: Context Audit completed and user confirms; or user says "开始阶段 X / 执行 Task Y / plan / start task".

**Precondition**: Context Audit must be completed. NEXT.md gate must pass.

**Actions**:
0. **Mandatory Mode Reference Load (强制模板加载)**:
   - If you have **NOT** read `.ai/MODE_REFERENCE.md` in this session, you **MUST** read it before producing any Mode 2 output.
   - Read only the `### Mode 2` section using chapter-anchor navigation.
1. Plan implementation for the single active task in `.ai/NEXT.md`.
2. **Mandatory Lessons Query (历史避坑强制检索)**:
   - The AI **must** use `grep_search` to search `.ai/LESSONS.md` against the `### 模块/关键词` field.
   - If matched lessons exist, cite them under "历史避坑经验".
3. **Generate One-Card Proposal Contract (单卡结构化开工契约)**:
   - ① **Task Objective (交付目标)**: 1-2 lines summarizing core goal.
   - ② **Impact Scope (影响范围)**: Explicit file list to inspect and modify.
   - ③ **JIT Tiered Acceptance Assertions (JIT 分级验收断言)**:
     - Tier 1: Syntax / Typecheck / Dry-run commands.
     - Tier 2: Specific automated test suite command (e.g. `pytest ...`, `npm test ...`) and expected exit code 0.
     - Tier 3: Manual smoke check steps (if UI or non-automatable).
   - ④ **First Minimum Deliverable (首个最小交付物)**.
   - ⑤ **Rollback Plan (回滚预案)**: How to revert if implementation breaks.
4. **Contract Freezing (开工契约冻结)**:
   - Once approved by the user, the acceptance assertions in this contract are **frozen and written to `.ai/NEXT.md`**.
   - The AI **MUST NOT** alter, weaken, or bypass these assertions in Mode 3 or Mode 4 (Anti-Collusion / 防自验作弊).
5. **Do not modify any code files.** Wait for user confirmation.

**Micro Mode shortcut**: Skip full contract card. Output a 3-line quick plan: ① Goal ② Files to modify ③ First step. Wait for explicit approval.

**Output**:
```markdown
## 📋 Task Plan (One-Card Gate)

### 任务卡片
- **Task ID**: {ID}
- **Title**: {Task Name}
- **Phase**: {Phase Name}

### 历史避坑经验（如有）
（lessons cited from LESSONS.md）

### 📋 任务开工契约 (Task Contract Card)
- **交付目标**: （1-2 lines）
- **影响范围**:
  - 需检查文件：...
  - 预计修改文件：...
- **JIT 验收断言 (Exit Criteria)**:
  1. [Tier 1 静态检查]: 命令与预期
  2. [Tier 2 自动化测试]: 测试命令（预期 Exit Code 0）
  3. [Tier 3 冒烟验证]: 关键路径行为确认
- **首个最小可交付物**: （what will be delivered first）
- **回滚预案**: （git revert / cleanup steps）

### 本次不会做的事（Non-goals）
（explicit boundaries）

---

🚀 **开工契约已生成，等待确认！**

请回复 **"确认执行"** / **"OK"** 批准开工契约并进入实现模式；或提出 **调整意见** 修改规划。
```

---

### 3.1 Mode 2→Mode 3 Transition Triggers（开工确认触发器）

**Affirmative Triggers (批准开工 - 锁定契约并进入 Mode 3)**:
- "确认" / "确认执行" / "批准" / "同意" / "执行" / "开始" / "开始实现"
- "OK" / "okay" / "没问题" / "可以开始" / "👍" / "🚀"

**Clarification / Question Pattern**:
- When user asks a technical or scope question: AI answers the question and stays in Mode 2 with the updated proposal card, waiting for the final affirmative confirmation. AI **MUST NOT** jump into Mode 3 on a question without user's explicit approval.

**Rejection / Modification Triggers**:
- "改一下" / "调整" / "重新规划" / "不同意" → Remain in Mode 2, adjust proposal.

---

### Mode 3: Task Implementation（任务实现与 Hard Stop 物理停机）

**Trigger**: User provides explicit affirmative signal approving Mode 2 contract card.

**Precondition**: Mode 2 contract card approved. NEXT.md gate valid.

**Iron Rules**:
1. **Scope Lock**: ONLY modify files specified in the approved Mode 2 contract.
2. **No Scope Creep**: Do not implement future tasks or unapproved features.
3. **No Phantom Code**: Every claimed functionality must be written into actual files.
4. **Hard Stop Principle (物理硬停机)**:
   - When coding is complete, the AI **MUST IMMEDIATELY STOP TURN**.
   - It is **STRICTLY FORBIDDEN** to automatically advance to Mode 4.5 or Mode 5.
   - The AI must output changed files and recommended test commands, and transition to `AWAITING_VERIFICATION` state.

**Output** (after implementation):
```markdown
## 🛠️ Task Implementation (Hard Stop)

### 任务
（Task ID + name）

### 当前进度
✓ Mode 1: Context Audit 完成
✓ Mode 2: Task Planning & Contract Approved
▶️ Mode 3: Task Implementation 已完成 (Hard Stop)

---

### 修改的文件 (Changed Files)
- `path/to/file1` (NEW / MODIFIED) - 说明
- `path/to/file2` (MODIFIED) - 说明

### 变更摘要
（what changed and why, per file）

### 冻结契约验收检查
- [ ] Tier 1 静态检查: 待运行
- [ ] Tier 2 自动化测试: 待运行
- [ ] Tier 3 冒烟验证: 待确认

### 建议测试命令
```bash
{test_command_from_contract}
```

---

✋ **实现已完成，已进入物理停机状态 (Awaiting Verification)！**

请选择下一步操作：
1. 回复 **"运行测试"** / **"执行验证"** → 进入 Mode 4 运行自动化验证
2. 回复 **"测试通过"**（附带测试结果） → 进入 Mode 5 进行物理收口与 Git 提交
3. 回复 **"需要修改"** → 继续在 Mode 3 调整代码
```

### Mode 4: Validation & Anti-Collusion Test（分级验证与防作弊测试）

**Trigger**: User says "运行测试" / "执行验证" / "validate" / "run tests"; or user provides test results / error logs.

**Precondition**: Mode 3 implementation completed. Code changes exist.

**Actions**:
1. **Execute Tiered Verification (执行分级验收)**:
   - **Tier 1 (Static/Lint)**: Run syntax check, typecheck (`tsc`, `mypy`, `ruff`, etc.), or dry-run.
   - **Tier 2 (Automated Test Suite)**: Execute the project's native test runner (e.g. `pytest`, `npm test`, `cargo test`, `go test`) with exact task test paths.
   - **Tier 3 (Manual Smoke)**: For non-automatable UI/interactive items, present concise verification steps and obtain user confirmation.
2. **Anti-Collusion & Integrity Guard (防同谋自验作弊检查)**:
   - **Assertion Immutability Check**: Verify that test files or assertions have NOT been altered or weakened in Mode 3/4 to fake a test pass.
   - **Exit Code Verification**: Test passes **ONLY** when the test runner process exits with **Code 0**. Text outputs alone without 0 exit code cannot be treated as pass.
3. **Capture Real Execution Logs**:
   - Write actual executed commands, exit codes, and stdout/stderr summary directly into `.ai/TEST_LOG.md`.
4. **Failure Handling**:
   - If ANY test fails (exit code != 0):
     - Record failure in `.ai/TEST_LOG.md` (command, error summary, root cause).
     - **FORBIDDEN** to enter Mode 5.
     - Return to **Mode 3** for targeted repair.
5. **Context Health Check**:
   - If test-fix loop iteration ≥ `mitigation_threshold` (default: 3), halt development, write post-mortem analysis to `TEST_LOG.md`, and recommend fresh session.

**Output**:
```markdown
## ✅ Validation Result (Tiered Verification)

### 任务
（Task ID + name）

### 物理执行记录
- **测试命令**: `{test_command}`
- **Exit Code**: `{0 / non-zero}`
- **耗时 / 资源**: `{time_elapsed}`

### 分级验证结果
| 级别 | 验证项 | 状态 | 物理证据 |
|---|---|---|---|
| Tier 1 | 静态 / 类型检查 | ✅ PASS / ❌ FAIL | `exit code 0` |
| Tier 2 | 自动化测试套件 | ✅ PASS / ❌ FAIL | `{N} passed, 0 failed` |
| Tier 3 | 冒烟 / 功能核验 | ✅ PASS / ⚠️ 需人工确认 | 用户签署 / 关键日志 |

### 失败项与修复建议（如有）
（if failed, list failing tests, root cause, and return to Mode 3）

### 最终状态与下一模式
- 最终结论: ✅ 全部通过 (All Pass) / ❌ 未通过
- 推荐操作: 回复 **"测试通过"** 或 **"收口"** 进入 Mode 5 进行物理归档与 Git 提交
```

---

### Mode 4.5: Document Sync Check（文档同步预检）

**Trigger**: Tests pass in Mode 4; or user requests document sync review.

**Actions**:
1. Scan for needed document updates:
   - `.ai/TASKS.md`: Mark task as `[x]` and record commit hash.
   - `.ai/STATUS.md`: Append phase summary, audit trail row, and update timestamps.
   - `.ai/TEST_LOG.md`: Ensure test results are committed.
   - `.ai/NEXT.md`: Prepare next task.
2. Present the sync checklist to the user. **Do NOT automatically execute Mode 5** without confirmation.

**Output**:
```markdown
## 📋 Document Sync Check
- [ ] TASKS.md - 准备标记 Task {ID} 为 [x]
- [ ] STATUS.md - 准备写入物理审计台账 (Audit Trail)
- [ ] NEXT.md - 准备推进至下一活跃任务

👉 请回复 **"收口"** 或 **"确认完成"** 进入 Mode 5 物理归档。
```

---

### Mode 5: Phase Closeout（物理 SSOT 结项与审计归档）

**Trigger**: Validation passed in Mode 4 and user confirms; or user says "测试通过 / 阶段完成 / 收口 / closeout / tests passed".

**Precondition**: **Mode 5 Iron Triangle Gate (铁三角门禁 - 三者必须同时满足)**:
```
┌──────────────────────────────────────────────────────────────┐
│                  Mode 5 铁三角物理门禁 (Iron Triangle)         │
├──────────────────────────────────────────────────────────────┤
│ 1. 物理变更存在: git status / git ls-files 确认代码文件落盘      │
│ 2. 真实测试绿灯: TEST_LOG.md 具备 Exit Code 0 真实执行凭证      │
│ 3. Git Commit 就绪: 具备真实的 commit hash，杜绝空气交付       │
└──────────────────────────────────────────────────────────────┘
```

**Actions & Document Alignments**:
1. **Git Commit & Evidence Extraction**:
   - Ensure all changes for current task are staged and committed: `git add . && git commit -m "feat({scope}): complete task {ID}"`.
   - Retrieve current commit hash via `git rev-parse --short HEAD`.
2. **Update `.ai/TASKS.md` (BLOCKING)**:
   - Mark completed task as `[x]` and record the `Git Commit Hash` and `Completed Timestamp`.
3. **Update `.ai/STATUS.md` (BLOCKING)**:
   - Update `## TL;DR` with verified facts.
   - Update `## 📊 核心度量` and `## 📈 里程碑执行状态`.
   - **Append to `## 🔍 已结项任务物理审计台账 (Audit Trail)`**:
     `| {Task_ID} | {Task_Name} | {Commit_Hash} | {Test_Command} (PASS) | {Timestamp} |`
   - Update `last_audit_timestamp` to current UTC.
4. **Update `.ai/NEXT.md` (BLOCKING)**:
   - Find the **next single uncompleted task (`[ ]`)** from `TASKS.md` whose dependencies are all satisfied.
   - Write it into `NEXT.md` as the single active task with an empty contract card.
   - If all tasks are completed, write **strictly** `no active task`.
5. **Update `.ai/TEST_LOG.md` & `.ai/LESSONS.md`**:
   - Finalize test conclusions.
   - Capture lessons learned with module keywords.

**Output**:
```markdown
## 🗂️ Phase Closeout (Physical SSOT Complete)

### 完成任务
- **Task ID**: {ID}
- **Title**: {Task Name}
- **Git Commit**: `{commit_hash}`
- **验证结论**: ✅ 真实测试通过 (Exit Code 0)

### 📊 物理审计台账记录 (Audit Trail)
| Task ID | 任务名称 | Git Commit | 验收方式 | 结项时间 |
|---|---|---|---|---|
| {ID} | {Task Name} | `{commit_hash}` | `{test_cmd}` (PASS) | {ISO-8601} |

### ✅ 文档更新完成确认
| 文件 | 状态 | 物理变更证据 |
|---|---|---|
| TASKS.md | ✅ 已更新 | 标记 `[x]` 并绑定 commit `{commit_hash}` |
| STATUS.md | ✅ 已更新 | 物理台账追加、里程碑与时间戳刷新 |
| NEXT.md | ✅ 已更新 | Active = Task {next_ID} (单一任务) |
| TEST_LOG.md | ✅ 已更新 | 记录真实测试 Exit Code 0 |

### 下一 Active Task
- **Next Task ID**: {next_ID} - {next_name}

📂 EVOLUTION_LOG
[时间] {ISO-8601}
[触发] Task {ID} 物理结项完成
[证据] Git Commit: {commit_hash} | Exit Code: 0
[变更] .ai/TASKS.md: 标记 Task {ID} 为 [x]
[变更] .ai/STATUS.md: 追加物理审计台账 + 更新里程碑
[变更] .ai/NEXT.md: 切换至 Task {next_ID}

### 🔄 推荐操作
推荐开启新对话以获得最干净的上下文，回复 **"继续项目"** 启动下一任务。
```

**Post-Closeout Self-Verification**:
- Verify that `NEXT.md` contains exactly one valid active task or `no active task`.
- Verify that `STATUS.md` contains the commit hash in the Audit Trail table.
- Verify that `TASKS.md` has the task marked `[x]`.

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
