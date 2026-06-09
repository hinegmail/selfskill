# ProjectOrchestrator Adapter 版本同步 - 技术设计文档

## 1. 设计概览

### 1.1 架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        真相之源层                                 │
├─────────────────────────────────────────────────────────────────┤
│  skill.md (v1.0.2) ← 单一权威版本                                 │
│  ├── 核心原则                                                     │
│  ├── 七步执行引擎                                                 │
│  ├── 禁止行为                                                     │
│  └── 触发关键词                                                   │
└────────────┬─────────────────────────────────────────────────────┘
             │
             │ (自动化生成)
             ▼
┌─────────────────────────────────────────────────────────────────┐
│            同步层 (adapter-generator.py)                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │  skill.md   │  │   模板       │  │  配置.yml    │            │
│  │  解析器      │  │ (Jinja2)    │  │              │            │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │
│         │                 │                │                    │
│         └─────────────────┴─────────────────┘                    │
│                      │                                           │
│         ┌────────────▼────────────┐                              │
│         │   适配器生成器          │                              │
│         │ - 提取章节             │                              │
│         │ - 应用模板             │                              │
│         │ - 注入平台信息         │                              │
│         └────────────┬────────────┘                              │
└────────────┬─────────────────────────────────────────────────────┘
             │
             │ (生成的输出)
             ▼
┌─────────────────────────────────────────────────────────────────┐
│               输出层 (适配器文件)                                 │
├─────────────────────────────────────────────────────────────────┤
│  KIRO_AGENT.md  │  ANTIGRAVITY.md  │  cursor.mdc               │
│  clinerules.md  │  CLAUDE.md        │  windsurfrules.md        │
│  gemini_styleguide.md  │  AGENTS.md                             │
└─────────────────────────────────────────────────────────────────┘
             │
             │ (版本验证)
             ▼
┌─────────────────────────────────────────────────────────────────┐
│          验证与自动化层                                          │
├─────────────────────────────────────────────────────────────────┤
│  GitHub Actions                    Pre-commit Hook              │
│  (CI/CD 验证)                      (本地验证)                     │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 主要组件

| 组件 | 功能 | 输入 | 输出 |
|------|------|------|------|
| **SkillParser** | 从 skill.md 提取结构化内容 | skill.md 文件 | 结构化数据 |
| **TemplateEngine** | Jinja2 模板渲染 | 模板 + 上下文 | 渲染的文本 |
| **AdapterGenerator** | 主编排工具 | skill.md + 配置 | 9 个适配器文件 |
| **VersionManager** | 集中版本追踪 | 发布信息 | .ai/SKILL_VERSION.md |
| **CI/CD 验证** | GitHub Actions | PR + 修改文件 | 通过/失败决策 |
| **Pre-commit Hook** | 本地 Git 验证 | 分阶段文件 | 通过/拦截 |

---

## 2. 实现细节

### 2.1 SkillParser 组件

**目的**：从 `skill.md` 中提取结构化内容

**关键方法**：
```python
class SkillParser:
    def extract_version(self) -> str
        # 解析版本号，如 "1.0.2"
    
    def extract_section(self, section_name: str) -> str
        # 提取特定章节的 markdown
    
    def extract_modes(self) -> Dict[str, str]
        # 提取所有模式 0-6 定义
    
    def extract_keywords(self) -> Dict
        # 提取触发关键词表
```

### 2.2 TemplateEngine 组件

**目的**：使用 Jinja2 模板生成适配器文件

**模板结构**：
```
templates/adapter/
├── base.md.j2              # 通用页眉、核心原则
├── modes.md.j2             # 七步模式定义
├── rules.md.j2             # 禁止行为、触发词
├── footer.md.j2            # EVOLUTION_LOG、版本信息
└── platforms/
    ├── kiro.md.j2          # KIRO_AGENT.md 特定
    ├── antigravity.md.j2   # ANTIGRAVITY.md 特定
    ├── cursor.mdc.j2       # cursor.mdc 特定
    └── ...其他平台
```

### 2.3 AdapterGenerator 主编排器

**目的**：协调解析、模板化和输出

**CLI 接口**：
```bash
# 生成所有适配器
python tools/adapter-generator.py \
    --input skill.md \
    --output-dir adapters/ \
    --version 1.0.2 \
    --language zh-CN

# 生成特定适配器
python tools/adapter-generator.py \
    --platforms kiro,cursor,claude \
    --validate

# 干运行（预览）
python tools/adapter-generator.py --dry-run
```

### 2.4 版本管理器 (.ai/SKILL_VERSION.md)

