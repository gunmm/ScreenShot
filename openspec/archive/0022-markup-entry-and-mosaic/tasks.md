# Tasks: 编辑方式中间页与马赛克页骨架

> 规则：任务必须可执行、可验证、可按顺序完成。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（openspec/changes/0022-markup-entry-and-mosaic/specs/）
- [x] 更新技术方案（design.md）
- [x] 实现代码（ViewController 接入中间页；新增 MarkupEntryViewController、MosaicViewController；调整 MarkupViewController 导航行为）
- [x] 自测（文件级 Swift 诊断 + 手工导航检查说明）
- [x] 同步主规格（openspec/specs/）
- [x] 归档（移动到 openspec/archive/）

## 自测步骤（手工）

- [x] Step 1: 使用文件级 Swift 诊断检查 ViewController、MarkupViewController、MarkupEntryViewController、MosaicViewController 无新增编译错误。
- [ ] Step 2: 生成长图后点击“涂抹/打码”，确认先进入中间选择页。
- [ ] Step 3: 从中间页进入“涂抹”，检查返回按钮回到中间页，点击“完成”后主页图像更新并关闭整个流程。
- [ ] Step 4: 从中间页进入“马赛克”，检查页面可正常打开并显示占位内容。
