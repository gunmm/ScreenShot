# Tasks: 编辑方式列表项增加分组间距

> 规则：任务必须可执行、可验证、可按顺序完成。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（openspec/changes/0025-markup-entry-section-spacing/specs/）
- [x] 更新技术方案（design.md）
- [x] 实现代码（调整 MarkupEntryViewController 的 section 结构以拉开项间距）
- [x] 自测（文件级 Swift 诊断 + 手工页面检查说明）
- [x] 同步主规格（openspec/specs/）
- [x] 归档（移动到 openspec/archive/）

## 自测步骤（手工）

- [x] Step 1: 使用文件级 Swift 诊断检查 MarkupEntryViewController 无新增编译错误。
- [ ] Step 2: 打开中间页，确认列表项之间存在可见间距。
- [ ] Step 3: 点击任一列表项，确认仍能进入对应编辑页。
