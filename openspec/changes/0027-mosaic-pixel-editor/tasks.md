# Tasks: 马赛克页接入真实像素化编辑

> 规则：任务必须可执行、可验证、可按顺序完成。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（openspec/changes/0027-mosaic-pixel-editor/specs/）
- [x] 更新技术方案（design.md）
- [x] 实现代码（MosaicViewController 接入像素化编辑；MarkupEntryViewController 更新入口文案）
- [ ] 自测（文件级 Swift 诊断 + 聚焦编译校验）
- [x] 同步主规格（openspec/specs/）
- [ ] 归档（移动到 openspec/archive/）

## 自测步骤（手工）

- [ ] Step 1: 检查 MosaicViewController 与 MarkupEntryViewController 没有新增 Swift 诊断错误。
- [ ] Step 2: 进入马赛克页，单指滑动后能实时看到像素化效果。
- [ ] Step 3: 调整粗细、透明度并再次绘制，确认新笔划参数生效。
- [ ] Step 4: 依次执行撤销、重做、完成，确认预览与导出结果一致。