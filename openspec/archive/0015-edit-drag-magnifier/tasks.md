# Tasks: 编辑拖动放大镜预览

> 规则：任务必须可执行、可验证、可按顺序完成。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（openspec/changes/0015-edit-drag-magnifier/specs/long-screenshot.md）
- [x] 更新技术方案（design.md）
- [x] 实现代码（EditViewController 中为拖动手柄增加放大镜预览）
- [ ] 自测（手工步骤 + 预期结果）
- [x] 同步主规格（openspec/specs/long-screenshot.md）
- [x] 归档（移动到 openspec/archive/）

## 自测步骤（手工）

- [ ] Step 1: 生成长截图后进入 Edit 页面，选中任意分片并拖动顶部手柄，观察是否出现并更新放大镜。
- [ ] Step 2: 拖动底部手柄并结束，观察放大镜是否实时刷新且在手势结束后立即消失。
