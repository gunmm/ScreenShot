# OpenSpec 工作区

本目录用于落地 OpenSpec（规范驱动开发 / SDD）流程。

## 目录结构

```
openspec/
  specs/     # 已实现系统的“真相来源”（长期维护、随实现同步）
  changes/   # 每次变更的工作目录（proposal/specs/design/tasks）
  archive/   # 已完成变更的归档（可追溯）
  schemas/   # （可选）自定义 schema/工作流
```

## 最小工作流（建议）

1. 在 `openspec/changes/` 新建一个变更目录（复制 `openspec/changes/_template/`）
2. 依次完善：
   - `proposal.md`：为什么要改、改什么、不改什么、验收标准、风险
   - `specs/`：需求/场景/边界/验收细化
   - `design.md`：技术方案与取舍
   - `tasks.md`：实现任务清单
3. 实现代码（只做 `tasks.md` 里列出的工作）
4. 同步回 `openspec/specs/`（更新主规格）
5. 把该变更目录移动到 `openspec/archive/`

> 根目录的 `AGENTS.md` 是对 AI/协作者的强制约束，请确保所有改动遵循该流程。

