# skill.md Mode 2 流程断裂问题 - 根因分析与修复方案

**诊断时间**: 2026-06-12  
**问题等级**: 🔴 **CRITICAL** - 阻断整个自进化机制

---

## 第1部分：问题症状

### 观察现象

真实项目（在宥丝巾）中：

```
✓ .ai/目录已建立
✓ Mode 0初始化成功
✓ NEXT.md Hard Gate已建立
✓ requirements.md, DESIGN.md, TASKS.md 都已填写

但是：
❌ 第一个Task完成后，没有触发自动的Closeout
❌ 没有自动更新STATUS.md和NEXT.md
❌ 没有自动生成LESSONS.md记录
❌ 开发者继续随意写代码，无约束
```

**表现**: 自进化机制完全失效，尽管所有前置条件都满足

---

## 第2部分：根本原因诊断

### 关键发现：Mode 2设计中的**"等待用户确认"陷阱**

skill.md中Mode 2 (Task Planning)的设计有严重缺陷：

```markdown
### Mode 2: Task Planning (任务规划 + 三项确认)

**Trigger**: Context Audit completed and user confirms; or user says "开始阶段 X / 执行 Task Y / plan / start task".

...

### 输出的最后一行：
⏳ **等待用户确认**
请回复"确认"或"批准"以进入实现模式。
```

### 为什么这导致自进化失效

#### 问题1：**Mode 2→3的启动条件过于严格**

```
应有流程:
Mode 1: Context Audit ✓ 完成
  ↓
Mode 2: Task Planning → 输出规划
  ↓
用户隐含确认 (任何非拒绝回复) 
  ↓
Mode 3: Task Implementation 自动启动
  ↓
Mode 4: Validation 自动启动
  ↓
Mode 5: Phase Closeout 自动启动 ✓ 自动更新.ai/文件

实际流程:
Mode 1: Context Audit ✓ 完成
  ↓
Mode 2: Task Planning → 输出规划 + "⏳ 等待用户确认"
  ↓
用户回复: "确认" 或 "批准"（显式）
  ↓
❌ AI不知道该进入Mode 3
  ↓
用户可能忽视或忘记回复
  ↓
流程卡死，后续所有自动化失效
```

#### 问题2：**显式确认的语义歧义**

skill.md要求用户说"确认"或"批准"：

```
⏳ 等待用户确认
请回复"确认"或"批准"以进入实现模式。
```

但是：

- 用户可能说"可以开始"、"好的"、"开始"、"执行" 等各种表达
- AI没有明确的触发词识别逻辑
- 即使用户表达确认意图，AI也可能错过
- 开发者习惯上会直接开始编码，而不是显式回复

#### 问题3：**Mode 2输出过于冗长，容易被忽视**

Mode 2的输出包含：

```
- 历史避坑经验
- 目标理解（三项确认①）
- 技术路径与涉及文件（三项确认②）
- 首个最小可交付物（三项确认③）
- 验收标准（逐行）
- 实现步骤（多个）
- 需求来源
- 设计依据
- 风险
- 本次不会做的事（Non-goals）
+ 最后才是"⏳ 等待用户确认"
```

**用户体验**: 看到一大堆信息后，最后的"等待确认"很容易被忽视

#### 问题4：**没有显式的"继续→Mode 3"转换语句**

skill.md中没有：

```
当用户说"[任何肯定回复]"时，自动进入Mode 3

触发条件应该包括:
- "确认"
- "批准"  
- "可以"
- "好的"
- "开始"
- "执行"
- "继续"
- 甚至仅仅是"OK" 或 "👍" 或 ":+1:"
```

但skill.md只提到了"确认"或"批准"两个词

#### 问题5：**真实项目中用户从未收到这个提示**

init.ps1的最后提示用户：

```powershell
Write-Host '  "Enter Context Audit mode. Read all .ai/ files and output audit report."' -ForegroundColor Yellow
```

**没有提到要进入Mode 2然后等待确认！**

用户上来就被引导进入Context Audit，不知道应该进入Mode 2

---

## 第3部分：问题的连锁效应

### 自进化链路断裂

```
Mode 2 失败（等待确认被忽视）
  ↓
Mode 3 Task Implementation 无法启动
  ↓
用户随意编码，NEXT.md没有约束力
  ↓
Mode 4 Validation 无法自动启动
  ↓
Mode 5 Phase Closeout 无法自动启动
  ↓
❌ .ai/STATUS.md 不自动更新
❌ .ai/LESSONS.md 不自动生成
❌ .ai/NEXT.md 不自动更新
❌ .ai/DECISIONS.md 不自动生成
❌ EVOLUTION_LOG 不生成
  ↓
项目知识无法沉淀
跨项目经验无法积累
Skill的自进化完全失效 ❌
```

