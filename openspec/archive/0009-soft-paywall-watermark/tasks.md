# Tasks: 软性付费墙 (带水印导出)

- [x] 创建 Proposal (`proposal.md`)。
- [x] 更新需求规格 (`specs/long-screenshot.md`)。
- [x] 撰写技术方案 (`design.md`)。
- [ ] 修改 `ViewController.swift` 的 `saveToPhotos` 方法：
  - [ ] 当试用期过期且未购买时，增加弹窗选项“带水印保存”。
  - [ ] 保留“去解锁”和“取消”按钮。
- [ ] 在 `ViewController.swift` 中新增图片加水印的方法 `addWatermark(to:)`：
  - [ ] 使用 `UIGraphicsBeginImageContextWithOptions` 重新绘制带水印的图片。
  - [ ] 在右下角绘制半透明背景框和文字水印。
- [ ] 确保用户选择“带水印保存”时，调用 `addWatermark(to:)` 并将返回的新图片传给 `performSave(image:)`。
- [ ] 确保选择“去解锁”时进入支付流程，并在支付成功后调用 `performSave(image:)` 原图保存。
- [ ] 测试免费/未购买状态下的保存带水印。
- [ ] 测试已购买状态下的无水印保存。
- [ ] 完成后执行 `Sync`（复制规格回主目录）并 `Archive`。
