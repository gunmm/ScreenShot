# Design: 支持导出为 PDF 功能

## 现状（As-is）

- 当前系统中，`ViewController` 中的 `saveButton` 直接绑定到 `@objc private func saveToPhotos()`。
- `saveToPhotos()` 会获取当前 `imageView.image`（如果是非付费状态，已附带全屏水印）。
- 调用 `performSave(image:)` 请求相册权限，调用 `UIImageWriteToSavedPhotosAlbum` 将图片直接保存到系统相册中。

## 方案（To-be）

- **总体思路**：将原本点击“保存”直达相册的行为，拦截为一个中间选择态（Action Sheet）。用户选择保存类型后，图片按原逻辑走，PDF 则转换为 Data 后经由系统分享面板导出。
- **模块与职责**：
  - `ViewController`: 新增 PDF 生成逻辑，新增弹出选择菜单和分享面板的逻辑。
- **数据流**：
  1. 点击“保存”按钮 -> 弹出 `UIAlertController` (ActionSheet: "保存为图片" / "分享为 PDF" / "取消")
  2. 若选“保存为图片” -> 执行现有的 `saveToPhotos()` -> `performSave()` -> `UIImageWriteToSavedPhotosAlbum`
  3. 若选“分享为 PDF” -> 调用 PDF 转换函数 -> 得到 `Data` -> 写入到临时文件 `NSTemporaryDirectory()` 作为 `.pdf` 文件（或直接将 Data 传给 UIActivityViewController，但提供文件 URL 可以让系统更好地识别文件名） -> 唤起 `UIActivityViewController`

## 接口/数据结构变更

- `ViewController.swift`:
  - 变更 `saveButton` 的 action，从 `saveToPhotos` 改为 `showSaveOptions`。
  - 新增 `func showSaveOptions()`
  - 新增 `func generatePDF(from image: UIImage) -> URL?`
  - 新增 `func sharePDF(from url: URL)`

## 关键算法/阈值

- **PDF 转换**：使用 `UIGraphicsPDFRenderer`。格式为与图片相同的物理尺寸 (`CGRect(origin: .zero, size: image.size)`)，实现单页连续长 PDF。
- **文件名生成**：将导出的 PDF 临时文件命名为 `LongScreenshot_yyyyMMdd_HHmmss.pdf`，以便用户保存到“文件”应用时有一个合理的默认名称。

## 兼容性与迁移

- 本次变更纯属交互和导出格式增强，不涉及本地状态持久化的迁移。

## 可观测性

- 在生成 PDF 失败、分享面板弹出等关键节点通过 `AppLogger` 输出日志，方便跟踪。

## 回滚策略

- 将 `saveButton` 的 Target-Action 恢复绑定至 `saveToPhotos` 即可完全回到变更前状态。
