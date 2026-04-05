# Proposal: 修复保存图片时显示未知错误的 Bug

## 背景 / 动机

- 线上有用户反馈：在保存长截图时，一点击保存就提示保存失败，显示“未知错误”。
- 分析代码发现，保存图片到相册的核心代码 `UIImageWriteToSavedPhotosAlbum` 被包裹在 `PHPhotoLibrary.requestAuthorization` 的回调中执行。该回调系统默认分配在后台线程。但在 iOS 中，UIKit 及其相关的部分 API（特别是 `UIImageWriteToSavedPhotosAlbum`）必须在主线程中执行，否则会导致不可预料的错误（也就是常见的 Error Domain=NSCocoaErrorDomain Code=-1 "Unknown error"）。

## 目标（Goals）

- G1: 修复点击保存按钮后报错“未知错误”的 Bug。
- G2: 确保 `UIImageWriteToSavedPhotosAlbum` 及后续的 UI 更新操作强制分发到主线程 (Main Thread) 中执行。

## 非目标（Non-goals）

- NG1: 不修改其他的用户界面流程或长截图生成逻辑。

## 范围（Scope）

- **会改的部分**：
  - 文件：`ViewController.swift` 中的 `performSave(image: UIImage)` 方法。
  - 行为变化：授权成功后，保存操作被调度到主队列执行。
- **不会改的部分**：
  - 不修改其他的 UI 元素或权限请求逻辑。

## 需求概要

- 当相册权限检查通过后，将保存相片的具体动作抛回主线程。

## 验收标准（Acceptance Criteria）

- AC1: 在获取相册权限并保存图片时，图片能够成功进入相册，且界面弹出保存成功的提示框。
- AC2: 在所有设备或模拟器上，不再出现偶发的“保存出错: The operation couldn't be completed. (Unknown error.)”或者“未知错误”。

## 风险与回滚

- **风险**：极低。修正线程派发不仅符合 Apple 开发规范，也是安全必要的。
- **回滚方案**：撤销 `ViewController.swift` 代码修改即可。
