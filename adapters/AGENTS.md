<!-- Generic Agent adapter (OpenAI Codex, GitHub Copilot Workspace, etc.) | Install: AGENTS.md (project root) -->

# ProjectOrchestrator 调度引擎

本项目使用 **ProjectOrchestrator** 敏捷调度引擎管理开发流程。执行任务规划与交付时，请优先读取并遵循 `.ai/MODE_REFERENCE.md` 中的 7-Mode 引擎规则。

**触发词**: "继续项目"、"启动项目"、"初始化"、"开始阶段"、"规划任务"、"运行测试"、"测试通过"、"收口"、"优化规则"

**执行流程**:
1. 读取 `.ai/MODE_REFERENCE.md` 获取完整的 7-Mode 执行引擎规则和输出模板
2. 读取 `.ai/STATUS.md` 和 `.ai/NEXT.md` 获取当前项目状态
3. 按 Mode 0→1→2→3→4→5 顺序执行，不可跳过

**核心原则**: 所有项目状态以 `.ai/` 目录文件为唯一真相源 (SSOT)，禁止基于对话记忆开发。

**Version**: 1.1 | **Generated**: 2026-08-21T04:14:07.572584Z | Auto-generated from skill.md
