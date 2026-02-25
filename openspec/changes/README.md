# 变更工作区（changes）

每一次功能迭代/修复都应该在这里开一个变更目录，包含四类产物：

- `proposal.md`：变更动机、范围、非目标、验收、风险
- `specs/`：需求规格（场景/边界/验收细化）
- `design.md`：技术方案（模块/接口/数据流/取舍/回滚）
- `tasks.md`：实现清单（按顺序、可勾选、可验证）

## 如何新建一个变更

1. 复制 `openspec/changes/_template/` 为新目录：
   - 命名建议：`NNNN-<短横线英文或拼音>`（例如 `0002-preferred-extension`）
2. 先写文档再改代码：
   - 先填 `proposal.md` → `specs/` → `design.md` → `tasks.md`
3. 实现完成后：
   - 把最终结论同步回 `openspec/specs/`
   - 将变更目录移动到 `openspec/archive/`

