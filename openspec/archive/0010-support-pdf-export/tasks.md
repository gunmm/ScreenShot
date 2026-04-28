# Tasks: 支持导出为 PDF 功能

> 规则：任务必须**可执行、可验证、可按顺序完成**。完成一项打勾一项。

## 实施清单

- [ ] 编写并确认 `0010-support-pdf-export` 变更提案、设计文档及需求规格。
- [ ] 修改 `ViewController.swift`：
  - [ ] 更改 `saveButton` 的 action 指向新的 `showSaveOptions()` 方法。
  - [ ] 实现 `showSaveOptions()`，弹出一个包含“保存图片到相册”和“分享为 PDF”的 `UIAlertController` Action Sheet。
  - [ ] 将原有的保存逻辑移至“保存图片”选项的回调中。
  - [ ] 实现 `generatePDF(from:) -> URL?` 方法，将 `UIImage` 转为临时目录下的 `.pdf` 文件。
  - [ ] 实现 `sharePDF(from:)` 方法，调起 `UIActivityViewController`。
  - [ ] 处理后台线程生成、主线程 UI 切换，以及显示 Loading 的问题。
- [ ] 自测（手工步骤 + 预期结果）
- [ ] 同步主规格（`openspec/specs/`）
- [ ] 归档（移动到 `openspec/archive/`）

## 自测步骤（手工）

- [ ] Step 1: 在生成了一张长截图之后，点击“保存”按钮，预期应该在底部弹出 Action Sheet。
- [ ] Step 2: 选择“保存图片到相册”，预期应该和以前一样将图片存入系统相册。
- [ ] Step 3: 再次点击“保存”并选择“分享为 PDF”，预期应该看到系统的 Share Sheet，并且分享的文件类型是 PDF（带有默认文件名如 LongScreenshot_...）。
- [ ] Step 4: 在 Share Sheet 中选择“存储到文件”并完成保存，去系统“文件”App 中打开该 PDF 文件，预期内容显示完整且正确。
