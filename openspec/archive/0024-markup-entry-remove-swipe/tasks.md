# Tasks: 移除编辑方式中间页滑动删改

> 规则：任务必须可执行、可验证、可按顺序完成。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（openspec/changes/0024-markup-entry-remove-swipe/specs/）
- [x] 更新技术方案（design.md）
- [x] 实现代码（移除 MarkupEntryViewController 的滑动编辑/删除能力）
- [x] 自测（文件级 Swift 诊断 + 手工列表交互检查说明）
- [x] 同步主规格（openspec/specs/）
- [x] 归档（移动到 openspec/archive/）

## 自测步骤（手工）

- [x] Step 1: 使用文件级 Swift 诊断检查 MarkupEntryViewController 无新增编译错误。
- [ ] Step 2: 打开中间页，确认入口仍以列表展示。
- [ ] Step 3: 点击任一列表项，确认仍能进入对应编辑页。
- [ ] Step 4: 左右滑动任一列表项，确认不再出现编辑或删除操作。
