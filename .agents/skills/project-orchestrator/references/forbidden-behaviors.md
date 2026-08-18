# 禁止行为与安全审计规则

> 本文件包含 ProjectOrchestrator 技能的全部禁止行为清单和安全审计规则。SKILL.md 中仅包含摘要，完整规则在此。

---

## 禁止行为清单

以下行为**严格禁止**，在任何模式下都不可违反:

1. **仅基于对话记忆继续开发** — 必须从 `.ai/` 文件恢复状态。
2. **未读取 `.ai/` 文档就开始实现** — 必须先执行上下文审计。
3. **跳过上下文审计模式** — Mode 1 是所有开发的前提。
4. **同时执行多个任务** — NEXT.md 闸门确保单任务执行。
5. **完成一个任务后自动开始下一任务** — 需用户明确指示。
6. **编造 requirements.md 中不存在的需求** — 需求以文件为准。
7. **忽略 TASKS.md 中的验收标准** — 必须逐条检查。
8. **忽略 NEXT.md 闸门** — 闸门失败时必须停止。
9. **无明确需要时重写已测试模块** — 不做不必要的重写。
10. **在功能实现期间重构无关模块** — 保持范围聚焦。
11. **在测试修复期间添加新功能** — 修复阶段仅修复。
12. **将旧 DESIGN.md 文本视为比 STATUS.md 更新** — STATUS.md 优先。
13. **静默更改架构** — 架构变更需提案和批准。
14. **静默重写 DESIGN.md 或 TASKS.md 结构** — 结构变更需提案。
15. **未经正式提案和明确用户批准修改本技能** — Mode 6.5 批准后可修改。
16. **将一次性修复转为永久规则而不审查** — 需通过认知蒸馏流程。
17. **未经验证或批准就标记任务完成** — 必须通过 Mode 4 验证。
18. **隐藏文档与代码之间的未解决冲突** — 必须停止并报告。
19. **编写重复逻辑或重复工具函数** — 编写前先搜索现有实现。
20. **在最终实现中遗留死代码、未使用导入或临时调试日志** — 如 `console.log`、`print`。
21. **过度工程化** — 不引入未使用的抽象层或假设性未来需求的占位符。
22. **为单个子任务完成创建单独的一次性 Markdown 文档** — 所有子任务完成记录在 `.ai/TASKS.md` 和 `.ai/STATUS.md` 中。

---

## 安全与审计规则

### 文件修改授权
- AI 仅在用户授权后修改仓库文件。
- 优先使用 PR 或用户批准的提交。
- 所有自动回写必须包含作者/原因/时间戳元数据。
- 阶段收口后建议 Git 提交并打标签（如 `v0.2-phase2`）。

### 破坏性操作防护
- AI **不得**在无明确用户指示的情况下执行破坏性操作:
  - 数据库删除/重置
  - 生产环境部署
  - 批量文件删除
  - 不可逆的数据迁移

### Git 提交规范
- 提交消息格式: `ai: closeout task {ID}` 或 `ai: {描述}`
- 标签格式: `v{版本}-phase{阶段号}`（如 `v0.2-phase2`）
- 提交前确保所有 `.ai/` 文件已更新且通过收口后验证

---

## Git Hook 状态校验

建议用户创建 Git pre-commit 钩子防止 AI 状态幻觉:

### Pre-commit Hook 脚本

创建 `.git/hooks/pre-commit` 文件:

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

### 钩子安装说明

```bash
# 赋予执行权限
chmod +x .git/hooks/pre-commit

# 测试钩子
git commit --allow-empty -m "test: pre-commit hook check"
```

### Windows (PowerShell) 等效检查

如需在 Windows 环境手动执行等效检查:

```powershell
# Check NEXT.md and TASKS.md consistency
if ((Test-Path ".ai/NEXT.md") -and (Test-Path ".ai/TASKS.md")) {
    $activeTask = (Select-String -Path ".ai/NEXT.md" -Pattern "Task [0-9]+\.[0-9]+" | Select-Object -First 1).Matches.Value
    if ($activeTask) {
        $taskCompleted = (Select-String -Path ".ai/TASKS.md" -Pattern "\[x\] $activeTask").Count -gt 0
        $taskActive = (Select-String -Path ".ai/NEXT.md" -Pattern "Active = $activeTask").Count -gt 0
        if ($taskCompleted -and $taskActive) {
            Write-Host "❌ Integrity Error: $activeTask is complete but still Active in NEXT.md" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "✅ Document integrity check passed" -ForegroundColor Green
```
