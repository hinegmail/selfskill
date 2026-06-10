# ProjectOrchestrator Adapter Generator Tools

Python工具包，用于自动生成和维护ProjectOrchestrator Skill适配器文件。

## 功能概览

- **SkillParser** - 从 `skill.md` 提取结构化内容
- **TemplateEngine** - 使用Jinja2渲染适配器模板
- **AdapterGenerator** - CLI工具，自动生成所有IDE适配器
- **Validators** - 多层验证系统（Markdown、版本、引用、语言等）
- **Utils** - 文件I/O、YAML处理、目录管理工具函数

## 安装

### 前置条件

- Python 3.8+
- pip 包管理器

### 步骤

```bash
# 1. 进入项目根目录
cd /path/to/selfskill

# 2. 安装依赖
pip install -r tools/requirements.txt

# 3. 验证安装
python tools/adapter_generator.py --help
```

## 快速开始

### 基本用法

```bash
# 生成所有9个适配器
python tools/adapter_generator.py --version 1.0.2 --validate

# 生成特定平台的适配器
python tools/adapter_generator.py --platforms kiro,cursor --version 1.0.2

# 干运行模式（预览不保存）
python tools/adapter_generator.py --dry-run --version 1.0.2
```

### 验证现有适配器

```bash
# 验证所有适配器的质量
python tools/adapter_generator.py --validate

# 详细的验证输出
python tools/adapter_generator.py --validate --verbose
```

## 模块详解

### 1. SkillParser

**功能**：从 `skill.md` 提取结构化内容

**使用示例**：

```python
from tools.skill_parser import SkillParser

parser = SkillParser("skill.md")

# 提取版本号
version = parser.extract_version()
print(f"Skill version: {version}")

# 提取核心原则
principles = parser.extract_section("Core Principles")

# 提取七步模式定义
modes = parser.extract_modes()

# 提取触发关键词
keywords = parser.extract_keywords()

# 提取禁止行为
forbidden = parser.extract_forbidden_behaviors()
```

### 2. TemplateEngine

**功能**：使用Jinja2渲染适配器模板

**使用示例**：

```python
from tools.template_engine import TemplateEngine

engine = TemplateEngine("tools/templates/adapter/")

# 加载模板
template = engine.load("platforms/kiro.md.j2")

# 准备上下文数据
context = {
    "version": "1.0.2",
    "principles": [...],
    "modes": [...],
    "keywords": [...]
}

# 渲染模板
output = engine.render(template, context)
print(output)
```

### 3. AdapterGenerator

**功能**：主编排工具，协调生成过程

**使用示例**：

```python
from tools.adapter_generator import AdapterGenerator

# 创建生成器实例
generator = AdapterGenerator(
    input_file="skill.md",
    output_dir="adapters/",
    version="1.0.2"
)

# 生成所有适配器
result = generator.generate()

if result.success:
    print(f"生成成功！输出文件：{result.generated_files}")
else:
    print(f"生成失败：{result.errors}")

# 或者验证现有适配器
is_valid = generator.validate()
print(f"验证结果：{is_valid}")
```

### 4. Validators

**功能**：多层验证系统

**使用示例**：

```python
from tools.validators import (
    MarkdownValidator,
    VersionValidator,
    FileReferenceValidator,
    LanguageValidator
)

# Markdown验证
md_validator = MarkdownValidator()
is_valid_md = md_validator.validate("adapters/CLAUDE.md")

# 版本验证
version_validator = VersionValidator()
version_issues = version_validator.check_consistency("adapters/")

# 文件引用验证
ref_validator = FileReferenceValidator()
has_prd_refs = ref_validator.check_prd_references("adapters/")

# 语言验证
lang_validator = LanguageValidator()
has_chinese_code = lang_validator.check_chinese_code("adapters/")

if not (is_valid_md and not version_issues and not has_prd_refs and not has_chinese_code):
    print("❌ 验证失败")
else:
    print("✅ 所有验证通过")
```

### 5. Utils

**功能**：辅助工具函数

**使用示例**：

```python
from tools import utils

# 读取文件
content = utils.read_file("skill.md")

# 写入文件
utils.write_file("output.md", content)

# 读取YAML配置
config = utils.read_yaml("generator.yml")

# 写入YAML
utils.write_yaml("config.yml", {"version": "1.0.2"})

# 目录操作
utils.ensure_dir("output_dir/")

# 递归搜索文件
md_files = utils.find_files("adapters/", "*.md")
```

## CLI 命令参考

### 主命令：adapter-generator.py

```bash
python tools/adapter_generator.py [OPTIONS]
```

