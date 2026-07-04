# ProjectOrchestrator Skill 版本追踪

## 当前版本

| 组件 | 版本 | 状态 | 最后更新 |
|------|------|------|---------|
| **skill.md** | v1.0 | ✅ 稳定 | 2026-07-04 |
| **适配器** | v1.0 | ✅ 同步 | 2026-07-04 |
| **模板** | v1.0 | ✅ 同步 | 2026-07-04 |

---

## 发布说明 (v1.0)

### 新增功能
- **STEERING.md 优化**：新增工作空间规则文件，支持针对不同项目的个性化 AI 行为配置
- **认知蒸馏增强**：改进 EVOLUTION_PROPOSALS.md 提议机制，支持更精细的知识积累
- **双轨认知完善**：执行轨道与进化轨道的协调机制优化

### 改进项
- 更新所有 9 个 IDE 适配器，确保版本对齐
- 优化 templates/ai/ 文件引用，统一使用 requirements.md（替代旧的 PRD.md）
- 改进模板引擎的 Jinja2 渲染性能

### 修复项
- 修复 .cursorrules 中的触发关键词不一致问题
- 更正 CLAUDE.md 中文件路径引用错误

### 兼容性
- ✅ 向后兼容 v1.0.1 项目（无需迁移）
- ✅ 支持所有主流 IDE（Cursor、Cline、Windsurf、Claude Code、Gemini、Antigravity、Kiro）

---

## 发布前同步检查清单

在发布新版本前，请逐一完成以下检查项。每一项都是**可执行且清晰明确**的。

### 1. 版本号一致性检查
- [ ] **skill.md** 的第一行包含版本 `v1.0`（查看：`grep -n "v1.0" skill.md | head -1`）
- [ ] **KIRO_AGENT.md** 包含 `v1.0`（查看：`grep "v1.0" adapters/KIRO_AGENT.md | wc -l`，应 ≥ 1）
- [ ] **ANTIGRAVITY.md** 包含 `v1.0`（查看：`grep "v1.0" adapters/ANTIGRAVITY.md | wc -l`，应 ≥ 1）
- [ ] **cursor.mdc** 包含 `v1.0`（查看：`grep "v1.0" adapters/cursor.mdc | wc -l`，应 ≥ 1）
- [ ] **clinerules.md** 包含 `v1.0`（查看：`grep "v1.0" adapters/clinerules.md | wc -l`，应 ≥ 1）
- [ ] **CLAUDE.md** 包含 `v1.0`（查看：`grep "v1.0" adapters/CLAUDE.md | wc -l`，应 ≥ 1）
- [ ] **windsurfrules.md** 包含 `v1.0`（查看：`grep "v1.0" adapters/windsurfrules.md | wc -l`，应 ≥ 1）
- [ ] **gemini_styleguide.md** 包含 `v1.0`（查看：`grep "v1.0" adapters/gemini_styleguide.md | wc -l`，应 ≥ 1）
- [ ] **AGENTS.md** 包含 `v1.0`（查看：`grep "v1.0" adapters/AGENTS.md | wc -l`，应 ≥ 1）

**快速检查命令**：
```bash
echo "=== 版本号检查 ===" && \
for file in skill.md adapters/*.md adapters/*.mdc adapters/cursorrules; do \
  if [ -f "$file" ]; then \
    count=$(grep -c "v1.0" "$file" 2>/dev/null || echo 0); \
    echo "$file: $count 次"; \
  fi; \
done
```

### 2. 文件名引用检查
- [ ] **所有适配器文件** 均引用 `requirements.md`（不是 `PRD.md`、`REQUIREMENTS.md` 或其他变体）
  - 验证命令：`grep -l "requirements.md" adapters/* | wc -l` 应返回 **≥ 8**
- [ ] **无旧文件名引用**（`PRD.md`、`RD.md` 等）
  - 验证命令：`grep -r "PRD\.md\|RD\.md" adapters/ | wc -l` 应返回 **0**
- [ ] **templates/ai/ 中的文件** 名称与 NEXT.md、DESIGN.md 等保持一致
  - 验证命令：`ls templates/ai/ | sort` 与预期列表比对

**快速检查命令**：
```bash
echo "=== 文件名引用检查 ===" && \
echo "requirements.md 出现次数:" && \
grep -r "requirements\.md" adapters/ | wc -l && \
echo "旧文件名 (PRD.md) 出现次数:" && \
grep -r "PRD\.md" adapters/ | wc -l
```

### 3. 语法与格式检查
- [ ] **markdown 适配器** 的前置元信息正确（版本号、描述、IDE 名称）
  - 验证命令：每个 .md 文件第一行包含 `#` 标题