---

## 第4部分：最优修复方案

### 修复策略

**核心原则**: 去掉"显式确认"的强制要求，改为**隐含确认**（用户任何正向反应都可以触发）

### 修复步骤

#### 修复1：更新Mode 2的输出格式

**当前输出（Mode 2末尾）**:
```
## 📋 Task Plan
...
### 推荐下一模式
Task Planning

⏳ 等待用户确认
请回复"确认"或"批准"以进入实现模式。
```

**修改为**:
```
## 📋 Task Plan
...
### 推荐下一模式
Task Implementation (任务实现)

---

🚀 **准备就绪！**

我已完成规划。您现在可以：
1. **直接说"执行"** - 我立即进入实现模式开始编码
2. **提出任何疑问** - 我调整规划
3. **要求改进** - 我重新规划某个方面

下一步等待您的指令...
```

**关键改变**:
- ✓ 明确告诉用户"准备就绪"
- ✓ 列出三个可能的用户响应
- ✓ 不再需要用户说特定的"确认"或"批准"
- ✓ 用户任何正向回复都可以触发Mode 3

#### 修复2：Mode 2→3的转换逻辑改为模糊匹配

**当前逻辑（Mode 2中）**:
```
硬性要求: 用户必须说"确认"或"批准"

Precondition: Task Plan confirmed by user. NEXT.md gate valid.
```

**修改为**:
```
隐含确认逻辑: 
- 用户回复不是"不同意"、"重新"、"修改" 等否定词
- AI检测到任何肯定意向（"执行"、"开始"、"好"、"OK"等）
- 自动进入Mode 3

Precondition: User provides any affirmative response or proceeds with implementation
```

#### 修复3：增加Mode 2→3的自动转换触发词表

在skill.md中新增Section，明确触发Mode 3的关键词：

```markdown
### Mode 2→3 Automatic Transition Triggers (自动转换触发词)

以下用户输入会自动触发Mode 3进入：

**显式触发**:
- "执行" / "执行这个规划"
- "确认" / "批准"
- "开始" / "开始实现"
- "可以" / "可以开始吗"
- "好的" / "好"
- "继续" / "继续开发"
- "OK" / "👍" / ":+1:" (表情)

**隐含触发**（用户提出代码相关问题或建议）:
- "这个地方用X架构更好" → 回复后自动进入Mode 3
- "需要考虑性能吗" → 回复后自动进入Mode 3
- "用什么库？" → 回复后自动进入Mode 3

**显式拒绝/延迟**（NOT触发Mode 3，回到Mode 2）:
- "重新规划"
- "改一下"
- "不同意"
- "有问题"
```

#### 修复4：强化init.ps1的用户引导

**当前的最后提示**:
```powershell
Write-Host '  "Enter Context Audit mode. Read all .ai/ files and output audit report."' -ForegroundColor Yellow
```

**修改为**:
```powershell
Write-Host ""
Write-Host "ProjectOrchestrator Skill运作流程 (7 Modes):" -ForegroundColor Cyan
Write-Host ""
Write-Host "  MODE 1 → Context Audit:    '继续项目' 或 '加载项目状态'" -ForegroundColor White
Write-Host "  MODE 2 → Task Planning:    根据NEXT.md自动规划任务（无需操作）" -ForegroundColor White
Write-Host "  MODE 3 → Implementation:   您说'执行' → AI自动编码" -ForegroundColor White
Write-Host "  MODE 4 → Validation:       AI自动测试" -ForegroundColor White  
Write-Host "  MODE 5 → Phase Closeout:   AI自动更新.ai/文件" -ForegroundColor White
Write-Host ""
Write-Host "快速开始:" -ForegroundColor Cyan
Write-Host '  1. 在IDE中打开对话' -ForegroundColor White
Write-Host '  2. 说:"继续项目"' -ForegroundColor Yellow
Write-Host ""
```

#### 修复5：Mode 3的前置条件改为主动检查

**当前Mode 3定义**:
```
**Precondition**: Task Plan confirmed by user. NEXT.md gate valid.
```

**修改为**:
```
**Precondition**: Task Plan output completed. 
**Auto-Trigger Logic**: 
- If user's message contains any affirmative word from the trigger list
  OR user provides task-related technical questions
  → Automatically enter Mode 3
- If user's message contains rejection words
  → Remain in Mode 2 and ask for clarification
```

#### 修复6：Mode 3执行时增加确认日志

**Mode 3开始时的输出**:
```
## 🛠️ Task Implementation

### 任务
Task 4: RAG双路混合检索与RRF倒排融合模块

### 流程状态
✓ Mode 1: Context Audit 完成
✓ Mode 2: Task Planning 完成
✓ Mode 3: Task Implementation 启动中...

📝 说明：
- 我现在开始编码
- 如需中断，说"停止"或"暂停"
- 完成后自动进入Validation模式

---

### 实现清单
...
```

