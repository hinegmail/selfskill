# ProjectOrchestrator Adapter 版本同步 - 任务清单

## 项目概览

**功能**：ProjectOrchestrator Adapter 版本同步与自动化

**目标版本**：v1.0.2

**预计时长**：2 周（80 小时）

**团队规模**：1-2 名开发者 + 1 名审查者

---

## 任务阶段与依赖

```
第1阶段 (基础)
├── [任务 1] 文件重命名：PRD.md → requirements.md
├── [任务 2] 创建版本追踪文件 (.ai/SKILL_VERSION.md)
└── [任务 3] 设置项目结构 (tools/、.github/ 等)

第2阶段 (英文化)
├── [任务 4] 英文化 KIRO_AGENT.md
├── [任务 5] 英文化 ANTIGRAVITY.md
├── [任务 6] 英文化 CLAUDE.md
├── [任务 7] 英文化 cursor.mdc & cursor.rules
├── [任务 8] 英文化 clinerules.md & windsurfrules.md
└── [任务 9] 英文化 gemini_styleguide.md & AGENTS.md

第3阶段 (生成器实现)
├── [任务 10] 实现 SkillParser (skill-parser.py)
├── [任务 11] 实现 TemplateEngine (template-engine.py)
├── [任务 12] 实现 AdapterGenerator (adapter-generator.py)
├── [任务 13] 创建适配器模板 (Jinja2 模板)
└── [任务 14] 实现语法验证

第4阶段 (自动化 & CI/CD)
├── [任务 15] 创建 GitHub Actions 工作流
├── [任务 16] 创建 Pre-commit Hook
├── [任务 17] 设置本地测试环境
└── [任务 18] 端到端测试

第5阶段 (文档与发布)
├── [任务 19] 编写 ADAPTER_MAINTENANCE.md 指南
├── [任务 20] 创建 tools/ README
├── [任务 21] 更新 init.ps1 & init.sh 脚本
└── [任务 22] 创建发布说明与文档
```

---

## 任务详解

### 第 1 阶段：基础设置

#### [任务 1] 文件重命名：PRD.md → requirements.md

**任务 ID**：adapter-sync-001

**状态**：[ ] 未开始

**估计时间**：1.5 小时

**验收标准**：
- [-] `templates/ai/PRD.md` 重命名为 `templates/ai/requirements.md`
- [~] 所有文档中的 `PRD.md` 引用已更新
- [~] 搜索确认零 `PRD.md` 引用（除 git 历史外）
- [~] `init.ps1` 和 `init.sh` 更新引用 `requirements.md`
- [~] 所有适配器文件正确引用 `requirements.md`

**详细步骤**：
1. 执行：`git mv templates/ai/PRD.md templates/ai/requirements.md`
2. 更新 README.md 所有引用
3. 更新 init.ps1：`PRD.md` → `requirements.md`
4. 更新 init.sh：`PRD.md` → `requirements.md`
5. 运行：`grep -r "PRD\.md" .`（确认零结果）
6. 提交：`git commit -m "refactor: 重命名 PRD.md 为 requirements.md"`

---

#### [任务 2] 创建版本追踪文件 (.ai/SKILL_VERSION.md)

**任务 ID**：adapter-sync-002

**状态**：[ ] 未开始

**估计时间**：1 小时

**验收标准**：
- [~] `.ai/SKILL_VERSION.md` 创建，当前版本为 v1.0.2
- [~] 文件包含完整的发布说明
- [~] 同步检查清单清晰可执行
- [~] 手动自定义部分存在（现为空）

---

#### [任务 3] 设置项目结构 (tools/、.github/、.ai/i18n/)

**任务 ID**：adapter-sync-003

**状态**：[ ] 未开始

**估计时间**：1.5 小时

**验收标准**：
- [~] `tools/` 目录创建并含 Python 结构
- [~] `requirements.txt` 创建（依赖：Jinja2、Click 等）
- [~] `.github/workflows/` 目录创建
- [~] `.ai/i18n/` 目录创建且含 config.yml
- [~] 所有目录结构符合设计文档

---

### 第 2 阶段：适配器英文化

#### [任务 4] 英文化 KIRO_AGENT.md

**任务 ID**：adapter-sync-004

**状态**：[ ] 未开始

**估计时间**：2 小时

**验收标准**：
- [~] 所有中文注释和描述已翻译为英文
- [~] 文件 100% 英文（触发关键词表除外）
- [~] 版本更新为 v1.0.2
- [~] 所有文件引用已更改：`PRD.md` → `requirements.md`
- [~] 反映新功能：STEERING.md、认知蒸馏、设计偏离对齐