- [ ] **cursor.mdc** 遵循 MDC 格式（以 `---` 分隔的前置元信息）
  - 验证命令：`head -5 adapters/cursor.mdc` 包含 `---`
- [ ] **cursorrules** 纯文本格式，无 markdown 标记
  - 验证命令：`file adapters/cursorrules` 返回 `ASCII text`
- [ ] **无中文代码注释** 在非 .ai 文件中（保持英文）
  - 验证命令：`grep -r "# 中文\|// 中文" adapters/ | wc -l` 应返回 **0**

**快速检查命令**：
```bash
echo "=== 语法检查 ===" && \
echo "检查 cursor.mdc 前置元信息:" && \
head -2 adapters/cursor.mdc && \
echo "检查适配器文件计数:" && \
ls -1 adapters/ | grep -E "\.(md|mdc)$|cursorrules|^[A-Z_]+$" | wc -l
```

### 4. 触发关键词一致性检查
- [ ] 所有 9 个适配器文件 **均包含完整的触发关键词表**（包含 "continue", "sync", "plan" 等）
  - 验证命令：`grep -c "continue\|sync\|plan" adapters/KIRO_AGENT.md` 应 ≥ 3
- [ ] 关键词表在各适配器中的 **含义保持一致**（无翻译差异或遗漏）
  - 手动检查：对比任意两个适配器中的关键词表是否语义相同

**快速检查命令**：
```bash
echo "=== 触发关键词检查 ===" && \
echo "KIRO_AGENT.md 中的关键词数:" && \
grep -o "continue\|sync\|plan\|implement\|test\|validate" adapters/KIRO_AGENT.md | wc -l
```

### 5. 适配器更新检查
- [ ] **KIRO_AGENT.md** 已更新（修改时间 ≥ 当日）
- [ ] **ANTIGRAVITY.md** 已更新
- [ ] **cursor.mdc** 已更新
- [ ] **clinerules.md** 已更新
- [ ] **CLAUDE.md** 已更新
- [ ] **windsurfrules.md** 已更新
- [ ] **gemini_styleguide.md** 已更新
- [ ] **AGENTS.md** 已更新
- [ ] **cursorrules** 已更新

**快速检查命令**：
```bash
echo "=== 适配器更新检查 ===" && \
stat -f "%m %N" adapters/* 2>/dev/null || \
stat --format "%y %n" adapters/* 2>/dev/null | \
tail -20
```

### 6. templates/ai/ 目录结构检查
- [ ] **requirements.md** 存在且非空
- [ ] **DESIGN.md** 存在且非空
- [ ] **TASKS.md** 存在且非空
- [ ] **STATUS.md** 存在且非空
- [ ] **NEXT.md** 存在且非空
- [ ] **RULES.md** 存在且非空
- [ ] **TEST_LOG.md** 存在且非空
- [ ] **DECISIONS.md** 存在且非空
- [ ] **LESSONS.md** 存在且非空
- [ ] **EVOLUTION_PROPOSALS.md** 存在且非空
- [ ] **STEERING.md** 存在且非空

**快速检查命令**：
```bash
echo "=== templates/ai/ 检查 ===" && \
for file in requirements.md DESIGN.md TASKS.md STATUS.md NEXT.md RULES.md TEST_LOG.md DECISIONS.md LESSONS.md EVOLUTION_PROPOSALS.md STEERING.md; do \
  if [ -f "templates/ai/$file" ]; then \
    size=$(wc -c < "templates/ai/$file"); \
    echo "✓ $file ($size bytes)"; \
  else \
    echo "✗ $file (缺失)"; \
  fi; \
done
```

### 7. GitHub Actions 工作流验证
- [ ] `.github/workflows/validate-adapter-versions.yml` 存在（如有 CI/CD）
- [ ] 工作流中的版本号检查规则已配置
- [ ] 工作流中的文件名引用检查已配置
- [ ] PR 上的所有检查已通过 ✅

**手动步骤**：
1. 推送到 GitHub 分支
2. 查看 GitHub Actions 标签页，确认所有检查通过
3. 如有失败，根据错误消息修复

### 8. Pre-commit Hook 验证（本地）
- [ ] `.git/hooks/pre-commit` 脚本存在（如已配置）
- [ ] 本地提交时，钩子已触发并通过
- [ ] 无版本号不匹配警告

**手动步骤**：
```bash
# 如已配置 pre-commit，运行：
git commit -m "chore: sync adapters to v1.0.2"
# 观察输出，确保无 ❌ 错误
```

