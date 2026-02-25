# Proposal: 落地 OpenSpec 工作流

## 背景 / 动机

项目代码主要由 AI 生成，迭代时容易出现：

- 需求与实现不一致（跑偏）
- 同一功能多处描述、难以判断“真相”
- 变更缺少验收与回滚，导致回归难排查

因此需要把仓库落到 OpenSpec 的标准结构，用文档强约束后续改动流程。

## 目标（Goals）

- G1：建立 `openspec/` 目录结构（specs/changes/archive/schemas）
- G2：把“已实现系统规格”沉淀到 `openspec/specs/`
- G3：提供 `changes/_template`，让每次改动都能复用
- G4：提供根目录 `AGENTS.md`，强制 AI/协作者遵循流程

## 非目标（Non-goals）

- NG1：本次不改动任何截图/拼接算法逻辑（仅整理规范与流程）
- NG2：本次不引入外部 CLI 依赖（只落地目录与模板）

## 范围（Scope）

- **会改的部分**：
  - 新增 `AGENTS.md`
  - 新增 `openspec/` 工作区与模板
  - 迁移/去重根目录 `OPENSPEC.md` 的内容到 `openspec/specs/`
- **不会改的部分**：
  - iOS 工程与业务代码行为

## 验收标准（Acceptance Criteria）

- AC1：仓库存在 `openspec/specs/`（主规格）与 `openspec/changes/_template/`
- AC2：主规格中能找到 LongScreenShot 的端到端规格文档
- AC3：存在示例变更目录，可作为后续开变更的参考

## 风险与回滚

- **风险**：文档重复导致“真相来源”不唯一
- **回滚方案**：保留根目录入口文档，仅让其指向 `openspec/specs/`，避免双份正文

