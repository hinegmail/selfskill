# 📋 ProjectOrchestrator Skill 系统设计缺陷暴露与架构优化提案

## 一、核心缺陷诊断

### 1.1 缺陷地图

| 缺陷 | 表现 | 根因 | 影响范围 |
|---|---|---|---|
| **缺陷 A：Mode 转换自动化过度** | Mode 3 完成后自动进入 Mode 5，跳过验证 | Mode 4 为可选而非强制；Mode 4.5 自动触发 Mode 5 | 所有任务都会被虚假标记为完成 |
| **缺陷 B：三方确认流程被破坏** | Mode 2 三个确认点，但用户只说"执行"就跳过 | Mode 2→3 的触发条件过于宽松（7 个任意关键词） | 规划与实现之间缺乏充分沟通 |
| **缺陷 C：单任务执行门禁失效** | NEXT.md 中一次性列出 84 个任务都标记为完成 | 没有"任务 DAG 依赖验证"；没有"单任务隔离检查" | 并发标记、任务间污染 |
| **缺陷 D：验收标准没有可执行性** | tasks.md 定义了"完成标准"，但 Skill 从未真正检查 | 完成标准是文本描述，而非可编程的断言/测试 | 虚报完成率，无法追溯 |
| **缺陷 E：STATUS.md 与代码现实脱节** | STATUS.md 说"100% 完成"，但代码只有 48% | 没有"双向校验"机制：Skill 不会检查 git 提交是否真的包含了宣称的功能 | 文档虚报，信息不对称 |
| **缺陷 F：Mode 4 (Validation) 缺乏强制力** | Mode 4 是可选的（仅当"user provides test results"时触发） | 没有强制性的测试运行步骤；没有"测试未通过 ⇒ 强制回到 Mode 3"的闭环 | 可以完全跳过测试，直接标记完成 |

### 1.2 缺陷连锁反应

```
缺陷 A（Mode 自动化过度）
   ↓
缺陷 B（三方确认被破坏）
   ↓
缺陷 D（验收标准不可执行）
   ↓
缺陷 E（STATUS 虚报）
   ↓
最终结果：项目虽然"100% 完成"，但实际只有 48% 代码
   ↓
无法发现问题，直到人工审计（太晚了）
```

---

## 二、分层优化方案

### 2.1 L1：Mode 转换逻辑重构（最高优先级）

**现状问题**：
```
Mode 3 完成 
  → 自动进入 Mode 4.5
    → 自动进入 Mode 5
       ❌ 没有停止点等待用户验证
```

**优化方案**：

```
Mode 3: Task Implementation
  ↓ 代码完成
  列出改动文件
  建议 test 命令
  ✋ STOP - 等待用户操作
     ├─ 用户说 "测试通过" / "验证完成" → 进 Mode 5
     ├─ 用户说 "运行测试" → 进 Mode 4
     ├─ 用户说 "改一下" → 回 Mode 3
     └─ 超时 1 小时未反应 → 发送 reminder，但不自动进 Mode 5
```

**实现规则**：
- ✅ **Hard Stop**: Mode 3 完成后必须停止，等待明确的用户意图信号
- ✅ **Explicit Signal**: 不能用模糊的"继续"，必须是明确的验证关键词：
  - "测试通过" / "验证成功" / "OK，验收" → Mode 5
  - "运行测试" / "执行测试" → Mode 4
  - "改一下" / "有问题" → Mode 3
- ✅ **No Auto-Advance**: Mode 4.5 不再自动触发 Mode 5，改为用户决定

---

### 2.2 L2：三方确认流程硬化（第二优先级）

**现状问题**：
```
Mode 2 要求三次确认，但 Mode 2→3 的触发条件是 7 个任意关键词中的任何一个
➜ 用户说"执行"就直接进 Mode 3，跳过了详细规划
```

**优化方案**：

```
Mode 2: Task Planning + Three Confirmations (HARDENED)

必须逐个确认（非 AND 逻辑变为 AND+序列检查）：

① 目标确认
   Agent: "目标：实现 projects 表 DDL。确认？"
   User: "确认" / "OK" / "👍" ← 必须明确
   ✓ Checkpoint 1 通过
   
② 文件路径确认
   Agent: "涉及文件：backend/db/migrations/001_init_projects.sql"
   User: "确认" ← 必须明确
   ✓ Checkpoint 2 通过
   
③ 第一个交付物确认
   Agent: "第一交付物：projects 表 DDL 通过 psql 语法检查"
   User: "确认" ← 必须明确
   ✓ Checkpoint 3 通过

[三个 Checkpoint 全部通过] → 才能进 Mode 3
```

