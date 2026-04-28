# Design: 去除试用期并实现全屏水印

## 现状（As-is）

- 当前包含 7 天试用逻辑。在试用期过期后保存图片时弹出软付费墙选项，通过右下角添加小水印的方式提供基础功能保存。预览过程中一直是无水印原图。

## 方案（To-be）

- **总体思路**：移除 `PurchaseStatusManager` 的 `isTrialExpired` 检查。`ViewController` 通过判断 `!isPurchased()` 决定是否给图片应用全屏水印。全屏水印应用时机提早到 `display(image:)` 之前，从而让预览和保存时使用的是同一张带水印的图。
- **模块与职责**：
  - `PurchaseStatusManager`: 精简代码，仅提供 `isPurchased()` 与 `setPurchased(_)`。
  - `ViewController`: 管理 `rawStitchedImage` 以保存无水印底图；添加全屏水印绘制逻辑；添加购买引导 UI。

## 接口/数据结构变更

- `ViewController.swift`:
  ```swift
  private let unlockProButton = UIButton(type: .system)
  private var rawStitchedImage: UIImage?
  
  private func addFullScreenWatermark(to image: UIImage) -> UIImage
  ```
- `PurchaseStatusManager.swift`:
  删除 `ensureTrialExpirationDate`, `isTrialExpired`, `readTrialExpirationDate`, `setTrialExpirationDate`。

## 关键算法/阈值

- **全屏水印算法**：
  1. 通过 `UIGraphicsBeginImageContextWithOptions` 开辟上下文。
  2. 使用 `CGContext.rotate(by: -CGFloat.pi / 6)` 倾斜画布（-30度）。
  3. 通过 `stride` 进行坐标遍历（考虑到旋转后内容偏移，循环区域要延伸到负坐标以及对角线长度以外，使用原图对角线长度 `diag` 扩展边界）。
  4. 水印文本: "图片来自 App Store滚动长截屏-滚动长截图"。
  5. 绘制颜色为白色，透明度约为 0.25 - 0.35。
