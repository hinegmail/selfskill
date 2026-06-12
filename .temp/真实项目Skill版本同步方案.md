# 真实项目中已应用的Skill版本同步方案

**时间**: 2026-06-12  
**问题**: selfskill项目中的skill.md已修复激活自进化，但真实项目（在宥丝巾AI）中已经复制的旧版skill需要更新

---

## 现状分析

### 版本差异

```
selfskill/skill.md (修复后)
  ├─ Mode 2输出: 🚀规划完成，准备就绪
  ├─ §3.1: Automatic Transition Triggers
  ├─ Mode 3前置: 自动检测
  └─ init.ps1: 完整的7-Mode流程说明

真实项目/skill.md (旧版本)
  ├─ Mode 2输出: ⏳等待用户确认
  ├─ §3.1: 不存在
  ├─ Mode 3前置: 用户确认
  └─ init.ps1: 仅提Context Audit
```

### 影响

当前真实项目中使用的还是**旧版skill**，存在：

- ❌ 用户仍需要显式说"确认"
- ❌ Mode 2→3转换仍然容易失败
- ❌ init.ps1仍然引导不清晰
- ❌ 自进化机制仍然不激活

---

## 同步方案

### 方案A: 直接复制更新（推荐✅）

**适用场景**: 真实项目的skill是从selfskill复制来的

**步骤**:

```bash
# 1. 进入真实项目目录
cd [真实项目路径]

# 2. 备份当前skill版本
cp skill.md skill.md.backup-v1.0

# 3. 从selfskill项目复制最新版本
cp d:\Users\Administrator\Documents\Projects\selfskill\skill.md ./skill.md

# 4. 如果有init.ps1，也更新
cp d:\Users\Administrator\Documents\Projects\selfskill\init.ps1 ./init.ps1

# 5. 提交版本更新
git add skill.md init.ps1
git commit -m "chore: update ProjectOrchestrator skill to v1.1 (activate self-evolution)"
git tag v1.1-skill-updated
```

**验证**:

```bash
# 检查是否包含新的§3.1
grep -n "Mode 2→Mode 3 Automatic Transition Triggers" skill.md
# 应该返回行号，证明新内容已包含

# 检查Mode 2输出是否更新
grep -n "🚀 **规划完成，准备就绪" skill.md
# 应该返回行号
```

---

### 方案B: 手动编辑更新（如有定制化）

**适用场景**: 真实项目对skill.md有定制化修改

**步骤**:

1. **打开真实项目的skill.md**
2. **找到Mode 2章节** (约L170-220)
3. **替换Mode 2输出**:
   ```markdown
   # 删除这部分
   ### ⏳ 等待用户确认
   请回复"确认"或"批准"以进入实现模式。
   
   # 替换为
   ---
   
   🚀 **规划完成，准备就绪！**
   
   以上规划已完成检查，技术路径清晰，验收标准明确。
   
   您现在可以：
   ① 说 **"执行"** 或 **"开始"** → 我立即进入实现模式开始编码
   ② 提出 **疑问或建议** → 我调整规划
   ③ 要求 **重新规划** → 我重新分析任务
   
   等待您的下一步指令...
   ```

4. **找到Mode 3章节开头** (约L230)
5. **更新Mode 3前置条件**:
   ```markdown
   # 替换这行
   **Trigger**: User confirms the Task Plan; or user says "确认 / 批准 / 开始实现 / approved / implement".
   **Precondition**: Task Plan confirmed by user. NEXT.md gate valid.
   
   # 改为
   **Trigger**: User provides affirmative signal matching Mode 2→3 Automatic Transition Triggers (see §3.1 below), OR user begins asking implementation-related technical questions.
   **Precondition**: Mode 2 output generated. NEXT.md gate valid.
   **Auto-Entry Logic**:
   - AI scans user's response for trigger words/patterns from the Transition Triggers list
   - If match found: **AUTOMATICALLY ENTER MODE 3** (no explicit permission needed)
   - If rejection words detected: remain in Mode 2, ask for clarification instead
   - If ambiguous: request explicit direction
   ```