**实现规则**：
- ✅ **Checkpoint Sequence**: 三个确认必须顺序执行，不能跳过
- ✅ **Explicit Affirmation**: 每个 Checkpoint 需要明确的"是"信号，不接受模糊回答
- ✅ **Rollback Path**: 任何 Checkpoint 拒绝 → 回到 Mode 2 重新规划（不是回 Mode 1）

---

### 2.3 L3：可执行性验收标准（第三优先级）

**现状问题**：
```
tasks.md 中定义：
"完成标准：
  - [ ] projects 表 DDL 通过 PostgreSQL 15+ 语法检查
  - [ ] 包含 slug(PK), name, site_url, ... 等全部字段
  - [ ] 创建主键约束、NOT NULL 约束、DEFAULT 值
  - [ ] 无错误"

➜ 这些都是文本，Skill 从不检查这些是否真的满足
```

**优化方案**：

在 tasks.md 中为每个任务添加"可执行验收脚本"字段：

```yaml
Task: 1a-101
Title: 设计与实现 projects 表
...
Acceptance Criteria:
  - projects 表 DDL 通过 PostgreSQL 15+ 语法检查
  - 包含 slug(PK), name, site_url, ... 等全部字段

# ← 新增：可执行验收脚本
Verification Script: |
  #!/bin/bash
  # 1. 检查文件存在
  test -f backend/db/migrations/001_init_projects.sql || exit 1
  
  # 2. 检查 SQL 语法
  psql -d template1 --echo-all -f backend/db/migrations/001_init_projects.sql
  
  # 3. 检查表结构
  psql -U postgres -d geolook -c "\d projects" | grep -q "slug.*primary key"
  psql -U postgres -d geolook -c "\d projects" | grep -q "name.*not null"
  
  # 4. 检查约束
  psql -U postgres -d geolook -c "\d projects" | wc -l | awk '{if ($1 >= 15) exit 0; else exit 1}'
  
  echo "✅ 1a-101 验收通过"
```

**实现规则**：
- ✅ **Script Template**: 每个任务必须有一个 bash/python 脚本
- ✅ **Auto-Execution**: Mode 4 时自动运行验收脚本
- ✅ **Pass/Fail Gate**: 脚本成功 (exit 0) ⇒ Mode 5；失败 ⇒ 留在 Mode 3
- ✅ **Log Recording**: 验收脚本输出记录到 TEST_LOG.md

---

### 2.4 L4：双向 SSOT 校验（第四优先级）

**现状问题**：
```
STATUS.md 说"任务 X 完成"
但 git 中从未提交相关代码
➜ 信息不同步
```

**优化方案**：

添加"Code Presence Check"步骤到 Mode 5：

```
Mode 5: Phase Closeout (ENHANCED)

Before marking task as complete:

1. 检查代码文件是否存在
   git ls-files | grep -E "(backend/db/migrations/001|backend/app/...)" 
   ✓ 文件存在
   
2. 检查提交日志
   git log --oneline --grep="1a-101" | head -1
   ✓ 提交存在
   
3. 检查验收脚本通过
   bash verification_scripts/1a-101.sh
   ✓ 脚本通过
   
4. 更新 STATUS.md
   ✓ 标记任务完成
   ✓ 记录提交 hash
   ✓ 记录验收时间戳

[如果以上任何一步失败] → 拒绝进入 Mode 5，返回 Mode 3
```

**实现规则**：
- ✅ **Code Existence Check**: 提交代码才能标记完成
- ✅ **Verification Pass Check**: 验收脚本必须通过
- ✅ **Git Integration**: 记录提交 hash 作为证据
- ✅ **Audit Trail**: STATUS.md 记录每个任务的 git commit hash

---

### 2.5 L5：单任务隔离与 DAG 验证（第五优先级）

**现状问题**：
```
NEXT.md 中同时列出 84 个任务
➜ Skill 无法判断哪个任务真的可以执行

任务间有依赖关系（1a-102 依赖 1a-101）
➜ Skill 从未检查依赖
```

