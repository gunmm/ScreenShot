# Design: 涂鸦打码功能

## 1. 交互与数据流变更
1. **主页 UI 调整 (`ViewController.swift`)**:
   - `actionsStack` 增加 `markupButton`。
   - `editButton` 标题从“编辑”改为“拼接调整”。
   - 当点击“拼接调整”时，继续使用 `EditViewController`。
   - 当点击“涂鸦/打码”时，弹出新的 `MarkupViewController`。
2. **数据流**:
   - 现有的 `rawStitchedImage` 存储了无水印的拼接原图。
   - 涂鸦编辑时，将 `rawStitchedImage` 传入 `MarkupViewController`。
   - 编辑完成后，将渲染了涂鸦的新图赋值给 `rawStitchedImage`，并重新调用 `display(image:)` 以应用水印（如果未付费）。
   - **状态处理注意**：如果用户先涂鸦打码，然后再去点击“拼接调整”，因为“拼接调整”是直接拿原始分片图像（`ChunkManager` 中的图片）重新拼接的，所以会覆盖掉之前的涂鸦。考虑到这本身是个相对线性的流程（一般都是先拼接再打码），在本次 MVP 中暂不需要做复杂的涂鸦点位映射。只要保证每一次新拼接都会产生干净的长图，而每一次打码都是基于当前 `rawStitchedImage` 叠加即可。

## 2. 模块设计 (`MarkupViewController.swift`)
- 视图层级与组件：
  - 创建一个 `UIViewController` 作为宿主容器。
  - 使用 `PKCanvasView` 作为全屏的画板。
  - 为了完美对齐和支持缩放：
    - 由于 `PKCanvasView` 继承自 `UIScrollView`，并且自带了非常优秀的缩放、平移手势支持。
    - 我们只需要设置 `canvasView.contentSize` 为原图大小。
    - 然后通过 `canvasView.insertSubview(imageView, at: 0)` 将带有长截图的 `UIImageView` 放在画板的最下层。
    - 这样在缩放或滑动时，图片和画板笔迹会完全同步移动，体验最好。
  - 使用 `PKToolPicker` 来显示底部的画笔选择器，并将其关联到 `canvasView`。

- 渲染输出合成逻辑：
  - 点击“完成”(`doneTapped`) 时，需要将底层原图与表层的 PencilKit 涂鸦合并为一张新图片。
  - 创建 `UIGraphicsImageRenderer`，使用 `originalImage.size` 和原始图片的 `scale` 以保证清晰度不降低。
  - `originalImage.draw(at: .zero)`
  - `let drawingImage = canvasView.drawing.image(from: CGRect(origin: .zero, size: originalImage.size), scale: originalImage.scale)`
  - `drawingImage.draw(at: .zero)`
  - 取出 `renderer.image` 作为合并结果。返回给 `ViewController`。