### 9. 适配器在各 IDE 中的测试
- [ ] **Cursor** 中加载 `.cursor/rules/project-orchestrator.mdc`，无语法错误
- [ ] **Cline** 中加载 `.clinerules/project-orchestrator.md`，无语法错误
- [ ] **Windsurf** 中加载 `.windsurfrules`，无语法错误
- [ ] **Claude Code** 中加载 `CLAUDE.md`，无语法错误（如适用）
- [ ] **Gemini Code Assist** 中加载 `.gemini/styleguide.md`，无语法错误
- [ ] **其他 IDE**（Antigravity、Kiro 等）的适配器加载正常

**手动步骤**：
1. 在各 IDE 中打开对应的适配器文件
2. 确认 IDE 无错误提示（如红色波浪线、语法错误）
3. 记录测试结果

### 10. 发布说明更新
- [ ] 此文件（.ai/SKILL_VERSION.md）中的"发布说明"已补充最新版本信息
- [ ] "发布历史"中已添加新版本条目
- [ ] "发布前必需的同步检查清单"已为下一版本准备好模板

### 11. Git 提交和标签
- [ ] 所有修改文件已分阶段提交：
  ```bash
  git add skill.md adapters/ .ai/SKILL_VERSION.md templates/ai/
  git commit -m "chore: sync adapters to v1.0.2"
  ```
- [ ] Git 标签已创建：
  ```bash
  git tag -a v1.0.2 -m "Release v1.0.2: Steering.md optimization & adapter sync"
  git push origin v1.0.2
  ```
- [ ] 标签推送到远程仓库

**验证命令**：
```bash
git tag -l | grep "v1.0.2"  # 应显示 v1.0.2
git log --oneline | head -3  # 应显示最近的提交
```

### 12. 最终完整性检查
- [ ] 运行完整的冒烟测试（如已配置）：
  ```bash
  python tools/adapter_generator.py --validate
  ```
  应返回：`✅ 所有检查通过`
- [ ] 本地项目构建/测试无错误（如适用）
- [ ] 文档已同步到主分支（README.md、POWER.md 等）

---

## 手动自定义项

此部分用于记录任何特定于适配器的自定义或特殊说明。

**当前状态**：暂无自定义项

---

## 发布历史

### v1.0.2 (2024-06-09)
**标签**：`v1.0.2`  
**主要改进**：
- STEERING.md 优化：新增工作空间规则文件支持
- 认知蒸馏增强：改进 EVOLUTION_PROPOSALS.md 提议机制
- 所有 9 个 IDE 适配器版本对齐
- 模板引擎性能优化

**发布检查清单**：✅ 全部通过  
**贡献者**：ProjectOrchestrator 团队  
**依赖项**：Python 3.8+, Jinja2 3.0+

---

### v1.0.1 (2024-04-15)
**标签**：`v1.0.1`  
**主要改进**：
- 添加基于时间戳的智能加载机制
- 优化 NEXT.md 硬门限机制
- 改进触发关键词识别

**发布检查清单**：✅ 全部通过  
**贡献者**：ProjectOrchestrator 团队

---

### v1.0.0 (2024-02-28)
**标签**：`v1.0.0`  
**内容**：
- 双轨认知模式（执行轨道 + 进化轨道）
- 七步执行引擎（初始化 → 审计 → 规划 → 实现 → 验证 → 收口 → 进化）
- 9 个 IDE 适配器（Cursor、Cline、Windsurf、Claude Code、Gemini、Antigravity、Kiro 等）
- 10 个 .ai/ 模板文件（Full Mode）和 5 个文件（Lite Mode）
- 项目编排工作流和约束机制

**发布检查清单**：✅ 全部通过  
**贡献者**：ProjectOrchestrator 创始团队

---

## 版本升级指南

### 从 v1.0.1 升级到 v1.0

**自动升级**（推荐）：
```bash
python tools/adapter_generator.py --version 1.0 --apply
```

**手动升级**：
1. 更新 `skill.md` 中的版本号为 `v1.0`
2. 运行 `python tools/adapter_generator.py --version 1.0`
3. 验证所有 9 个适配器文件已更新
4. 提交更改并创建标签

**向后兼容性**：✅ 完全兼容，无需迁移现有项目

---

## 联系与支持

- **项目主页**：https://github.com/ProjectOrchestrator
- **问题追踪**：GitHub Issues
- **讨论**：GitHub Discussions
- **文档**：README.md, README_CN.md

---

**文件维护**：自动生成版本 + 手动审查  
**最后更新**：2026-07-04  
**下一次计划更新**：v1.0.3（待定）