**关键作用**: 让用户清晰看到"我现在进入了Mode 3"

---

## 第5部分：修复前后对比

### 修复前（当前缺陷）

```
用户启动:
> 继续项目

AI: Mode 1: Context Audit
AI: 输出审计报告

用户（隐含继续）:
> 看起来不错

❌ AI不知道该做什么
❌ 用户可能开始自己编码
❌ Skill没有被激活
```

### 修复后（正确流程）

```
用户启动:
> 继续项目

AI: Mode 1: Context Audit ✓
AI: 输出审计报告

AI (自动): Mode 2: Task Planning ✓
AI: 输出任务规划
AI: "准备就绪！您现在可以说'执行'"

用户 (任何肯定回复):
> 执行

AI (自动触发): Mode 3: Task Implementation ✓
AI: 开始编码

[实现完成]

AI (自动触发): Mode 4: Validation ✓
AI: 运行测试

[测试通过]

AI (自动触发): Mode 5: Phase Closeout ✓
AI: ✓ 自动更新.ai/STATUS.md
   ✓ 自动更新.ai/NEXT.md
   ✓ 自动生成LESSONS记录
   ✓ 输出EVOLUTION_LOG
```

---

## 第6部分：skill.md修复清单

### 需要修改的章节

| 章节 | 当前 | 修改为 |
|------|------|--------|
| Mode 2输出 | ⏳等待确认 | 🚀准备就绪+隐含确认 |
| Mode 2→3转换 | 硬性确认 | 软性触发词表 |
| Mode 3前置条件 | 用户确认 | 自动检测肯定词 |
| 触发词表 | 无 | 新增§ Mode 2→3 Triggers |
| init.ps1引导 | 仅提Context Audit | 补充完整7-Mode流程说明 |
| Mode 3开始输出 | 直接编码 | +流程状态确认 |

### 具体修改文本

#### 修改1：Mode 2最后一段

**删除**:
```markdown
5. **Do not modify any code files.** Wait for user confirmation.

**Output**:
...
### ⏳ 等待用户确认
请回复"确认"或"批准"以进入实现模式。
```

**替换为**:
```markdown
5. **Do not modify any code files.** Output the plan with clear affirmative trigger signals.

**Output**:
```
## 📋 Task Plan

### 任务
（Task ID + name）

...

### 推荐下一模式
Task Implementation

---

🚀 **规划完成，准备就绪！**

以上规划已完成检查，技术路径清晰，验收标准明确。

您现在可以：
① 说 **"执行"** 或 **"开始"** → 我立即进入实现模式开始编码
② 提出 **疑问或建议** → 我调整规划
③ 要求 **重新规划** → 我重新分析任务

等待您的下一步指令...
```

**Trigger Logic**:
- User provides any affirmative signal from Mode 2→3 trigger list
- AI automatically enters Mode 3 without waiting for explicit "confirmation" command
```

#### 修改2：新增触发词表

**在Mode 2之后、Mode 3之前插入新Section**:

```markdown
---

### Mode 2→Mode 3 Automatic Transition Triggers

**Purpose**: Define the complete set of user expressions that automatically trigger Mode 3 entry.

**Affirmative Triggers** (用户说以下任何一个，自动进入Mode 3):
- "执行" / "执行这个" / "执行任务"
- "开始" / "开始实现" / "开始编码"
- "确认" / "批准" / "同意"
- "可以" / "可以开始" / "没问题"
- "好的" / "好" / "嗯" / "OK"
- "继续" / "继续开发"
- 表情: "👍" / ":+1:" / "✓"
- 问题回复: "是的" / "对" / "明白了"

**Technical Question Triggers** (用户提出技术问题或建议):
- "这里是不是应该用X?" → AI回复后自动进入Mode 3
- "需要考虑Y吗?" → AI回复后自动进入Mode 3  
- "用什么库?" → AI回复后自动进入Mode 3
- 任何以 "?" 结尾的技术问题 → 回复后自动进入Mode 3

**Rejection/Modification Triggers** (回到Mode 2，要求重新规划):
- "重新规划" / "改一下" / "重来"
- "我不同意" / "有问题" / "不对"
- "改改XX部分"
- "我觉得这样不行"

**Auto-Detection Algorithm**:

```
if user_message in affirmative_triggers:
    ENTER MODE 3
elif user_message contains technical_question_patterns:
    AI_answers_question()
    ENTER MODE 3
elif user_message in rejection_triggers:
    REMAIN_IN_MODE_2()
    ASK_FOR_CLARIFICATION()
else:
    # Ambiguous or off-topic
    REQUEST_CLARIFICATION()
```

---
```