6. **在Mode 2和Mode 3之间插入新的§3.1章节**（见附录A）

7. **更新init.ps1最后的用户引导**（见附录B）

---

### 方案C: 自动化脚本更新（技术方案）

如果真实项目中有多个地方使用了skill，可以写个更新脚本：

```python
#!/usr/bin/env python3
"""
同步ProjectOrchestrator Skill版本的自动化脚本
从selfskill项目复制最新修复到多个真实项目
"""

import os
import shutil
from pathlib import Path
from datetime import datetime

SELFSKILL_ROOT = r"d:\Users\Administrator\Documents\Projects\selfskill"
PROJECTS_TO_UPDATE = [
    r"[真实项目1路径]",
    r"[真实项目2路径]",
    # 其他项目...
]

def update_project(project_path):
    """更新单个项目的skill文件"""
    
    # 备份旧版本
    skill_file = os.path.join(project_path, "skill.md")
    if os.path.exists(skill_file):
        backup_file = f"{skill_file}.backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        shutil.copy2(skill_file, backup_file)
        print(f"✓ Backed up to {backup_file}")
    
    # 复制新版本
    source_skill = os.path.join(SELFSKILL_ROOT, "skill.md")
    shutil.copy2(source_skill, skill_file)
    print(f"✓ Updated {skill_file}")
    
    # 同步init.ps1
    source_init = os.path.join(SELFSKILL_ROOT, "init.ps1")
    dest_init = os.path.join(project_path, "init.ps1")
    if os.path.exists(source_init):
        shutil.copy2(source_init, dest_init)
        print(f"✓ Updated {dest_init}")

def main():
    print("🔄 ProjectOrchestrator Skill Version Sync")
    print(f"Source: {SELFSKILL_ROOT}")
    print()
    
    for project in PROJECTS_TO_UPDATE:
        if os.path.exists(project):
            print(f"Updating: {project}")
            update_project(project)
            print()
        else:
            print(f"⚠️ Project not found: {project}")
            print()
    
    print("✅ Sync complete!")

if __name__ == "__main__":
    main()
```

---

## 推荐操作步骤

### 立即执行（5分钟）

#### Step 1: 确认真实项目的skill.md位置

```bash
# 在真实项目中找skill.md
find . -name "skill.md" -type f
# 可能的位置:
# - 项目根目录
# - ./docs/
# - ./.ai/
# - ./.kiro/
```

#### Step 2: 选择同步方案

```
如果skill.md是从selfskill直接复制的 → 用方案A（直接复制）
如果skill.md有定制化修改 → 用方案B（手动编辑）
如果有多个项目需要同步 → 用方案C（自动脚本）
```

#### Step 3: 执行同步

**方案A示例**（最快）:
```bash
cd [真实项目]
cp skill.md skill.md.backup-v1.0
cp d:\Users\Administrator\Documents\Projects\selfskill\skill.md ./
git add skill.md
git commit -m "chore: sync ProjectOrchestrator skill v1.1"
```

#### Step 4: 验证更新

```bash
# 检查§3.1是否存在
grep "Mode 2→Mode 3 Automatic Transition Triggers" skill.md
# 应该有输出

# 检查Mode 2输出是否更新
grep "🚀 **规划完成，准备就绪" skill.md  
# 应该有输出
```

#### Step 5: 测试新流程

在真实项目中进行一次完整的Mode 1-5测试：

```
1. 在IDE中打开对话
2. 说: "继续项目"
3. AI执行Mode 1 → Mode 2
4. 您回复: "执行"
5. 观察: Mode 3是否自动启动？
6. 是 ✅ 表示同步成功
```

---

## 附录A: §3.1完整内容

```markdown
---

## 3.1 Mode 2→Mode 3 Automatic Transition Triggers（自动转换触发器）

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
```

---

## 附录B: init.ps1末尾更新

