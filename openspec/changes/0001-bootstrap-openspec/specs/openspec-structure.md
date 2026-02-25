# Specs: OpenSpec 工作流约束

## 约束

- 任何改动必须先在 `openspec/changes/<change>/` 产出：
  - `proposal.md`
  - `specs/`（需求增量）
  - `design.md`
  - `tasks.md`
- 实现完成后必须同步主规格到 `openspec/specs/`
- 变更完成后必须归档到 `openspec/archive/`

## 验收

- 仓库存在 `openspec/specs/`（主规格）与 `openspec/changes/_template/`
- 根目录 `AGENTS.md` 存在且可读
- 根目录 `OPENSPEC.md` 仅作为入口索引，不再包含重复正文

