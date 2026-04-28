# Specs: 支持导出为 PDF 功能

## 用户故事 (User Stories)

- 作为一名职场人士，我希望能将生成的网页或对话长图直接保存为 PDF 文件存储在 iCloud Drive 中，以便在 Mac 或 PC 上方便地查阅和归档，而不需要它污染我的手机相册。

## 边界与约束 (Boundaries & Constraints)

1. 生成的 PDF 是一页超长 PDF，宽度和高度与拼接的长截图保持一致，不强制将其切分为 A4 多页。
2. 若用户尚未解锁 Pro，生成的 PDF 同图片一样，会带有全屏半透明水印。
3. PDF 生成需在后台线程执行，避免由于图片过大导致主线程卡顿（UI 卡死）。
4. 通过 `UIActivityViewController` 调起分享，依赖于 iOS 系统提供的「存储到文件」功能，由于沙盒机制，App 不直接向用户自定义路径写文件。
