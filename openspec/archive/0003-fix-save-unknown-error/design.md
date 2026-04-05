# Design: 修复保存图片时显示未知错误的 Bug

## 模块与接口变更

- **模块**：`ViewController`
- **关联方法**：`private func performSave(image: UIImage)`

## 数据流/执行流变更

**原流程**：
1. 点击保存按钮触发 `saveToPhotos()` -> `performSave(image:)`。
2. 调用 `PHPhotoLibrary.requestAuthorization`。
3. 系统在**后台线程**触发回调。
4. 回调里面直接调用 `UIImageWriteToSavedPhotosAlbum`。
5. 系统因为不在主线程调用 UI 核心方法而可能静默失败，调用了完成回调，并抛出 `Error Domain=NSCocoaErrorDomain Code=-1`（未知错误）。

**新流程**：
1. 前几步同上。
2. 系统在**后台线程**触发回调，检查授权状态。
3. 如果状态通过，将 `UIImageWriteToSavedPhotosAlbum` 调用包在 `DispatchQueue.main.async` 或 `DispatchQueue.main.async` 内，转发到主线程执行。
4. 主线程成功保存图片或产生恰当的错误信息。完成回调 `image(_:didFinishSavingWithError:contextInfo:)` 也将在主线程中执行，安全地更新 UI 并弹出系统提示框。

## 取舍（Trade-offs）

- 无负面取舍。这是标准的 iOS 线程模型规范。

## 回滚方案

- 还原 `ViewController.swift` 中引入的 `DispatchQueue.main.async` 包裹即可。
