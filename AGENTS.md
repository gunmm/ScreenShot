# AI 代理工作约束（OpenSpec-first）

本仓库采用 **OpenSpec（规范驱动开发 / SDD）** 作为唯一开发流程。

## 你必须遵循的流程（强制）

任何非纯文档/格式化的代码改动，都必须按以下顺序执行：

1. **Propose（提出变更）**
   - 在 `openspec/changes/` 下创建一个新的变更目录（参考 `openspec/changes/_template/`）。
   - 先写清楚 `proposal.md`（动机、范围、非目标、验收标准、风险）。
2. **Spec（写清需求）**
   - 在该变更目录的 `specs/` 下补充/修改需求规格（用户故事、边界、验收）。
3. **Design（技术方案）**
   - 写 `design.md`（模块/数据流/接口变更/取舍/回滚方案）。
4. **Tasks（任务拆解）**
   - 写 `tasks.md`（可勾选、可验收、可按顺序执行）。
5. **Apply（实现）**
   - 仅在以上文档齐备后才允许修改代码。
6. **Sync（同步主规格）**
   - 将本次变更沉淀回 `openspec/specs/`（主规格）中，确保“真相来源”更新。
7. **Archive（归档）**
   - 将完成的变更目录移动到 `openspec/archive/`，保留可追溯记录。

## 真相来源（Source of Truth）

- **已实现系统规格**：`openspec/specs/`
- **正在进行/待做的变更**：`openspec/changes/`
- **已完成的历史变更**：`openspec/archive/`

## 不允许的行为

- 未更新 `openspec/changes/...` 的提案/规格/设计/任务，就直接改代码
- 只改代码不更新 `openspec/specs/`（会导致规格与实现背离）
- 在 `changes/` 里写“空洞口号”但没有验收标准/边界条件/回滚方案