### 可用选项

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--version` | string | 1.0.2 | 目标版本号 |
| `--input-file` | path | skill.md | 输入的skill.md文件路径 |
| `--output-dir` | path | adapters/ | 输出适配器文件的目录 |
| `--platforms` | string | all | 生成的平台（逗号分隔，或"all"表示全部） |
| `--config` | path | - | 配置文件路径（YAML格式） |
| `--validate` | flag | false | 仅验证，不生成 |
| `--dry-run` | flag | false | 干运行模式（预览但不保存） |
| `--verbose` | flag | false | 详细输出 |
| `--stats` | flag | false | 显示性能统计信息 |

### 示例

```bash
# 生成所有适配器到v1.0.3
python tools/adapter_generator.py --version 1.0.3 --validate

# 生成特定平台
python tools/adapter_generator.py --platforms kiro,cursor,claude --version 1.0.3

# 干运行模式（预览）
python tools/adapter_generator.py --dry-run --version 1.0.3

# 仅验证
python tools/adapter_generator.py --validate

# 使用配置文件
python tools/adapter_generator.py --config generator.yml

# 详细输出和性能统计
python tools/adapter_generator.py --verbose --stats --version 1.0.3
```

## 测试

### 运行测试

```bash
# 运行所有测试
pytest tests/ -v

# 运行特定模块的测试
pytest tests/unit/test_skill_parser.py -v

# 生成覆盖率报告
pytest --cov=tools --cov-report=html
```

### 测试结构

```
tests/
├── unit/
│   ├── test_skill_parser.py
│   ├── test_template_engine.py
│   ├── test_validators.py
│   └── test_utils.py
├── integration/
│   ├── test_adapter_generator.py
│   └── test_end_to_end.py
└── fixtures/
    ├── sample_skill.md
    └── sample_config.yml
```

## 配置文件

### generator.yml 示例

```yaml
# 适配器生成器配置文件

# 版本号
version: "1.0.2"

# 输入文件
input_file: "skill.md"

# 输出目录
output_dir: "adapters/"

# 生成的平台列表
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

# 是否验证
validate: true

# 是否干运行
dry_run: false

# 模板目录
template_dir: "tools/templates/adapter/"

# 详细输出
verbose: false
```

## 扩展指南

### 添加新平台

1. **创建平台模板**：
   ```
   tools/templates/adapter/platforms/{platform}.md.j2
   ```

2. **更新配置**：
   在 `generator.yml` 的 `platforms` 列表中添加新平台名称

3. **更新生成器**：
   在 `adapter_generator.py` 中的平台列表中注册新平台

4. **运行生成**：
   ```bash
   python tools/adapter_generator.py --platforms {platform} --validate
   ```

### 自定义模板

1. **编辑模板文件**：
   ```
   tools/templates/adapter/base.j2
   tools/templates/adapter/modes.j2
   tools/templates/adapter/platforms/{platform}.md.j2
   ```

2. **使用Jinja2语法**：
   ```jinja2
   {{ version }}
   {% for mode in modes %}
     # {{ mode.name }}
   {% endfor %}
   ```

3. **测试新模板**：
   ```bash
   python tools/adapter_generator.py --dry-run --validate
   ```

### 添加新验证器

1. **创建验证器类**：
   ```python
   # tools/validators.py
   class CustomValidator:
       def validate(self, file_path):
           # 实现验证逻辑
           return is_valid
   ```

2. **集成到生成器**：
   更新 `adapter_generator.py` 的验证流程

3. **测试验证器**：
   ```bash
   pytest tests/unit/test_validators.py -v
   ```

## 常见问题

**Q：如何更新到新版本？**  
A：更新 `requirements.txt`，然后运行 `pip install -r tools/requirements.txt --upgrade`

**Q：生成失败怎么办？**  
A：使用 `--verbose` 查看详细错误信息，检查 `skill.md` 格式是否正确

**Q：可以并行生成多个平台吗？**  
A：生成器已支持并行处理，自动使用多核优化性能

**Q：如何调试模板问题？**  
A：使用 `--dry-run` 模式预览输出，检查上下文数据

## 性能指标

- **解析时间**：< 1秒 (skill.md)
- **渲染时间**：< 5秒 (所有9个适配器)
- **验证时间**：< 3秒 (所有验证器)
- **总耗时**：< 10秒 (端到端)

## 依赖项

- `Jinja2 >= 3.0.0` - 模板引擎
- `Click >= 8.0.0` - CLI框架
- `PyYAML >= 6.0` - YAML处理
- `pytest >= 7.0.0` - 测试框架
- `pytest-cov >= 2.0.0` - 覆盖率

## 许可证

MIT License

## 联系与支持

- 📖 [完整维护指南](../ADAPTER_MAINTENANCE.md)
- 🐛 [报告问题](https://github.com/projectorchestrator/issues)
- 💬 [讨论](https://github.com/projectorchestrator/discussions)

---

**文档版本**：1.0  
**最后更新**：2024-12  
**维护者**：ProjectOrchestrator 团队
