# `.ai/` Directory — ProjectOrchestrator Runtime Data

> **This is not AI-generated cache. This is your project's Single Source of Truth (SSOT).**

## What is this directory?

`.ai/` contains the **runtime state files** for the ProjectOrchestrator development workflow.
All project knowledge — requirements, design, tasks, status, and lessons — lives here, not in chat history.

## File Overview

| File | Purpose | Updated When |
|------|---------|---------------|
| `MODE_REFERENCE.md` | Full 7-Mode engine rules & output templates (Skill definition) | Skill upgrade |
| `STATUS.md` | Current project state + audit trail | Every session |
| `NEXT.md` | The single active task (execution gate) | Task switch |
| `STEERING.md` | Project navigation hub: mission, architecture, milestones | Architecture change |
| `TASKS.md` | Complete task list with dependencies & acceptance criteria | Task planning |
| `requirements.md` | Product requirements | Requirements change |
| `DESIGN.md` | Technical design document | Design change |
| `RULES.md` | Project-specific AI behavior rules & coding conventions | Rule evolution |
| `TEST_LOG.md` | Test execution records: commands, results, root causes | Mode 4 (Validation) |
| `LESSONS.md` | Project-level lessons learned | Mode 5 (Closeout) |
| `DECISIONS.md` | Architecture Decision Records (ADR format) | Major decisions |
| `EVOLUTION_PROPOSALS.md` | Proposed improvements to rules/design/Skill | Mode 6 (Evolution) |

## How to use

1. **Start a conversation**: say `继续项目` (continue) or `启动项目` (new project)
2. The AI will read `.ai/STATUS.md` and `.ai/NEXT.md` to recover project state
3. Follow the 7-Mode execution engine: Mode 0 (Init) → Mode 1 (Audit) → Mode 2 (Plan) → Mode 3 (Code) → Mode 4 (Test) → Mode 5 (Closeout)

## Important

- **Do NOT delete** this directory — it contains your project's entire development history
- **Do NOT manually edit** `MODE_REFERENCE.md` — it is auto-generated from `skill.md`
- **Git commit** after each Mode 5 (Phase Closeout) to preserve state
- For full rules, read `MODE_REFERENCE.md`

---

*Powered by ProjectOrchestrator Skill — File-based memory, not chat-based memory.*
