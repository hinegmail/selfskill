# ProjectOrchestrator Skill 优化建议方案

> **基于文件**：`ProjectOrchestrator_Skill运行时状态诊断报告.md`
> **生成时间**：2026-08-10
> **方案总数**：9 项（P0×2 + P1×2 + P2×3 + P3×2）
> **核心目标**：修复 Mode 0 初始化遗漏、Mode 5 收口状态漂移、规则矛盾三大系统性缺陷

---

## 目录

- [1. 问题根因概述](#1-问题根因概述)
- [2. P0 — Skill 规则矛盾修复](#2-p0--skill-规则矛盾修复)
  - [建议 1：TEST_LOG.md 从"可选"提升为"必须"](#建议-1test_logmd-从可选提升为必须)
  - [建议 2：Pre-Flight Check 增加 RULES.md 占位符扫描](#建议-2pre-flight-check-增加-rulesmd-占位符扫描)
- [3. P1 — Mode 0 初始化补全](#3-p1--mode-0-初始化补全)
  - [建议 3：Mode 0 增加 RULES.md 占位符自动填充](#建议-3mode-0-增加-rulesmd-占位符自动填充)
  - [建议 4：init 脚本增加 RULES.md 占位符替换逻辑](#建议-4init-脚本增加-rulesmd-占位符替换逻辑)
- [4. P2 — Mode 5 收口校验增强](#4-p2--mode-5-收口校验增强)
  - [建议 5：Post-Closeout 增加任务计数交叉校验](#建议-5post-closeout-增加任务计数交叉校验check-d)
  - [建议 6：Post-Closeout 增加任务名称匹配校验](#建议-6post-closeout-增加任务名称匹配校验)
  - [建议 7：Mode 5 BLOCKING 更新增加 STEERING.md 里程碑标记同步](#建议-7mode-5-blocking-更新增加-steeringmd-里程碑标记同步)
- [5. P3 — 模板可读性改进](#5-p3--模板可读性改进)
  - [建议 8：RULES.md 模板占位符增加内联提示注释](#建议-8rulesmd-模板占位符增加内联提示注释)
  - [建议 9：Mode 1 Closeout Integrity Check 增加 Check D](#建议-9mode-1-closeout-integrity-check-增加-check-d)
- [6. 方案汇总表](#6-方案汇总表)
- [7. 实施注意事项](#7-实施注意事项)
- [8. 依赖关系图](#8-依赖关系图)

---

## 1. 问题根因概述

通过对 `Test` 目录运行时状态的全面诊断，发现三类系统性缺陷：

| 缺陷类别 | 根因 | 导致的运行时问题 |
|:---------|:-----|:----------------|
| **Skill 规则矛盾** | `MODE_REFERENCE.md` 与 `RULES.md` 对同一文件的强制级别定义冲突 | TEST_LOG.md 66 次测试零记录 |
| **Mode 0 初始化遗漏** | Mode 0 自动提取流程未覆盖 RULES.md | RULES.md 5 处占位符永远不被填充 |
| **Mode 5 收口校验不足** | Post-Closeout Verification 缺少跨文件计数校验和任务名称匹配校验 | STATUS.md 虚报 2 个里程碑完成、NEXT.md 指向错误任务 |

以下 9 项建议针对上述根因提出精确到行号的修改方案。

---

## 2. P0 — Skill 规则矛盾修复

### 建议 1：TEST_LOG.md 从"可选"提升为"必须"

| 字段 | 内容 |
|:-----|:-----|
| **问题** | `MODE_REFERENCE.md` 第 565 行将 TEST_LOG.md 标为 `OPTIONAL - but recommended`，但 `RULES.md` 第 56 行说"测试结果**必须**记录到 `.ai/TEST_LOG.md`"，第 34 行 State Sync 也将 TEST_LOG.md 列入 must update。AI 遵循了更宽松的"可选"，导致 66 次测试零记录。 |
| **影响文件** | `templates/ai/MODE_REFERENCE.md` |
| **修改位置** | §Mode 5，第 565-566 行 |
| **修复的问题** | C3: TEST_LOG.md 完全为空 |

#### Before（第 543-566 行）

```
**Must update the following files (BLOCKING - required before next task)**:
1. `.ai/TASKS.md` — mark completed task as `[x]`
2. `.ai/STATUS.md` — Update **all** of the following sections:
   ...
3. `.ai/NEXT.md` — regenerate with exactly one next active task; ...

**Micro Mode shortcut**: ...

**LESSONS.md Cap Check**: ...

**Conditionally update the following files (OPTIONAL - but recommended)**:
4. `.ai/TEST_LOG.md` — append final test conclusion (only if test records exist)
5. `.ai/DECISIONS.md` — if design deviations or important decisions were made
6. `.ai/LESSONS.md` — **Mandatory knowledge capture**: ...
7. `.ai/EVOLUTION_PROPOSALS.md` — ...
```

#### After

```
**Must update the following files (BLOCKING - required before next task)**:
1. `.ai/TASKS.md` — mark completed task as `[x]`
2. `.ai/STATUS.md` — Update **all** of the following sections:
   ...
3. `.ai/NEXT.md` — regenerate with exactly one next active task; ...
4. `.ai/TEST_LOG.md` — Append structured test record (test command, result, failures, root causes, fixes, retest, final conclusion). **Mandatory when tests were executed in Mode 4.** Only skip entirely if no tests were run at all (must state explicit reason for skipping).

**Micro Mode shortcut**: ...

**LESSONS.md Cap Check**: ...

**Conditionally update the following files (OPTIONAL - but recommended)**:
5. `.ai/DECISIONS.md` — if design deviations or important decisions were made
6. `.ai/LESSONS.md` — **Mandatory knowledge capture**: ...
7. `.ai/EVOLUTION_PROPOSALS.md` — ...
```

#### 同步修改：Mode 5 Output 模板（第 596 行）

Before:
```
| TEST_LOG.md | ✅ 已更新 / ⏭️ 跳过 | 追加测试结论 / 无测试记录 |
```

After:
```
| TEST_LOG.md | ✅ 已更新 | 追加结构化测试记录（命令/结果/失败项/根因/修复/复测） |
```

---

### 建议 2：Pre-Flight Check 增加 RULES.md 占位符扫描

| 字段 | 内容 |
|:-----|:-----|
| **问题** | Pre-Flight Check（第 17-26 行）扫描 STATUS.md 和 STEERING.md 的占位符，但不扫描 RULES.md。RULES.md 中的 `{auth_middleware_name}` 等占位符永远不会触发 Mode 0 初始化。 |
| **影响文件** | `templates/ai/MODE_REFERENCE.md` |
| **修改位置** | §Pre-Flight Check，第 22 行 |
| **修复的问题** | RULES.md 占位符永远不触发初始化 |

#### Before（第 22 行）

```
2. Scan for template placeholder patterns: `{待`, `0 / 0 任务`, `项目名称` as literal text, `{待填写}`, `{待提取}`, `Milestone 1]` with no real name.
```

#### After

```
2. Scan for template placeholder patterns: `{待`, `0 / 0 任务`, `项目名称` as literal text, `{待填写}`, `{待提取}`, `Milestone 1]` with no real name, `{auth_middleware_name}`, `{语言`, `{spaces`, `{e.g.`. Scan across STATUS.md, STEERING.md, NEXT.md, **and RULES.md**.
```

---

## 3. P1 — Mode 0 初始化补全

### 建议 3：Mode 0 增加 RULES.md 占位符自动填充

| 字段 | 内容 |
|:-----|:-----|
| **问题** | Mode 0 Actions 第 41-46 行只对 STEERING.md、STATUS.md、NEXT.md 做自动提取，完全遗漏了 RULES.md。5 个占位符（`{auth_middleware_name}`、`{语言 1}`、`{风格指南}`、`{spaces/tabs}`、`{e.g., 120}`）的信息都可以从 design.md/tasks.md 提取，但没有任何流程处理它们。 |
| **影响文件** | `templates/ai/MODE_REFERENCE.md` |
| **修改位置** | §Mode 0 Actions，第 45 行后（NEXT.md 条目后追加 RULES.md 条目） |
| **修复的问题** | RULES.md 5 处占位符未填充 |

#### After（在第 45 行 `**NEXT.md**: ...` 之后追加）

```
     - **RULES.md**: Fill template placeholders using data extracted from `DESIGN.md` and `TASKS.md`:
       - `{auth_middleware_name}`: Extract from DESIGN.md auth/login section. If no formal middleware exists, write `无（基于 user_id 隔离）`.
       - `{语言 1}`: Extract primary language from DESIGN.md tech stack (e.g., `Python`).
       - `{风格指南，如 PEP 8 / ESLint + Prettier}`: Extract from TASKS.md coding standards section (e.g., `PEP 8 + mypy 类型检查`).
       - `{spaces / tabs}`: Infer from language convention (Python → `4 spaces`, Go → `tabs`, JS/TS → `2 spaces`).
       - `{e.g., 120}`: Set to `120` (universal default) or extract from project conventions if specified.
```

---

### 建议 4：init 脚本增加 RULES.md 占位符替换逻辑

| 字段 | 内容 |
|:-----|:-----|
| **问题** | `init.ps1`/`init.sh` 直接从 `templates/ai/` 复制 RULES.md 到目标项目的 `.ai/` 目录，不处理占位符。 |
| **影响文件** | `init.ps1`、`init.sh` |
| **修改位置** | 在 `.ai/` 文件复制完成后的后处理区块 |
| **修复的问题** | 脚本层面不处理 RULES.md 占位符 |

#### init.ps1 修改（在 .ai/ 目录创建完成后追加）

```powershell
# --- RULES.md 占位符自动填充 ---
$rulesPath = Join-Path $AiPath "RULES.md"
if (Test-Path $rulesPath) {
    $rulesContent = Get-Content $rulesPath -Raw -Encoding UTF8

    # 从 design.md 提取技术栈信息
    $designPath = Join-Path $AiPath "design.md"
    $designContent = ""
    if (Test-Path $designPath) {
        $designContent = Get-Content $designPath -Raw -Encoding UTF8
    }

    # 简单启发式提取主语言
    $lang = "Python"; $style = "PEP 8 + mypy 类型检查"; $indent = "4 spaces"
    if ($designContent -match "TypeScript|React|Vue|Angular") {
        $lang = "TypeScript"; $style = "ESLint + Prettier"; $indent = "2 spaces"
    } elseif ($designContent -match "Go\b|Golang") {
        $lang = "Go"; $style = "gofmt + go vet"; $indent = "tabs"
    } elseif ($designContent -match "Rust") {
        $lang = "Rust"; $style = "rustfmt + clippy"; $indent = "4 spaces"
    }

    # 认证机制推断
    $authMiddleware = "无（基于 user_id 隔离）"
    if ($designContent -match "JWT|json.web.token") { $authMiddleware = "JWT" }
    elseif ($designContent -match "OAuth") { $authMiddleware = "OAuth 2.0" }
    elseif ($designContent -match "Session|session.based") { $authMiddleware = "Session" }

    # 执行替换
    $rulesContent = $rulesContent -replace '\{auth_middleware_name\}', $authMiddleware
    $rulesContent = $rulesContent -replace '\{语言 1\}', $lang
    $rulesContent = $rulesContent -replace '\{风格指南，如 PEP 8 / ESLint \+ Prettier\}', $style
    $rulesContent = $rulesContent -replace '\{spaces / tabs\}', $indent
    $rulesContent = $rulesContent -replace '\{e\.g\., 120\}', '120'

    Set-Content $rulesPath -Value $rulesContent -Encoding UTF8 -NoNewline
    Write-ColorMessage "[+] RULES.md placeholders auto-filled (lang=$lang, auth=$authMiddleware)" "Green"
}
```

#### init.sh 修改（等效 Bash 逻辑）

```bash
# --- RULES.md 占位符自动填充 ---
RULES_PATH="$AI_DIR/RULES.md"
if [ -f "$RULES_PATH" ]; then
    DESIGN_PATH="$AI_DIR/design.md"
    DESIGN_CONTENT=""
    [ -f "$DESIGN_PATH" ] && DESIGN_CONTENT=$(cat "$DESIGN_PATH")

    # 简单启发式提取主语言
    LANG_NAME="Python"; STYLE="PEP 8 + mypy 类型检查"; INDENT="4 spaces"
    if echo "$DESIGN_CONTENT" | grep -qE "TypeScript|React|Vue|Angular"; then
        LANG_NAME="TypeScript"; STYLE="ESLint + Prettier"; INDENT="2 spaces"
    elif echo "$DESIGN_CONTENT" | grep -qE "Go\b|Golang"; then
        LANG_NAME="Go"; STYLE="gofmt + go vet"; INDENT="tabs"
    elif echo "$DESIGN_CONTENT" | grep -q "Rust"; then
        LANG_NAME="Rust"; STYLE="rustfmt + clippy"; INDENT="4 spaces"
    fi

    # 认证机制推断
    AUTH_MW="无（基于 user_id 隔离）"
    if echo "$DESIGN_CONTENT" | grep -qE "JWT|json.web.token"; then AUTH_MW="JWT"
    elif echo "$DESIGN_CONTENT" | grep -q "OAuth"; then AUTH_MW="OAuth 2.0"
    elif echo "$DESIGN_CONTENT" | grep -qE "Session|session.based"; then AUTH_MW="Session"
    fi

    # 执行替换
    sed -i \
        -e "s/{auth_middleware_name}/$AUTH_MW/g" \
        -e "s/{语言 1}/$LANG_NAME/g" \
        -e "s/{风格指南，如 PEP 8 \/ ESLint + Prettier}/$STYLE/g" \
        -e "s/{spaces \/ tabs}/$INDENT/g" \
        -e "s/{e.g., 120}/120/g" \
        "$RULES_PATH"

    echo "[+] RULES.md placeholders auto-filled (lang=$LANG_NAME, auth=$AUTH_MW)"
fi
```

---

## 4. P2 — Mode 5 收口校验增强

### 建议 5：Post-Closeout 增加任务计数交叉校验（Check D）

| 字段 | 内容 |
|:-----|:-----|
| **问题** | Post-Closeout Verification（第 637-660 行）验证了 NEXT.md 有效性、STATUS.md 无占位符、TASKS.md 已标记 [x]，但没有校验 STATUS.md 中的任务计数（如"65/91"）是否与 TASKS.md 实际 `[x]`/总数一致。这正是 C2 问题（虚假标记 14/14）的根因。 |
| **影响文件** | `templates/ai/MODE_REFERENCE.md` |
| **修改位置** | §Mode 5 Post-Closeout Verification，第 648 行后 |
| **修复的问题** | C2: STATUS.md 虚假标记里程碑完成；H1: 总任务计数不一致 |

#### After（在第 648 行 `If any sub-check fails, re-execute the STATUS.md update` 之后追加）

```
   - **Task Count Cross-Validation**: Count `[x]` and total tasks in TASKS.md. Compare with `项目整体进度` field in STATUS.md. If the completed count or total count doesn't match, re-execute the STATUS.md update with correct counts.
   - **Milestone Accuracy Check**: For each milestone in STATUS.md's `## 📈 里程碑执行状态`, verify the completed/total count matches the actual count from TASKS.md for that phase. If any milestone shows "已完成" or "✅" but TASKS.md has uncompleted `[ ]` tasks in that phase, re-execute the milestone update with correct status (should be "进行中").
```

#### 同步修改：Verification Output 模板（第 656-658 行）

Before:
```
- STATUS.md: TL;DR ✓ + 📈 里程碑执行状态 populated (no template placeholders) ✓ + 项目整体进度 count ✓
```

After:
```
- STATUS.md: TL;DR ✓ + 📈 里程碑执行状态 populated (no template placeholders) ✓ + 项目整体进度 count ✓ + milestone counts match TASKS.md ✓
```

---

### 建议 6：Post-Closeout 增加任务名称匹配校验

| 字段 | 内容 |
|:-----|:-----|
| **问题** | 现有 Check 1（第 639-642 行）验证 NEXT.md 中的 Task ID 在 TASKS.md 中存在且为 `[ ]`，但没有验证**任务名称**是否匹配。C1 问题中 NEXT.md 说 "Task 4.4.2 生产部署指南" 但 TASKS.md 说 "4.4.2 Backend Dockerfile 优化"，ID 相同但名称完全不同，现有校验无法捕获。 |
| **影响文件** | `templates/ai/MODE_REFERENCE.md` |
| **修改位置** | §Mode 5 Post-Closeout Verification，第 640 行 |
| **修复的问题** | C1: NEXT.md 指向了与 tasks.md 不匹配的任务 |

#### Before（第 640 行）

```
   - A **valid next task** (Task ID + name that exists in TASKS.md as `[ ]`), OR
```

#### After

```
   - A **valid next task** (Task ID + name that **exactly matches** the corresponding task entry in TASKS.md, and that task is marked `[ ]`), OR
```

#### 同步修改：Mode 1 Closeout Integrity Check A（第 113 行）

Before:
```
     - **Check A (NEXT.md vs TASKS.md)**: Read the active task ID in NEXT.md. Search for that task in TASKS.md. If the task is already marked `[x]` (completed), this means the previous session's Mode 5 updated TASKS.md but failed to update NEXT.md.
```

After:
```
     - **Check A (NEXT.md vs TASKS.md)**: Read the active task ID **and name** in NEXT.md. Search for that task ID in TASKS.md. Verify the task name in NEXT.md matches the task name in TASKS.md. If the task is already marked `[x]` (completed), this means the previous session's Mode 5 updated TASKS.md but failed to update NEXT.md. If the task name doesn't match, this means the previous session's Mode 5 redefined the task scope without updating TASKS.md.
```

---

### 建议 7：Mode 5 BLOCKING 更新增加 STEERING.md 里程碑标记同步

| 字段 | 内容 |
|:-----|:-----|
| **问题** | Mode 5 的 BLOCKING 更新（第 543-559 行）包含 TASKS.md、STATUS.md、NEXT.md，但不包含 STEERING.md。STEERING.md §3 的里程碑标记（`[ ]`/`[x]`）从未被更新，导致所有里程碑永远显示未完成。 |
| **影响文件** | `templates/ai/MODE_REFERENCE.md` |
| **修改位置** | §Mode 5 BLOCKING updates，第 559 行后（NEXT.md 条目后） |
| **修复的问题** | H2: STEERING.md 里程碑标记全部未勾选；H3: Phase 2 任务总数错误 |

#### After（在第 559 行 `3. .ai/NEXT.md — ...` 之后追加，原有的编号顺延）

```
4. `.ai/STEERING.md` — Update §3 milestone markers: For each milestone, if all tasks in that phase are `[x]` in TASKS.md, mark it `[x]` in STEERING.md; otherwise mark it `[ ]`. Also verify task count annotations (e.g., "共 23 项") match actual task count in TASKS.md — if mismatch, update the count.
```

#### 同步修改：Post-Closeout Verification（在第 649 行后追加）

```
4. **Read back** `.ai/STEERING.md` — verify §3 milestone markers are updated: completed milestones marked `[x]`, in-progress milestones marked `[ ]`, and task count annotations match TASKS.md actual counts.
```

#### 同步修改：EVOLUTION_LOG 模板（在第 630 行后追加）

```
[变更] .ai/STEERING.md: 更新里程碑标记 + 校准任务计数
```

---

## 5. P3 — 模板可读性改进

### 建议 8：RULES.md 模板占位符增加内联提示注释

| 字段 | 内容 |
|:-----|:-----|
| **问题** | 模板中 `{auth_middleware_name}` 等占位符没有注释说明应填什么，AI 和用户都不清楚期望值。 |
| **影响文件** | `templates/ai/RULES.md` |
| **修改位置** | 第 76-86 行（架构约定和代码风格区块） |
| **修复的问题** | 可读性/可维护性 |

#### Before（第 76-86 行）

```markdown
## 架构约定

- API 接口前缀：`/api/v1/`
- 认证中间件：{auth_middleware_name}
- 错误响应格式：`{ "error": { "code": "...", "message": "..." } }`

## 代码风格

- {语言 1}：{风格指南，如 PEP 8 / ESLint + Prettier}
- 缩进：{spaces / tabs}
- 最大行宽：{e.g., 120}
```

#### After

```markdown
## 架构约定

- API 接口前缀：`/api/v1/`
- 认证中间件：{auth_middleware_name} <!-- Mode 0 自动填充。填写认证机制名称，如 JWT/Session/OAuth。若无独立中间件，写"无（基于 user_id 隔离）" -->
- 错误响应格式：`{ "error": { "code": "...", "message": "..." } }`

## 代码风格

- {语言 1}：{风格指南，如 PEP 8 / ESLint + Prettier} <!-- Mode 0 自动填充。从 design.md 技术栈提取主语言及对应风格指南 -->
- 缩进：{spaces / tabs} <!-- Mode 0 自动填充。Python=4 spaces, Go=tabs, JS/TS=2 spaces -->
- 最大行宽：120 <!-- 默认 120，可按项目实际调整 -->
```

> **注意**：`{e.g., 120}` 直接替换为硬编码 `120`，不再保留为占位符。120 是跨语言通用默认值，保留为占位符反而增加无意义的初始化步骤。

---

### 建议 9：Mode 1 Closeout Integrity Check 增加 Check D

| 字段 | 内容 |
|:-----|:-----|
| **问题** | Mode 1 的收口完整性校验（第 111-125 行）有 Check A/B/C，但没有检查 STATUS.md 任务计数与 TASKS.md 实际计数的一致性。如果上次 Mode 5 的 Post-Closeout Verification 漏检了计数（正是当前情况），Mode 1 也无法捕获。 |
| **影响文件** | `templates/ai/MODE_REFERENCE.md` |
| **修改位置** | §Mode 1 Closeout Integrity Check，第 115 行后（Check C 之后） |
| **修复的问题** | Mode 1 无法捕获已发生的计数漂移 |

#### After（在第 115 行 Check C 之后追加）

```
    - **Check D (STATUS.md count vs TASKS.md count)**: Count `[x]` and total tasks in TASKS.md. Compare with the `项目整体进度` field in STATUS.md. If the completed count or total count doesn't match, the previous session's Mode 5 failed to synchronize task counts — enter Recovery Protocol to recalculate and update STATUS.md. Also verify each milestone's completed/total count in STATUS.md's `## 📈 里程碑执行状态` matches the actual count from TASKS.md for that phase.
```

#### 同步修改：Recovery Protocol（第 116-124 行）

Before:
```
   - **If any check fails**: Output a prominent warning and enter **Recovery Protocol**:
     > ⚠️ [Closeout Integrity Alert] Previous session's Mode 5 (Phase Closeout) was not fully completed. Detected issue: {describe which check failed}.
     >
     > **Recovery Protocol**: I will now complete the missing Mode 5 updates before proceeding:
     > 1. Update STATUS.md with the completed task's phase summary + TL;DR + timestamp.
     > 2. Regenerate NEXT.md with the next uncompleted task from TASKS.md.
     > 3. Output EVOLUTION_LOG for the recovery.
```

After:
```
   - **If any check fails**: Output a prominent warning and enter **Recovery Protocol**:
     > ⚠️ [Closeout Integrity Alert] Previous session's Mode 5 (Phase Closeout) was not fully completed. Detected issue: {describe which check failed}.
     >
     > **Recovery Protocol**: I will now complete the missing Mode 5 updates before proceeding:
     > 1. Update STATUS.md with the completed task's phase summary + TL;DR + timestamp.
     > 2. **Recalculate task counts**: Count `[x]` and total tasks in TASKS.md, update `项目整体进度` and all milestone counts in STATUS.md.
     > 3. Regenerate NEXT.md with the next uncompleted task from TASKS.md (verify task name matches TASKS.md).
     > 4. Update STEERING.md milestone markers if needed.
     > 5. Output EVOLUTION_LOG for the recovery.
```

---

## 6. 方案汇总表

| # | 优先级 | 建议名称 | 影响文件 | 修复的问题 | 修改类型 |
|:--|:-------|:---------|:---------|:-----------|:---------|
| 1 | 🔴 P0 | TEST_LOG.md 从"可选"提升为"必须" | `MODE_REFERENCE.md` | C3: TEST_LOG.md 零记录 | 规则矛盾修复 |
| 2 | 🔴 P0 | Pre-Flight Check 扫描 RULES.md 占位符 | `MODE_REFERENCE.md` | RULES.md 占位符不触发初始化 | 检测覆盖扩展 |
| 3 | 🟠 P1 | Mode 0 增加 RULES.md 自动填充 | `MODE_REFERENCE.md` | RULES.md 5 处占位符未填充 | 初始化流程补全 |
| 4 | 🟠 P1 | init 脚本增加 RULES.md 占位符替换 | `init.ps1`, `init.sh` | 脚本层面不处理 RULES.md 占位符 | 脚本逻辑增强 |
| 5 | 🟡 P2 | Post-Closeout 增加任务计数交叉校验 | `MODE_REFERENCE.md` | C2/H1: 虚假标记 + 计数偏差 | 校验增强 |
| 6 | 🟡 P2 | Post-Closeout 增加任务名称匹配校验 | `MODE_REFERENCE.md` | C1: NEXT.md 指向错误任务 | 校验增强 |
| 7 | 🟡 P2 | Mode 5 增加 STEERING.md 里程碑同步 | `MODE_REFERENCE.md` | H2/H3: STEERING.md 标记未更新 | BLOCKING 更新扩展 |
| 8 | 🟢 P3 | RULES.md 模板增加内联提示注释 | `templates/ai/RULES.md` | 可读性/可维护性 | 模板改进 |
| 9 | 🟢 P3 | Mode 1 增加 Check D 任务计数校验 | `MODE_REFERENCE.md` | Mode 1 无法捕获计数漂移 | 检测覆盖扩展 |

---

## 7. 实施注意事项

### 7.1 文件修改分布

| 影响文件 | 涉及建议 # | 修改量 |
|:---------|:-----------|:-------|
| `templates/ai/MODE_REFERENCE.md` | 1, 2, 3, 5, 6, 7, 9 | 7 处修改（涉及 §Pre-Flight Check、§Mode 0、§Mode 1、§Mode 5 多个章节） |
| `templates/ai/RULES.md` | 8 | 1 处修改（架构约定 + 代码风格区块） |
| `init.ps1` | 4 | 1 处追加（.ai/ 创建后处理区块） |
| `init.sh` | 4 | 1 处追加（.ai/ 创建后处理区块） |

### 7.2 修改后必须执行的步骤

1. **重新生成 IDE Adapters**：`python tools/adapter_generator.py` — 因为 `MODE_REFERENCE.md` 是所有 adapter 的源文件，修改后需要重新生成。
2. **更新 Skill 版本号**：`skill.md` 第 1 行的 `v1.0` → `v1.1`。
3. **Git 提交**：`git add -A && git commit -m "feat: fix Mode 0/5 state sync gaps and rule contradictions"`。

### 7.3 建议间的重叠与依赖

| 关系 | 说明 |
|:-----|:-----|
| **建议 3 与建议 4 重叠** | 两者都解决 RULES.md 占位符问题。建议 3 在 AI 的 Mode 0 流程中填充，建议 4 在 init 脚本中填充。两个都做是"双保险"（脚本先跑，AI Mode 0 再兜底），也可以只选其中一个。**推荐两个都做**——脚本层在项目初始化时就完成填充，Mode 0 作为运行时兜底。 |
| **建议 5 与建议 9 递进** | 建议 5 在 Mode 5 收口时**防止**计数漂移（预防），建议 9 在 Mode 1 审计时**检测**已发生的漂移（检测）。两个都做形成"预防+检测"完整闭环。**推荐两个都做**。 |
| **建议 1 与建议 2 独立** | 建议 1 修复 Mode 5 的 TEST_LOG.md 级别矛盾，建议 2 修复 Pre-Flight Check 的 RULES.md 扫描遗漏。两者独立，无依赖。 |
| **建议 6 依赖建议 5 的框架** | 建议 6 增强的是 Post-Closeout Verification 的 Check 1，建议 5 在同一区块追加 Check D。两者修改同一区域，需注意行号不冲突。**建议同时实施**。 |

### 7.4 风险评估

| 风险 | 可能性 | 影响 | 缓解措施 |
|:-----|:-------|:-----|:---------|
| Mode 5 将 TEST_LOG.md 提升为 BLOCKING 后，AI 在无测试的任务中被迫写入空记录 | 低 | 低 | 已在建议 1 中加条件："Only skip entirely if no tests were run at all (must state explicit reason)" |
| init 脚本的启发式语言检测误判（如项目同时用 Python + TypeScript） | 中 | 低 | 取第一个匹配的语言作为主语言；AI Mode 0 会兜底修正；用户可手动修改 |
| Post-Closeout Verification 增加校验步骤后，收口耗时增加 | 低 | 低 | 都是本地文件读取和字符串比对，耗时可忽略 |
| STEERING.md 升级为 BLOCKING 后，每次收口都需读写额外文件 | 低 | 低 | STEERING.md 通常 <100 行，IO 开销可忽略 |

---

## 8. 依赖关系图

```
                    ┌─────────────────────────────────────────┐
                    │         P0: 规则矛盾修复                  │
                    │                                         │
  ┌──── 建议 1 ──── │ TEST_LOG.md: OPTIONAL → BLOCKING         │
  │                 │ 建议 1 独立                                │
  │                 └─────────────────────────────────────────┘
  │
  │                 ┌─────────────────────────────────────────┐
  ├──── 建议 2 ──── │ Pre-Flight: 增加 RULES.md 占位符扫描     │
  │                 │ 建议 2 独立                                │
  │                 └─────────────────────────────────────────┘
  │
  │                 ┌─────────────────────────────────────────┐
  │                 │         P1: Mode 0 初始化补全             │
  │                 │                                         │
  ├──── 建议 3 ──── │ Mode 0: 增加 RULES.md 自动填充           │──┐
  │                 │ 建议 3 与建议 4 重叠（双保险）             │  │
  │                 └─────────────────────────────────────────┘  │
  │                                                             │  两者都做
  ├──── 建议 4 ──── init.ps1/sh: 增加 RULES.md 占位符替换 ──────┘
  │
  │                 ┌─────────────────────────────────────────┐
  │                 │         P2: Mode 5 收口校验增强           │
  │                 │                                         │
  ├──── 建议 5 ──── │ Post-Closeout: 增加 Check D 计数校验     │──┐
  │                 │ 建议 5 与建议 9 递进（预防+检测）         │  │
  │                 └─────────────────────────────────────────┘  │
  │                                                             │  闭环
  ├──── 建议 9 ──── Mode 1: 增加 Check D 计数校验 ─────────────┘
  │
  │                 ┌─────────────────────────────────────────┐
  ├──── 建议 6 ──── │ Post-Closeout: 增加任务名称匹配校验      │
  │                 │ 建议 6 与建议 5 同区域，建议同时实施       │
  │                 └─────────────────────────────────────────┘
  │
  │                 ┌─────────────────────────────────────────┐
  ├──── 建议 7 ──── │ Mode 5: 增加 STEERING.md 里程碑同步      │
  │                 │ 建议 7 独立                                │
  │                 └─────────────────────────────────────────┘
  │
  │                 ┌─────────────────────────────────────────┐
  │                 │         P3: 模板可读性改进               │
  │                 │                                         │
  └──── 建议 8 ──── │ RULES.md: 增加内联提示注释               │
                    │ 建议 8 独立                                │
                    └─────────────────────────────────────────┘
```

---

## 9. 实施顺序建议

推荐按以下顺序逐步实施，每步完成后可独立验证：

| 步骤 | 实施建议 | 验证方式 |
|:-----|:---------|:---------|
| **Step 1** | 建议 1 + 建议 2 | 检查 `MODE_REFERENCE.md` 中 TEST_LOG.md 已从 OPTIONAL 移至 BLOCKING；Pre-Flight Check 包含 RULES.md 占位符 |
| **Step 2** | 建议 8 | 检查 `templates/ai/RULES.md` 占位符旁有 HTML 注释 |
| **Step 3** | 建议 3 + 建议 4 | 用 `init.ps1` 初始化一个测试项目，检查 RULES.md 占位符已被替换 |
| **Step 4** | 建议 5 + 建议 6 | 人工模拟一次 Post-Closeout Verification，检查计数和名称校验生效 |
| **Step 5** | 建议 7 | 完成一个任务后检查 STEERING.md 里程碑标记已更新 |
| **Step 6** | 建议 9 | 人为制造计数偏差，启动新会话检查 Mode 1 Check D 能否捕获 |
| **Step 7** | 重新生成 adapters | `python tools/adapter_generator.py` |
| **Step 8** | 版本号更新 + Git 提交 | `skill.md` v1.0 → v1.1，提交并打 tag |

---

*方案结束*