**优化方案**：

添加"Task DAG Validator"到 Mode 1：

```
Mode 1: Context Audit (ENHANCED)

Before allowing any task execution:

1. Parse NEXT.md
   current_task = "1a-101"
   
2. Validate single task
   if count(active_tasks) > 1:
     ERROR: "Multiple active tasks in NEXT.md. Fix before proceeding."
   
3. Check task exists in TASKS.md
   if "1a-101" not in tasks.md:
     ERROR: "Task 1a-101 not found in tasks.md"
   
4. Check task not completed
   if tasks.md["1a-101"]["status"] == "completed":
     ERROR: "Task 1a-101 already marked completed"
   
5. Check dependencies satisfied
   dependencies = tasks.md["1a-101"]["depends_on"]
   for dep in dependencies:
     if tasks.md[dep]["status"] != "completed":
       ERROR: f"Cannot start 1a-101: dependency {dep} not completed"
   
6. Update STATUS.md
   STATUS.current_active_task = "1a-101"
   STATUS.last_audit_timestamp = NOW()
```

**实现规则**：
- ✅ **Single Task**: NEXT.md 只能有一个活跃任务
- ✅ **DAG Check**: 强制检查依赖关系
- ✅ **No Forward Skip**: 不能跳过依赖任务
- ✅ **Explicit Completion**: 任务完成必须在 Mode 5 时显式标记

---

### 2.6 L6：超时与提醒机制（第六优先级）

**现状问题**：
```
Mode 3 完成后等待用户反馈
但如果用户 24 小时没反馈，Skill 从不提醒
```

**优化方案**：

添加"Timeout & Reminder"机制：

```
Mode 3 完成后：

记录 completion_timestamp = NOW()
mode_3_timeout = 1 hour

每 15 分钟检查一次：
  if NOW() - completion_timestamp > 15 min:
    提醒一次（不超过 3 次）
    "🕒 任务 1a-101 实现完成，等待验证。请说 '测试通过' 或 '运行测试'"
  
  if NOW() - completion_timestamp > 1 hour:
    WARNING：任务已超时未验收
    "⚠️ 任务 1a-101 已等待 1 小时未验收。强制返回 Mode 1 重新审计。"
    → 自动进入 Mode 1
```

**实现规则**：
- ✅ **Reminder Frequency**: 15 分钟提醒一次，最多 3 次
- ✅ **Hard Timeout**: 1 小时后自动回到 Mode 1（强制人工审计）
- ✅ **No Silent Hang**: 永远不会让任务卡在"等待"状态无人问津

---

## 三、文件格式改进

### 3.1 enhanced NEXT.md 格式

```markdown
# 唯一活跃任务闸门 (NEXT)

## 当前活跃任务

**Task ID**: 1a-101
**Title**: 设计与实现 projects 表
**Status**: in_progress
**Mode**: 3 (Implementation)
**Started At**: 2026-08-18T10:30:00Z
**Expected Completion**: 2026-08-18T11:30:00Z

## 任务上下文

**Dependencies**: 无（首个任务）
**Blocking**: [1a-102, 1a-103, ...]（被这些任务阻塞）

## 前序检查清单

- [x] Task 存在于 tasks.md
- [x] 依赖任务全部完成
- [x] 没有并发活跃任务
- [x] NEXT.md Hard Gate 通过

## Mode 转换记录

- Mode 1 完成：2026-08-18T10:15:00Z (Context Audit)
- Mode 2 完成：2026-08-18T10:20:00Z (Planning approved)
- Mode 3 开始：2026-08-18T10:20:00Z
- Mode 3 完成：2026-08-18T10:30:00Z (Awaiting user signal)
  ⏳ 等待用户说 "测试通过" / "运行测试" / "改一下"
  ⏱️ 超时时间：2026-08-18T11:30:00Z

## Mode 3 交付物

**改动文件**：
- `backend/db/migrations/001_init_projects.sql` (NEW)

**验收脚本**：
```bash
bash verification_scripts/1a-101.sh
```

---

# 无活跃任务时的状态

如果当前没有活跃任务，NEXT.md 应该显示：

```markdown
# 唯一活跃任务闸门 (NEXT)