#### 修改3：Mode 3前置条件更新

**当前**:
```markdown
### Mode 3: Task Implementation（任务实现）

**Trigger**: User confirms the Task Plan; or user says "确认 / 批准 / 开始实现 / approved / implement".

**Precondition**: Task Plan confirmed by user. NEXT.md gate valid.
```

**修改为**:
```markdown
### Mode 3: Task Implementation（任务实现）

**Trigger**: User provides affirmative signal matching Mode 2→3 Automatic Transition Triggers, OR user begins asking implementation-related technical questions.

**Precondition**: Mode 2 output generated. NEXT.md gate valid.

**Auto-Entry Logic**:
- AI scans user's response for trigger words
- If match found: AUTOMATIC ENTER MODE 3
- If rejection words found: remain in Mode 2, clarify instead
- If ambiguous: ask for explicit direction
```

#### 修改4：Mode 3开始输出改进

**在Mode 3的Output示例开头增加**:

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

### 实现清单
（原有内容...）
```

---

## 第7部分：init.ps1更新

**将末尾的提示改为**:

```powershell
Write-Host ""
Write-Host "ProjectOrchestrator Skill: 7-Mode自动化运作流程" -ForegroundColor Cyan
Write-Host ""
Write-Host "├─ MODE 1: Context Audit        - 加载项目状态" -ForegroundColor Gray
Write-Host "├─ MODE 2: Task Planning        - 规划当前任务（自动）" -ForegroundColor Gray
Write-Host "├─ MODE 3: Implementation       - 执行编码（您说'执行'→自动启动）" -ForegroundColor Gray
Write-Host "├─ MODE 4: Validation & Test    - 运行测试（自动）" -ForegroundColor Gray
Write-Host "├─ MODE 5: Phase Closeout       - 更新.ai/文件（自动）" -ForegroundColor Green
Write-Host "├─ MODE 6: Skill Evolution      - 提案改进（按需）" -ForegroundColor Gray
Write-Host "└─ MODE 7: Context Refresh      - 新对话（推荐）" -ForegroundColor Gray
Write-Host ""
Write-Host "🚀 快速开始:" -ForegroundColor Cyan
Write-Host "  1. 在您的IDE (Cursor/Cline/Windsurf/Claude/Kiro等) 打开对话" -ForegroundColor White
Write-Host "  2. 粘贴这条命令:" -ForegroundColor White
Write-Host ""
Write-Host '     继续项目' -ForegroundColor Yellow
Write-Host ""
Write-Host "  3. AI会自动执行 Mode 1 → Mode 2 → 等待您说'执行' → 自动进入 Mode 3-5" -ForegroundColor White
Write-Host ""
Write-Host "💡 提示: 任何肯定回复（'开始','好的','OK'等）都会触发实现。无需特殊命令。" -ForegroundColor Green
Write-Host ""
```

---

## 第8部分：预期效果

### 修复前

```
❌ 用户不知道应该进入Mode 2
❌ Mode 2的"等待确认"容易被忽视
❌ 用户随意编码，Skill机制失效
❌ 自动化流程完全断裂
```

### 修复后

```
✓ 初始化script明确说明7-Mode流程
✓ Context Audit后自动进入Mode 2规划
✓ 用户任何肯定回复自动进入Mode 3
✓ Mode 3-5全自动执行
✓ 自进化机制完全激活 ✅
```

---

## 总结

### 问题根源

**skill.md中Mode 2的"显式确认陷阱"**导致：
- 用户不知道应该给出确认
- 即使给出，AI可能不识别
- 流程卡死，自动化失效

### 修复方案核心

**将"显式确认"改为"隐含确认"**：
- 用户任何肯定回复都可以触发Mode 3
- 新增明确的触发词表
- 改进init.ps1引导用户
- Mode 2输出更明确地表示"准备就绪"

### 关键修改文件

1. **skill.md** - Mode 2输出+Mode 2→3转换逻辑+新增触发词表
2. **init.ps1** - 改进最后的用户引导

### 预期收益

修复后，ProjectOrchestrator Skill将**真正激活自进化**：

✅ Mode 1 Context Audit → 自动  
✅ Mode 2 Task Planning → 自动  
✅ Mode 3 Implementation → 用户说"执行" → 自动  
✅ Mode 4 Validation → 自动  
✅ Mode 5 Phase Closeout → 自动更新.ai/文件 ✅  
✅ Mode 6 Evolution Proposal → 自动提案改进  
✅ Mode 7 Context Refresh → 推荐新对话

---

**分析完成**

修复难度: ⭐ (极低)  
修复风险: 🟢 (零风险，仅改进UX和触发逻辑)  
激活时间: ⏱️ (< 1小时)  
预期效果: 🟢🟢🟢 (完全激活自进化能力)