**详细步骤**：
1. 打开 `adapters/KIRO_AGENT.md`
2. 识别所有中文章节并翻译为英文
3. 更新文件引用（3 处 `PRD.md` 引用）
4. 添加"强制历史避坑查询"到模式 2
5. 添加"设计偏离对齐"部分到模式 5
6. 更新版本头：v1.0 → v1.0.2
7. 保留双语触发关键词表（用户方便）
8. 运行 linter 验证 UTF-8，无语法错误
9. 提交：`git add adapters/KIRO_AGENT.md`

---

#### [任务 5-9] 英文化其他适配器

**任务 ID**：adapter-sync-005 至 009

**状态**：[ ] 未开始

**估计时间**：每个 1.5-2 小时

**流程**：
- 任务 5：ANTIGRAVITY.md（全中文翻译）
- 任务 6：CLAUDE.md
- 任务 7：cursor.mdc & cursor.rules
- 任务 8：clinerules.md & windsurfrules.md
- 任务 9：gemini_styleguide.md & AGENTS.md

**所有任务共同验收标准**：
- [~] 内容 100% 英文
- [~] 版本更新至 v1.0.2
- [~] 文件引用正确
- [~] 新功能已反映
- [~] 无编码错误

---

### 第 3 阶段：生成器实现

#### [任务 10] 实现 SkillParser

**任务 ID**：adapter-sync-010

**状态**：[ ] 未开始

**估计时间**：4 小时

**验收标准**：
- [~] `SkillParser` 类含所有所需方法
- [~] 能从 skill.md 页眉提取版本
- [~] 能提取所有章节（核心原则、七步引擎等）
- [~] 能提取触发关键词表
- [~] 能提取禁止行为清单
- [~] 单元测试通过（100% 覆盖）
- [~] 优雅处理格式错误的 skill.md

---

#### [任务 11] 实现 TemplateEngine

**任务 ID**：adapter-sync-011

**状态**：[ ] 未开始

**估计时间**：3 小时

**验收标准**：
- [~] `TemplateEngine` 类实现 Jinja2 模板加载
- [~] 能用上下文变量渲染模板
- [~] 优雅处理缺失模板
- [~] 支持模板继承（如需）
- [~] 单元测试通过
- [~] 性能：< 1 秒所有渲染

---

#### [任务 12] 实现 AdapterGenerator

**任务 ID**：adapter-sync-012

**状态**：[ ] 未开始

**估计时间**：5 小时

**验收标准**：
- [~] `AdapterGenerator` 类实现主生成逻辑
- [~] CLI 接口支持所有选项
- [~] 能生成所有 9 个或特定平台的适配器
- [~] 错误处理处理无效输入/输出路径
- [~] `--validate` 标志工作
- [~] `--dry-run` 标志工作
- [~] 配置文件支持 (YAML)
- [~] 单元+集成测试通过

---

#### [任务 13] 创建适配器模板

**任务 ID**：adapter-sync-013

**状态**：[ ] 未开始

**估计时间**：6 小时

**验收标准**：
- [~] 所有基础模板创建（base、modes、rules、footer）
- [~] 所有平台特定模板创建（9 个）
- [~] 模板无错误渲染
- [~] 生成的输出匹配当前适配器结构
- [~] 覆盖：所有适配器可从模板生成

---

#### [任务 14] 实现语法验证

**任务 ID**：adapter-sync-014

**状态**：[ ] 未开始

**估计时间**：3 小时

**验收标准**：
- [~] Markdown 验证器实现
- [~] MDC 格式验证器实现
- [~] 版本验证（格式检查）
- [~] 文件引用验证（无 PRD.md）
- [~] 语言验证（无中文代码注释）
- [~] 所有验证器可从 CLI 调用
- [~] 每个验证器的单元测试

---

### 第 4 阶段：自动化 & CI/CD

#### [任务 15] 创建 GitHub Actions 工作流

**任务 ID**：adapter-sync-015

**状态**：[ ] 未开始

**估计时间**：3 小时

**验收标准**：
- [~] `.github/workflows/validate-adapter-versions.yml` 创建
- [~] 工作流在 PR 到 main 时触发
- [~] 所有验证检查实现
- [~] 工作流在 PR 上添加注释（明确错误信息）
- [~] 验证成功时工作流通过
- [~] 验证失败时工作流失败并阻止合并

**检查项**：
1. 提取 skill.md 版本
2. 检查适配器版本（必须匹配 skill.md）
3. 检查文件引用（无 PRD.md）
4. 检查中文代码注释
5. 各适配器格式语法验证