```powershell
Write-Host ""
Write-Host "[OK] Initialization complete!" -ForegroundColor Green
Write-Host ""
Write-Host "ProjectOrchestrator Skill: 7-Mode自动化运作流程" -ForegroundColor Cyan
Write-Host ""
Write-Host "├─ MODE 1: Context Audit        (加载项目状态)" -ForegroundColor Gray
Write-Host "├─ MODE 2: Task Planning        (规划当前任务，自动)" -ForegroundColor Gray
Write-Host "├─ MODE 3: Implementation       (执行编码，您说'执行'→自动启动)" -ForegroundColor Yellow
Write-Host "├─ MODE 4: Validation & Test    (运行测试，自动)" -ForegroundColor Gray
Write-Host "├─ MODE 5: Phase Closeout       (更新.ai/文件，自动 ✅)" -ForegroundColor Green
Write-Host "├─ MODE 6: Skill Evolution      (提案改进，按需)" -ForegroundColor Gray
Write-Host "└─ MODE 7: Context Refresh      (新对话推荐)" -ForegroundColor Gray
Write-Host ""
Write-Host "🚀 快速开始 (3步):" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1️⃣  在您的IDE (Cursor/Cline/Windsurf/Claude/Kiro等) 打开对话" -ForegroundColor White
Write-Host ""
Write-Host "  2️⃣  说这条命令:" -ForegroundColor White
Write-Host ""
Write-Host '      继续项目' -ForegroundColor Yellow
Write-Host ""
Write-Host "  3️⃣  AI会自动执行 Mode 1 → Mode 2 → 等待您说'执行' → 自动进入 Mode 3-5" -ForegroundColor White
Write-Host ""
Write-Host "💡 提示:" -ForegroundColor Green
Write-Host "  • 任何肯定回复（'开始','好的','OK'等）都会触发实现" -ForegroundColor DarkGray
Write-Host "  • 无需记住特殊命令，自然表达即可" -ForegroundColor DarkGray
Write-Host "  • 如要调整规划，说'改一下'或'重新规划'" -ForegroundColor DarkGray
Write-Host ""
```

---

## 同步检查清单

完成同步后，检查以下项目：

```
□ skill.md已更新到新版本
□ 新版本包含§3.1 Automatic Transition Triggers
□ Mode 2输出改为"🚀准备就绪"
□ Mode 3前置条件改为自动检测
□ init.ps1已更新（如有）
□ init.ps1显示完整的7-Mode流程说明
□ Git提交成功（commit message包含"skill"或"v1.1"）
□ 在真实项目中测试Mode 1-5流程
□ 测试中用户说"执行"后自动进入Mode 3
□ Mode 3输出显示"▶️ Mode 3: Task Implementation 进行中"
□ 任务完成后自动进入Mode 4→5
```

---

## 风险评估

| 风险 | 等级 | 缓解措施 |
|------|------|--------|
| 破坏现有工作流 | 🟢 低 | 仅改进触发逻辑，向后兼容 |
| 丢失旧版本 | 🟢 低 | 建议创建backup-v1.0 |
| 定制化冲突 | 🟡 中 | 如有定制，使用方案B手动更新 |
| 版本不一致 | 🟢 低 | 更新后使用git tag标记版本 |

---

## 后续行动

### 短期（今天）

- [ ] 确认真实项目的skill.md位置
- [ ] 选择合适的同步方案
- [ ] 执行同步
- [ ] 本地验证更新

### 中期（本周）

- [ ] 在真实项目中执行一次完整的Task
- [ ] 观察是否成功触发Mode 1→5自动化
- [ ] 确认.ai/文件是否自动更新

### 长期（持续）

- [ ] 将selfskill中的skill.md作为"黄金副本"
- [ ] 定期检查是否有新的修复需要同步
- [ ] 建立版本管理流程（Git tags）
- [ ] 文档说明skill版本号

---

## 总结

### 当前状态

```
selfskill/skill.md      ✅ 已修复 v1.1
真实项目/skill.md        ⚠️ 仍是旧版 v1.0
```

### 行动

**同步真实项目的skill至v1.1**，激活自进化

### 预期结果

修复同步后，真实项目将：

✅ Mode 2→3流程自动化  
✅ 用户不需记住特殊命令  
✅ 自动化流程完整启动  
✅ .ai/文件自动更新  
✅ 知识自动沉淀  

---

**同步方案生成时间**: 2026-06-12 17:00 UTC

