# 项目 AI 规则与编码约定 (RULES)

## 🧠 AI 核心行为规则 (AI Orchestration Rules)

* **Orchestrator Configurations**:
  - `mitigation_threshold`: 3  # The maximum retry limit for the test-fix-retest loop before triggering a halt.

1. **Memory Reset & Smart Audit (认知重置与智能审计)**:
   - Do not rely on chat history. You must load `.ai/` files via file tools at the start of every session.
   - **Timestamp Smart Load**: Prioritize reading `STEERING.md`, `STATUS.md`, `NEXT.md`, and `RULES.md`. Avoid reading raw docs (`requirements.md`/`DESIGN.md`) exceeding 30K if their timestamps match the `last_audit_timestamp` in `STATUS.md`. Retrieve details strictly via INDEX line ranges.
   - **Auto-Initialization**: If `STEERING.md` or other control files are blank placeholders or missing, you **must automatically demote to Mode 0 (Initialization)**. Proactively read raw docs, extract metadata, milestones, and line indexes, and propose the generated skeletal files in the chat. Do not request manual creation.

2. **NEXT.md Single Gate (NEXT闸门拦截)**:
   - You are permitted to execute exactly one active task specified in `.ai/NEXT.md`.
   - Coding future or un-designated tasks is strictly forbidden. Halt and report if `NEXT.md` is empty, conflicts with `STATUS.md`, or has multiple tasks.

3. **7-Mode Execution Lifecycle (七模式状态机引擎)**:
   - You must proceed strictly and sequentially through Mode 0 to Mode 6 (Init -> Audit -> Planning -> Implementation -> Validation -> Closeout -> Evolution).
   - Jumping directly to coding (Mode 3) without executing and confirming Mode 1/2 is strictly forbidden.

4. **One-Card Contract & Lessons Search (单卡开工契约与避坑检索)**:
   - In Mode 2 (Planning), you **must** execute `grep_search` on `.ai/LESSONS.md` using keywords from the current task. Cite any matched historical pitfalls under "历史避坑经验".
   - You must present the **One-Card Contract Protocol**: ① Task objective understanding; ② Technical path + files (incorporating lessons); ③ JIT Tiered Acceptance Assertions (frozen after user approval). Wait for explicit user approval before writing code.

5. **Context Blurring Mitigation (测试修复熔断机制)**:
   - During implementation and validation, do not add new features or refactor unrelated code.
   - If the test-fix-retest loop in the current chat exceeds `mitigation_threshold` (default: 3), you **must** halt development.
   - Compile a **"Root Cause Analysis (根因诊断反思)"** list, write it directly into `.ai/TEST_LOG.md`, and output a notice requesting the user to start a new clean session.

6. **Dual-Track Logging (双轨日志写入)**:
   - Every state update to `.ai/` files must include a standard `📂 EVOLUTION_LOG` block at the end of the response.

7. **State Sync & Design Alignment (状态同步与设计对齐)**:
   - After validation passes, you must update `STATUS.md` (including `last_audit_timestamp` to the current timestamp), `TASKS.md`, `TEST_LOG.md`, and `NEXT.md`.
   - **Design Alignment**: Read `DESIGN.md` (via line index in `steering.md`) and compare actual code changes. If architectural deviations exist, you **must** submit a patch proposal to `EVOLUTION_PROPOSALS.md` rather than silently mutating `DESIGN.md`.

## 开发规则（含防臃肿与去重约束）

1. 实现前必须产出 Task Plan。
2. Task Plan 必须列出预计检查和修改的文件。
3. **防臃肿与 DRY（复用原则）**：
   - 编写任何辅助函数或工具方法前，**必须**搜索代码库（如 `utils/`, `helpers/`, `components/`）确认是否有同类实现，禁止重复造轮子。
   - 坚持 **KISS 极简原则**，编写最紧凑、最符合语言惯例的代码。严禁过度设计，禁止编写当前任务未调用到的占位函数。
   - **死代码清理**：在提交测试前，必须清理所有未使用的 import、冗余调试代码（如 `console.log`, `print` 调试残留）和死代码。
   - **体量限制**：如果新增或修改后的单个文件行数超过 **300行**，必须提议进行文件拆分或组件解耦。
   - **禁止文档碎片化**：严禁针对单个微小任务创建独立的 Markdown 总结或说明文档。所有小任务的完成状态只能体现在 `.ai/TASKS.md`（勾选）和 `.ai/STATUS.md`（追加简要日志）中。只有在完成整个里程碑/大阶段任务时，方可提议输出或更新整体的总结报告。
4. 保持变更最小化、任务范围化。
5. 实现后必须解释每个修改的文件和原因。
6. 如任务过大，必须提议拆分为微任务。

## 测试规则

1. 优先运行最小相关测试集。
2. 仅修复与当前任务相关的失败。
3. 测试通过后不自动开始下一个任务。
4. 测试结果必须记录到 `.ai/TEST_LOG.md`。

## 收口规则

1. 任务通过验证后才能标记完成。
2. 必须用当前实现结果更新 `STATUS.md`。
3. 必须在 `NEXT.md` 中生成恰好一个下一任务。
4. 如无下一任务，明确标注"无活跃任务"。

---

## 命名规范

- 后端 API 字段：`snake_case`
- 前端变量/函数：`camelCase`
- React 组件：`PascalCase`
- CSS 类名：`kebab-case`
- 数据库表名：复数形式
- 常量：`UPPER_SNAKE_CASE`

## 架构约定

- API 接口前缀：`/api/v1/`
- 认证中间件：{auth_middleware_name}
- 错误响应格式：`{ "error": { "code": "...", "message": "..." } }`

## 代码风格

- {语言 1}：{风格指南，如 PEP 8 / ESLint + Prettier}
- 缩进：{spaces / tabs}
- 最大行宽：{e.g., 120}

---

## 踩坑教训（按时间倒序）

> 以下条目来自 LESSONS.md 的固化。每条须经用户审批后方可添加。

（无）
