# 唯一活跃任务闸门 (NEXT)

> [!IMPORTANT]
> 根据 ProjectOrchestrator 铁律，AI 绝对禁止超出本文件标注的范围编写任何业务代码。
> 严禁在此处堆叠多个任务。只有当本任务完成并收口后，方可在此处设置下一个任务。

> ⚠️ **模板占位符**: 本文件为初始化模板。Mode 0 初始化时，AI 将从 TASKS.md 提取第一个未完成任务 `[ ]` 并填充本文件。

## 📌 当前活跃任务 (Single Active Task)
* **Task ID**: {待 Mode 0 初始化时从 TASKS.md 提取}
* **任务标题**: {待提取任务名称}
* **所属阶段**: {待提取所属阶段}
* **状态**: IN_PROGRESS

## 🔗 前序依赖检查 (DAG Pre-requisites)
* **前置依赖**: 无 / [{待检查的前置任务 ID}]
* **依赖状态**: [x] 前置任务均已完成结项

## 📝 冻结开工契约 (Frozen Contract - Mode 2 确认后锁定)
* **涉及文件**:
  - 需检查: {待 Mode 2 填入}
  - 预计修改: {待 Mode 2 填入}
* **JIT 分级验收断言 (Exit Criteria)**:
  1. [Tier 1 静态检查]: {待 Mode 2 填入}
  2. [Tier 2 自动化测试]: {待 Mode 2 填入测试命令，要求 Exit Code 0}
  3. [Tier 3 冒烟验证]: {待 Mode 2 填入}
* **首个交付物**: {待 Mode 2 填入}
* **回滚预案**: {待 Mode 2 填入}

## 🚦 状态流转记录
- [ ] Mode 1: 上下文与依赖审计通过
- [ ] Mode 2: 开工契约卡片已确认 (断言已冻结)
- [ ] Mode 3: 编码完成 (Hard Stop 已挂起)
- [ ] Mode 4: 自动化测试通过 (真实 Exit Code 0)
- [ ] Mode 5: Git 物理结项与审计归档