**内容**：
```markdown
# ProjectOrchestrator Skill 版本追踪

## 当前版本
- skill.md: v1.0.2
- 适配器: v1.0.2 (最后同步: 2024-06-09T10:30:00Z)
- 模板: v1.0.2

## 发布历史
- v1.0.2: 添加 STEERING.md 优化、认知蒸馏
- v1.0.1: 添加基于时间戳的智能加载
- v1.0.0: 初始发布

## 发布前必需的同步检查清单
- [ ] skill.md 版本凹凸到 v1.0.X
- [ ] 所有适配器更新到 v1.0.X
- [ ] templates/ai/* 更新引用 requirements.md
- [ ] GitHub Actions 工作流通过
- [ ] Pre-commit hooks 通过
- [ ] 所有适配器用各自 IDE 测试
- [ ] 发布说明添加到此文件
- [ ] Git tag 创建: v1.0.X

## 手动自定义项
如适配器有特定自定义，在此记录
```

### 2.5 CI/CD 验证工作流 (GitHub Actions)

**验证检查**：
1. 版本号一致性（skill.md 版本 = 所有适配器版本）
2. 文件名引用正确（requirements.md，不是 PRD.md）
3. 无中文代码注释在适配器中
4. 语法验证每种适配器格式
5. 触发关键词跨适配器一致

**失败时的错误消息**：
```
❌ 版本不匹配: skill.md (v1.0.2) > KIRO_AGENT.md (v1.0.1)
❌ 文件引用错误: 适配器包含 'PRD.md'（应为 'requirements.md'）
❌ 语言错误: 适配器包含中文代码注释
```

### 2.6 Pre-commit Hook

**脚本**：`.git/hooks/pre-commit`

**检查**：
- 版本号匹配（如果 skill.md 和适配器都被修改）
- 文件名一致
- 无明显语法错误

**允许绕过**：开发者可用 `git commit --no-verify`（不推荐）

---

## 3. 数据结构

### 3.1 Skill 数据结构

```python
@dataclass
class SkillData:
    version: str              # "1.0.2"
    core_principles: List[str]
    file_system: Dict[str, str]  # 文件名 -> 描述
    priority_system: List[str]
    modes: Dict[str, Mode]
    forbidden_behaviors: List[str]
    trigger_keywords: Dict
```

### 3.2 生成结果

```python
@dataclass
class GenerationResult:
    version: str
    generated_files: Dict[str, str]  # 平台 -> 文件路径
    generation_timestamp: str
    duration_seconds: float
    success: bool
    errors: List[str]
```

---

## 4. 性能目标

| 操作 | 目标 | 方法 |
|------|------|------|
| 解析 skill.md | < 1 秒 | 整个文件加载内存 |
| 渲染所有适配器 | < 5 秒 | 模板缓存、并行渲染 |
| 验证 | < 3 秒 | 并行文件检查 |
| 总端到端 | < 10 秒 | 优化 I/O |

---

## 5. 测试策略

### 5.1 单元测试

```python
def test_extract_version():
    parser = SkillParser("skill.md")
    assert parser.extract_version() == "1.0.2"

def test_render_template():
    engine = TemplateEngine("tools/templates/adapter/")
    template = engine.load("platforms/kiro.md.j2")
    output = template.render({"version": "1.0.2"})
    assert "v1.0.2" in output
```

### 5.2 集成测试

```python
def test_end_to_end_generation():
    config = Config(input="skill.md", output_dir="test_output/")
    generator = AdapterGenerator(config)
    result = generator.generate()
    
    assert result.success
    assert len(result.generated_files) == 9
```

### 5.3 冒烟测试

```python
def test_adapter_syntax():
    for adapter_file in glob.glob("adapters/*"):
        content = read_file(adapter_file)
        assert len(content) > 1000  # 健全性检查
        assert "v1.0.2" in content  # 版本存在
        assert "requirements.md" in content  # 正确文件名
        assert "PRD.md" not in content  # 无旧文件名
```

---

## 6. 部署与发布

### 6.1 发布工作流

```
1. 开发者更新 skill.md
   ↓
2. 运行: python tools/adapter-generator.py --version X.Y.Z
   ↓
3. 提交: git add adapters/ .ai/SKILL_VERSION.md
   ↓
4. 推送: git push origin feature/adapter-sync
   ↓
5. GitHub Actions 验证
   ↓
6. 审查员批准 PR
   ↓
7. 合并到 main
   ↓
8. GitHub Actions 创建 tag: vX.Y.Z
   ↓
9. 自动生成发布说明
```

---

**文档版本**：1.0

**最后更新**：2024-06-09

**状态**：准备实施阶段
