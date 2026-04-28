# Design: 软性付费墙 (带水印导出)

## 现状（As-is）

- 当前在 `ViewController.swift` 的 `saveToPhotos` 方法中：如果 `isTrialExpired` 且不是 `isPurchased`，会弹出一个 `UIAlertController` 提示试用已结束，仅提供“取消”和“去解锁”两个选项。如果点击取消，保存流程就会中断。

## 方案（To-be）

- **总体思路**：修改过期后提示弹窗的选项，增加“带水印保存”。当用户选择此选项时，通过 CoreGraphics 对当前生成的图片在右下角追加文字水印，然后再进行保存相册的逻辑。
- **模块与职责**：
  - `ViewController.swift`: `saveToPhotos()` 方法更新弹窗逻辑，引入新的 Alert Action。增加 `addWatermark(to:)` 方法，利用 `UIGraphicsBeginImageContext` 进行图片重新绘制，叠加上水印信息。
- **数据流**：
  1. 用户点击“保存”。
  2. 判断状态。如果过期且未购买，弹窗。
  3. 用户选择“带水印保存”。
  4. 获取 `imageView.image`，传递给 `addWatermark(to:)`。
  5. `addWatermark` 方法开辟与原图等大 Context，先绘制原图，然后在右下角指定位置（带有一定 padding）绘制半透明的文字“由「滚动长截屏」生成”以及背景阴影或圆角背景框。
  6. 取出带有水印的 UIImage，继续调用 `performSave(image:)` 完成相册授权与保存。

## 接口/数据结构变更

- `ViewController.swift` 新增方法：
  ```swift
  private func addWatermark(to image: UIImage) -> UIImage
  ```
  输入 `UIImage`，输出加上水印后的 `UIImage`。

## 关键算法/阈值

- 水印大小：水印的字号应该相对图片宽度自适应（例如图片宽度的 3% 到 5%），确保在不同分辨率和尺寸的手机截图中都能清晰可见但不过度突兀。
- 水印位置：右下角，距离底部和右侧各有一小段 Margin（例如屏幕宽度的 2%）。
- 水印样式：半透明黑色背景框，白色文字，带轻微阴影，以适应浅色和深色截图背景。

## 兼容性与迁移

- 不涉及老数据迁移，仅在保存时动态生成。

## 可观测性

- `addWatermark(to:)` 应该在日志中输出 "Adding watermark to image of size X by Y"，以便确认水印绘制逻辑确实执行。

## 回滚策略

- 可以直接撤销 `ViewController.swift` 中关于 `saveToPhotos` 弹窗的修改。
