# ProjectOrchestrator Adapter 维护指南

## 1. 概览

本指南说明如何维护、更新和发布ProjectOrchestrator Adapter v1.0.2及后续版本。

### 核心原则

- **单一源**: `skill.md` 是所有适配器的权威源
- **版本统一**: 所有9个适配器必须保持相同的版本号
- **自动化优先**: 使用 `adapter-generator.py` 自动生成而不是手动编辑
- **验证强制**: 所有更改必须通过多层验证系统

---

## 2. 版本编号方案

### 格式

遵循语义化版本 (Semantic Versioning)：`MAJOR.MINOR.PATCH`

**示例**：
- `v1.0.0` - 初始发布
- `v1.0.1` - 补丁（bug修复）
- `v1.1.0` - 次版本（新功能，向后兼容）
- `v2.0.0` - 主版本（破坏性变更）

### 何时更新版本

- **PATCH**: 修复bug、性能优化、错别字修正
- **MINOR**: 新增功能、新增模式、改进规则（向后兼容）
- **MAJOR**: 架构变更、破坏性变更、重新设计

### 版本号位置

所有9个适配器文件的第一行标题中必须包含版本号：

```markdown
# {ADAPTER_NAME} — ProjectOrchestrator Skill v1.0.2
```

---

## 3. 发布工作流（逐步）

### 第一步：更新 skill.md

1. 在 `skill.md` 顶部更新版本号
2. 在版本变更部分记录所有改进和修复
3. 提交本地更改（暂不推送）

```bash
# 在 skill.md 中修改版本
# # ProjectOrchestrator Skill v1.0.3

git add skill.md
git commit -m "docs: update skill.md to v1.0.3"
```

### 第二步：运行适配器生成器

使用 `adapter-generator.py` 自动生成所有适配器：

```bash
# 进入项目根目录
cd d:\Users\Administrator\Documents\Projects\selfskill

# 生成所有适配器（版本号自动更新）
python tools/adapter_generator.py --version 1.0.3 --validate

# 或使用干运行模式（预览不保存）
python tools/adapter_generator.py --version 1.0.3 --dry-run
```

### 第三步：验证生成的输出

```bash
# 检查所有适配器文件的版本号一致性
for file in adapters/*.md adapters/cursorrules adapters/*.mdc; do
  echo "=== $file ==="
  grep -n "v1.0.3" "$file" || echo "未找到版本号"
done

# 验证文件引用正确
grep -l "requirements.md" adapters/* | wc -l  # 应显示 9 或更多

# 验证无PRD.md引用
grep -r "PRD\.md" adapters/ | wc -l  # 应显示 0
```

### 第四步：运行测试套件

```bash
# 运行所有测试
pytest tests/ -v --cov=tools --cov-report=html

# 或运行特定测试
pytest tests/test_validators.py -v

# 检查测试覆盖率
coverage report
```

### 第五步：提交和推送

```bash
# 暂存所有更改
git add adapters/ .ai/SKILL_VERSION.md skill.md

# 提交变更
git commit -m "chore: sync adapters to v1.0.3

- Update skill.md to v1.0.3
- Regenerate all 9 adapters
- Update version tracking in .ai/SKILL_VERSION.md
- All tests pass, validation successful"

# 推送到远程（如果使用远程仓库）
git push origin main
```

### 第六步：创建发布标签

```bash
# 创建带注释的标签
git tag -a v1.0.3 -m "Release v1.0.3: [发布说明]"

# 推送标签到远程
git push origin v1.0.3

# 验证标签
git tag -l | grep v1.0.3
```

### 第七步：更新版本追踪文件

编辑 `.ai/SKILL_VERSION.md`，在"发布历史"部分添加新版本条目：

```markdown
### v1.0.3 (2024-12-XX)
**标签**：`v1.0.3`  
**主要改进**：
- [改进1]
- [改进2]

**发布检查清单**：✅ 全部通过  
**贡献者**：ProjectOrchestrator 团队
```

---

## 4. 运行适配器生成器（CLI示例）

### 基本用法

```bash
# 生成所有9个适配器，版本号为1.0.3，并验证
python tools/adapter_generator.py --version 1.0.3 --validate

# 生成特定平台的适配器
python tools/adapter_generator.py --platforms kiro,cursor,claude --version 1.0.3

# 干运行模式（预览但不保存）
python tools/adapter_generator.py --version 1.0.3 --dry-run

# 仅验证（不生成）
python tools/adapter_generator.py --validate
```

### 高级选项

```bash
# 指定输出目录
python tools/adapter_generator.py --output-dir ./custom_output/

# 使用配置文件
python tools/adapter_generator.py --config ./generator.yml

# 生成并报告性能统计
python tools/adapter_generator.py --stats

# 详细日志输出
python tools/adapter_generator.py --verbose --version 1.0.3
```

### 配置文件示例 (generator.yml)

```yaml
version: "1.0.3"
input_file: "skill.md"
output_dir: "adapters/"
platforms:
  - kiro
  - cursor
  - claude
  - antigravity
  - cline
  - windsurf
  - gemini
  - agents
  - cursorrules
validate: true
dry_run: false
```

---

## 5. 测试流程

### 单元测试

```bash
# 运行所有单元测试
pytest tests/unit/ -v

# 运行特定模块的测试
pytest tests/unit/test_skill_parser.py -v
pytest tests/unit/test_template_engine.py -v
pytest tests/unit/test_validators.py -v
```

