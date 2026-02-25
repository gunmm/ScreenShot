# Design: 落地 OpenSpec 工作流

## 现状（As-is）

- 规格文档仅有根目录 `OPENSPEC.md`（单文件），后续变更没有固定的提案/任务/归档结构。
- 容易出现“改了代码但没改文档”或“文档多份不一致”。

## 方案（To-be）

- 引入 `openspec/` 工作区：
  - `openspec/specs/`：主规格（已实现系统真相来源）
  - `openspec/changes/`：每次变更的工作目录（proposal/specs/design/tasks）
  - `openspec/archive/`：归档完成的变更目录
  - `openspec/schemas/`：预留自定义 schema（可选）
- 在根目录新增 `AGENTS.md`，对 AI/协作者强制“先文档后代码”的工作约束。
- 根目录保留 `OPENSPEC.md` 作为**入口索引**，正文迁移到 `openspec/specs/`，避免重复。

## 数据/文件迁移

- 将原 `OPENSPEC.md` 的正文迁移到 `openspec/specs/long-screenshot.md`
- 根目录 `OPENSPEC.md` 改为索引（指向 `openspec/specs/` 与 `openspec/README.md`）

## 回滚策略

- 如果团队不再使用 OpenSpec，可删除 `openspec/` 目录并恢复根目录单文档（需要从 `openspec/specs/` 回拷正文）。