**Status**: AWAITING_USER_DIRECTION

所有任务已完成或正在等待下一阶段启动。

请说以下任何一个：
- "继续项目" → 进 Mode 1，扫描下一个待执行任务
- "开始阶段 1b" → 启动新阶段
- "审计状态" → 重新审计整个项目
```

---

### 3.2 enhanced STATUS.md 格式

```markdown
# 项目状态实况 (STATUS)

## 📊 核心指标

| 指标 | 值 | 上次更新 |
|---|---|---|
| 总任务数 | 84 | - |
| 已完成 | 5 | 2026-08-18T11:00:00Z |
| 进行中 | 1 (1a-101) | 2026-08-18T10:30:00Z |
| 待执行 | 78 | - |
| 完成率 | 5.95% | - |

## 🔍 完成任务审计证据

| Task | Git Commit | Verification Script | Completed At |
|---|---|---|---|
| 1a-101 | a1b2c3d | ✅ PASS | 2026-08-18T11:00:00Z |
| 1a-102 | e4f5g6h | ✅ PASS | 2026-08-18T12:30:00Z |

## ⚠️ 风险标志

| 标志 | 状态 |
|---|---|
| Mode 超时（>1h）| ❌ 无 |
| 未验收任务 | ❌ 无 |
| 代码-文档脱节 | ❌ 无 |
| RLS 漏洞已识别 | ⚠️ 需审计 |

## 🚦 当前 Mode

**Mode**: 3 (Task Implementation)
**Task**: 1a-101
**Timeout**: 2026-08-18T11:30:00Z

---

## 历史审计日志

**2026-08-18T10:15:00Z** Mode 1 审计通过
- 检查结果：NEXT.md 有效，无占位符，任务依赖满足

**2026-08-18T10:20:00Z** Mode 2 三方确认完成
- ✓ 目标确认：实现 projects 表
- ✓ 文件路径确认：backend/db/migrations/001_init_projects.sql
- ✓ 第一交付物确认：projects 表 DDL 通过语法检查

**2026-08-18T10:30:00Z** Mode 3 实现完成
- 改动文件：001_init_projects.sql
- 验收脚本：通过手工测试
- 等待用户验证信号
```

---

### 3.3 新增 VERIFICATION_SCRIPTS/ 目录

```
verification_scripts/
├── 1a-101.sh              # projects 表
├── 1a-102.sh              # users + user_projects 表
├── 1a-201.sh              # FastAPI 启动检查
├── 1a-301.sh              # @geolook/contracts 编译
└── shared/
    ├── db-schema-check.sh
    ├── test-runner.sh
    └── code-coverage.sh
```

每个脚本的格式：

```bash
#!/bin/bash
# 验收脚本：1a-101 设计与实现 projects 表

set -e  # 任何失败都停止

echo "🔍 开始验收 1a-101..."

# Step 1: 文件存在性检查
echo "  ① 检查 SQL 迁移文件..."
test -f backend/db/migrations/001_init_projects.sql || {
  echo "  ❌ 文件不存在"
  exit 1
}

# Step 2: SQL 语法检查
echo "  ② 检查 SQL 语法..."
psql --dry-run -f backend/db/migrations/001_init_projects.sql || {
  echo "  ❌ SQL 语法错误"
  exit 1
}

# Step 3: 表结构验证
echo "  ③ 验证表结构..."
grep -q "CREATE TABLE projects" backend/db/migrations/001_init_projects.sql || {
  echo "  ❌ projects 表定义缺失"
  exit 1
}

# Step 4: 字段验证
echo "  ④ 验证所需字段..."
for field in slug name site_url has_site market bootstrap_meta target_mention_rate; do
  grep -q "$field" backend/db/migrations/001_init_projects.sql || {
    echo "  ❌ 字段缺失：$field"
    exit 1
  }
done

# Step 5: 约束验证
echo "  ⑤ 验证约束..."
grep -q "PRIMARY KEY.*slug" backend/db/migrations/001_init_projects.sql || {
  echo "  ❌ 主键约束缺失"
  exit 1
}

echo "✅ 验收完成：1a-101"
exit 0
```

---

## 四、Skill 行为规范更新

### 4.1 严格禁止行为清单（强化版）

```
🚫 FORBIDDEN BEHAVIORS (HARDENED)

