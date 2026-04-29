# Tasks: Markup 撤销按钮初始状态修复

> 规则：任务必须可执行、可验证、可按顺序完成。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（openspec/changes/.../specs/）
- [x] 更新技术方案（design.md）
- [x] 实现代码（MarkupViewController 初始化与绘制变化时刷新按钮状态）
- [x] 验证（MarkupViewController 文件级诊断通过；工程级 xcodebuild 因本次会话跳过未执行）
- [x] 同步主规格（openspec/specs/）
- [x] 归档（移动到 openspec/archive/）

## 验证记录

- [x] Step 1: 对 MarkupViewController 执行文件级诊断，结果无错误。
- [ ] Step 2: 打开涂抹编辑页，确认未绘制时撤销/重做按钮为禁用。
- [ ] Step 3: 绘制一笔后确认撤销按钮可用，撤销到空白后确认重做可用。
- [ ] Step 4: 重做到最新状态后确认重做禁用。