### 集成测试

```bash
# 运行生成器集成测试
pytest tests/integration/test_adapter_generator.py -v

# 测试生成的适配器质量
pytest tests/integration/test_adapter_quality.py -v
```

### 测试覆盖率

```bash
# 生成覆盖率报告
pytest --cov=tools --cov-report=html

# 查看覆盖率
open htmlcov/index.html  # macOS
start htmlcov/index.html  # Windows
```

---

## 6. 冲突解决（手动 vs 生成编辑）

### 场景1：用户手动修改了适配器文件

**问题**：用户修改了 `adapters/CLAUDE.md`，但生成器会覆盖该修改。

**解决方案**：

1. **识别手动修改**：
   ```bash
   git diff adapters/CLAUDE.md
   ```

2. **保存手动修改**：
   ```bash
   cp adapters/CLAUDE.md adapters/CLAUDE.md.backup
   ```

3. **重新生成适配器**：
   ```bash
   python tools/adapter_generator.py --validate
   ```

4. **合并更改**：
   - 使用 merge tool 合并 `CLAUDE.md.backup` 和新生成的 `CLAUDE.md`
   - 或手动复制你想要的更改到新文件

5. **验证合并结果**：
   ```bash
   pytest tests/ -v
   ```

### 场景2：需要平台特定的自定义

**问题**：某个IDE需要特定的自定义规则。

**解决方案**：

1. **创建自定义模板**：在 `tools/templates/adapter/platforms/` 中创建或编辑平台特定模板

2. **记录自定义**：在 `.ai/SKILL_VERSION.md` 的"手动自定义项"部分记录：
   ```markdown
   ## 手动自定义项

   ### Cursor IDE 特定规则
   - 自定义规则1：[描述]
   - 自定义规则2：[描述]
   - 维护者：[名字]
   - 最后更新：[日期]
   ```

3. **在适配器中标记自定义**：
   ```markdown
   <!-- 自定义: Cursor IDE 特定规则 (维护者: [名字]) -->
   ```

4. **每次生成时手动应用自定义**：
   ```bash
   # 生成适配器
   python tools/adapter_generator.py --validate
   
   # 应用平台特定自定义
   # [手动编辑 adapters/cursor.mdc]
   ```

---

## 7. 回滚指南

### 回滚到上一个版本

```bash
# 查看历史版本标签
git tag -l | sort -V

# 切出上一个版本的分支
git checkout v1.0.1

# 复制适配器文件到本地
cp adapters/* ./adapters_v1.0.1/

# 切回主分支
git checkout main
```

### 部分回滚（仅特定适配器）

```bash
# 恢复单个适配器到特定提交
git checkout abc123def -- adapters/CLAUDE.md

# 或从标签恢复
git checkout v1.0.1 -- adapters/CLAUDE.md

# 验证恢复
git diff adapters/CLAUDE.md
```

### 完全回滚（恢复整个版本）

```bash
# 创建回滚提交（推荐做法）
git revert abc123def

# 或强制重置（仅在本地）
git reset --hard v1.0.1
```

---

## 8. 故障排除（常见问题）

### Q1：生成器报错 "skill.md 格式不正确"

**A**：检查 `skill.md` 的语法和结构：
```bash
python tools/skill_parser.py --validate skill.md
```

### Q2：某个适配器文件生成失败

**A**：检查模板和上下文：
```bash
python tools/adapter_generator.py --platforms claude --verbose
```

### Q3：版本号在生成后不匹配

**A**：确认使用了正确的版本号参数：
```bash
python tools/adapter_generator.py --version 1.0.3 --validate
```

### Q4：Pre-commit hook 阻止了提交

**A**：检查hook的验证结果，修复问题后重试：
```bash
# 查看hook输出
cat .git/hooks/pre-commit

# 修复后重新提交
git commit -m "..."
```

### Q5：测试覆盖率低于80%

**A**：添加缺失的测试用例：
```bash
pytest --cov=tools tests/ --cov-report=term-missing
# 查看哪些行未被覆盖，添加测试
```

---

## 9. FAQ

**Q：多久更新一次适配器？**  
A：建议每次 `skill.md` 更新时都运行生成器重新生成适配器，保持同步。

**Q：可以手动编辑生成的适配器吗？**  
A：不建议。应该修改模板或 `skill.md`，然后重新生成。手动编辑可能在下次生成时被覆盖。

**Q：如何处理多语言版本？**  
A：目前适配器为英文版本。多语言支持可在 `.ai/i18n/` 下创建翻译版本，但推荐维护单一英文版本作为主版本。

**Q：版本 v1.0.2 和 v1.0.2-beta 有什么区别？**  
A：`v1.0.2` 是稳定版本，建议用于生产。`v1.0.2-beta` 是测试版本，仅用于测试新功能。

**Q：如何贡献新的IDE适配器？**  
A：
1. 在 `tools/templates/adapter/platforms/` 创建新平台的模板
2. 更新 `adapter_generator.py` 的平台列表
3. 运行生成器验证
4. 提交Pull Request

---

## 联系与支持

- 🐛 **报告问题**：[GitHub Issues]
- 💬 **讨论**：[GitHub Discussions]
- 📖 **文档**：[README.md](./README.md)
- 🔧 **工具**：[tools/README.md](./tools/README.md)

---

**文档版本**：1.0  
**最后更新**：2024-12  
**维护者**：ProjectOrchestrator 团队
