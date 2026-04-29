# Tasks: 编辑方式中间页列表化与滑动操作

> 规则：任务必须可执行、可验证、可按顺序完成。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（openspec/changes/0023-markup-entry-list-swipe/specs/）
- [x] 更新技术方案（design.md）
- [x] 实现代码（MarkupEntryViewController 改为列表页并接入滑动删改）
- [x] 自测（文件级 Swift 诊断 + 手工列表交互检查说明）
- [x] 同步主规格（openspec/specs/）
- [x] 归档（移动到 openspec/archive/）

## 自测步骤（手工）

- [x] Step 1: 使用文件级 Swift 诊断检查 MarkupEntryViewController 无新增编译错误。
- [ ] Step 2: 打开中间页，确认入口从顶部向下以列表展示。
- [ ] Step 3: 点击任一列表项，确认仍能进入对应编辑页。
- [ ] Step 4: 对列表项执行编辑滑动操作，确认文案可在当前页实时更新。
- [ ] Step 5: 对列表项执行删除滑动操作，确认条目从列表消失，删除到空列表时出现空状态提示。