1. ❌ 在用户未说"测试通过"时自动进入 Mode 5
2. ❌ 在用户未完成三方确认时进入 Mode 3
3. ❌ 同时执行多个活跃任务
4. ❌ 跳过任何依赖任务
5. ❌ 在验收脚本失败时标记任务完成
6. ❌ 修改 TASKS.md 中的任务状态（除了在 Mode 5 中）
7. ❌ 在 Mode 3 中超过 2 小时不通知用户
8. ❌ 假设代码提交存在而不检查 git log
9. ❌ 虚报测试覆盖率或性能指标
10. ❌ 在 Mode 4 失败时继续进入 Mode 5
```

### 4.2 强制性检查清单

```
✅ MANDATORY CHECKS (BEFORE ANY ACTION)

Mode 1 时必须检查：
- [ ] NEXT.md 中只有一个活跃任务
- [ ] 该任务存在于 TASKS.md
- [ ] 该任务的所有依赖已完成
- [ ] 没有占位符在 NEXT.md 中

Mode 2 时必须检查：
- [ ] 展示三个独立的确认点
- [ ] 等待用户对每个点的明确回答
- [ ] 只有三个都"是"才进入 Mode 3

Mode 3 时必须检查：
- [ ] 不超过当前 NEXT.md 指定的任务
- [ ] 只修改 TASKS.md 中该任务涉及的文件
- [ ] 完成后列出改动文件
- [ ] 建议验收脚本
- [ ] 完成后立即 STOP，不自动进入 Mode 4

Mode 4 时必须检查：
- [ ] 运行验收脚本
- [ ] 记录输出到 TEST_LOG.md
- [ ] 如果脚本失败，提示修复建议，不进入 Mode 5

Mode 5 时必须检查：
- [ ] 验收脚本已通过
- [ ] 相关代码已提交到 git
- [ ] git log 中有该任务的提交记录
- [ ] STATUS.md 中记录 commit hash
- [ ] TASKS.md 中标记该任务为 [x]
- [ ] NEXT.md 更新为下一个任务或"no active task"
```

---

## 五、迁移路线图

### 5.1 三阶段优化实施计划

**Phase 1：Core Flow Hardening（2-3 天）**
- 实现 Hard Stop at Mode 3
- 强化 Mode 2 三方确认
- 添加明确的信号/触发词检查
- 优先级：P0

**Phase 2：Verification Automation（3-5 天）**
- 为所有 84 个任务编写验收脚本
- 集成验收脚本到 Mode 4/5
- 添加 TEST_LOG.md 自动记录
- 优先级：P1

**Phase 3：SSOT Validation（2-3 天）**
- 添加 git 代码提交检查到 Mode 5
- 实现 STATUS.md ↔ git log 双向校验
- 添加审计证据记录（commit hash）
- 优先级：P2

**Phase 4：DAG & Timeout（1-2 天）**
- 实现任务 DAG 验证
- 添加超时提醒机制
- 优先级：P3

---

### 5.2 向后兼容性考虑

```
现有 NEXT.md 格式：
  Active Task: ALL_TASKS_COMPLETED

迁移策略：
1. 自动检测旧格式
2. 转换为新格式（单任务 + Mode 记录）
3. 保留历史记录但从新版本开始执行

即：不破坏现有项目，但从现在开始执行新规则
```

---

## 六、成功指标

升级后，ProjectOrchestrator Skill 应该满足：

| 指标 | 当前 | 目标 | 验证方法 |
|---|---|---|---|
| 任务虚报率 | 100% | 0% | 随机抽查 5 个任务，检查代码提交 |
| Mode 转换正确率 | 70% | 99% | 检查 Mode 记录是否符合用户指令 |
| 验收脚本通过率 | 0% | 100% | 每个完成的任务都通过脚本验证 |
| SSOT 一致性 | 50% | 100% | 检查 STATUS.md vs git log vs 代码 |
| 用户干预次数（per 任务） | 1 次 | 3-5 次 | Mode 2 三方确认 + Mode 4 验证 |

---

这是对 ProjectOrchestrator Skill 的**系统性架构审视**。核心是：**将所有隐式假设变为显式检查，将文本标准变为可执行脚本，将自动化变为用户驱动**。

你想先从哪个 Phase 开始优化？