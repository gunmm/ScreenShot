# 任务拆解：长截图手动裁剪编辑功能

- [ ] 1. **重构 `ImageStitcher`**
  - [ ] 1.1 提取 `calculateValidRanges(for images: [UIImage]) -> [(start: Int, end: Int)]`。
  - [ ] 1.2 提取核心拼接方法 `stitch(images: [UIImage], withRanges: [(start: Int, end: Int)]) -> UIImage?`。
  - [ ] 1.3 确保现有无参数的 `stitch(:)` 调用这两步，不改变原有外部行为。
- [ ] 2. **主页面状态支持**
  - [ ] 2.1 在 `ViewController` 原有的 `UIState.generated` 关联值中，除了 `size` 外，同时存下 `images: [UIImage]` 和当前的 `validRanges: [(start: Int, end: Int)]`。
  - [ ] 2.2 在 `ViewController` 添加 `Edit / 编辑` 按钮，仅在有结果时启用。
- [ ] 3. **新增 `EditViewController`**
  - [ ] 3.1 创建包含取消、确认按钮的导航栏。
  - [ ] 3.2 使用 `UIScrollView` 排列所有图像，并支持通过某种交互（比如 Slider 叠加，或直接控制 ImageView 内容显示区域）来修改每张图的 Top/Bottom Range。
  - [ ] 3.3 每次拖动结束，调用轻量级的 `ImageStitcher.stitch(withRanges:)` 更新中间的预览图（或者仅使用 UIKit 的 contentRect 切割层叠显示来模拟更少开销地拖放）。
  - *注：为避免每次滑动时重新绘制非常大的 UIImage，在 `EditViewController` 中我们使用多个重叠的 `UIImageView`，动态改变各自的 bounds/mask 或 frame。滑动完成点击确认后，再真正执行合并绘制。*
- [ ] 4. **完成回调与页面刷新**
  - [ ] 4.1 `EditViewController` 确认后回调闭包 `onConfirm(newRanges)`。
  - [ ] 4.2 `ViewController` 收到回调后重新调用 `ImageStitcher.stitch(images: images, withRanges: newRanges)` 产生最终图。
  - [ ] 4.3 刷新 UI 显示最终结果图，并允许用户一如既往地分享/保存。