---

#### [任务 16] 创建 Pre-commit Hook

**任务 ID**：adapter-sync-016

**状态**：[ ] 未开始

**估计时间**：2 小时

**验收标准**：
- [~] `.git/hooks/pre-commit` 脚本创建
- [~] Hook 检查版本一致性
- [~] Hook 检查文件引用问题
- [~] Hook 检查语言问题
- [~] Hook 可执行 (chmod +x)
- [~] Hook 不阻止非适配器提交
- [~] 可用 `--no-verify` 绕过（有警告）
- [~] 文档说明 hook 安装

---

#### [任务 17] 设置本地测试环境

**任务 ID**：adapter-sync-017

**状态**：[ ] 未开始

**估计时间**：2 小时

**验收标准**：
- [~] Python 测试运行器配置 (pytest)
- [~] 所有单元测试通过
- [~] 所有集成测试通过
- [~] 测试覆盖 > 80%
- [~] 开发者可用单一命令运行测试
- [~] README.md 记录测试命令

---

#### [任务 18] 端到端测试

**任务 ID**：adapter-sync-018

**状态**：[ ] 未开始

**估计时间**：3 小时

**验收标准**：
- [~] 生成器成功生成全部 9 个适配器
- [~] 生成的适配器语法有效
- [~] 生成的适配器在各自 IDE 中正确加载
- [~] Pre-commit hook 在生成的适配器上通过
- [~] GitHub Actions 工作流在生成的适配器上通过
- [~] 无适配器功能回归
- [~] 性能满足目标（< 10 秒总计）

---

### 第 5 阶段：文档与发布

#### [任务 19] 编写 ADAPTER_MAINTENANCE.md 指南

**任务 ID**：adapter-sync-019

**状态**：[ ] 未开始

**估计时间**：4 小时

**内容章节**：
1. 概览
2. 版本编号方案
3. 发布工作流（逐步）
4. 运行适配器生成器（CLI 示例）
5. 测试流程
6. 冲突解决（手动 vs 生成编辑）
7. 回滚指南
8. 故障排除（常见问题）
9. FAQ

---

#### [任务 20-22] 其他文档

**任务 ID**：adapter-sync-020 至 022

- **任务 20**：创建 tools/README.md（安装、使用、扩展指南）
- **任务 21**：更新 init.ps1 & init.sh（requirements.md 引用）
- **任务 22**：创建发布说明与标签（v1.0.2）

---

## 任务依赖图

```
任务 1 (重命名 PRD.md)
  ↓
任务 2 (创建 SKILL_VERSION.md)
  ↓
任务 3 (设置项目结构)
  ├─→ 任务 4-9 (英文化适配器) [可并行]
       ↓
任务 10 (实现 SkillParser)
  ↓
任务 11 (实现 TemplateEngine)
  ↓
任务 12 (实现 AdapterGenerator)
  ↓
任务 13 (创建模板)
  ↓
任务 14 (实现验证器)
  ├─→ 任务 15 (GitHub Actions) [可并行]
  └─→ 任务 16 (Pre-commit Hook) [可并行]
       ↓
任务 17 (设置测试)
  ↓
任务 18 (端到端测试)
  ├─→ 任务 19-22 (文档) [可并行]
```

---

## 完成标准

### 第 1 阶段完成条件：
- [~] 所有文件引用指向 `requirements.md`
- [~] `.ai/SKILL_VERSION.md` 创建且含同步检查清单
- [~] 项目结构准备好（tools/、.github/、.ai/i18n/）

### 第 2 阶段完成条件：
- [~] 全部 9 个适配器翻译为英文
- [~] 版本在所有适配器中更新为 v1.0.2
- [~] 文件引用在所有适配器中正确
- [~] 新功能在所有适配器中反映

### 第 3 阶段完成条件：
- [~] SkillParser 功能完整（单元测试通过）
- [~] TemplateEngine 功能完整（单元测试通过）
- [~] AdapterGenerator 功能完整（CLI 工作）
- [~] 所有适配器模板创建并测试
- [~] 所有验证器实现并工作

### 第 4 阶段完成条件：
- [~] GitHub Actions 工作流创建并通过
- [~] Pre-commit hook 创建并测试
- [~] 本地测试环境完全设置
- [~] 端到端测试成功完成

### 第 5 阶段完成条件：
- [~] ADAPTER_MAINTENANCE.md 完成
- [~] tools/README.md 完成
- [~] init.ps1 和 init.sh 更新
- [~] 发布说明和标签创建

---

**文档版本**：1.0

**最后更新**：2024-06-09

**状态**：准备执行
