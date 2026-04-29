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
- 坐标系设计：
  - 编辑器采用**单一内容坐标系**，不再维护“背景 scrollView + 透明 canvasView”两套滚动状态。
  - `displaySize` 仍按可用宽度等比缩放得到，作为编辑时的统一内容尺寸。
  - `PKCanvasView` 负责绘制、滚动与缩放，背景图使用独立的 `UIImageView` 放在其后方视口内。
  - 为了消除缩放时的几何误差，背景图实际承载在一个只读 `UIScrollView` 中，并同步 `PKCanvasView` 的 `zoomScale`、`contentInset` 与 `contentOffset`。
  - 原图的显示 frame 根据 `zoomScale + contentOffset + contentInset` 进行同步计算，使底图与笔迹共享同一套视觉几何。
  - 所有笔迹都保留在 `PKCanvasView` 原生坐标空间内，避免外层缩放容器影响 PencilKit 的历史笔迹渲染。

- 缩放与平移：
  - `PKCanvasView` 承担滚动与缩放手势，并保留原生的 PencilKit 绘制反馈。
  - 最小缩放比例按可视高度适配整张长图，保证用户可以一键回到全图视角。
  - 最大缩放比例提升到 `4.0`，用于头像、昵称、手机号等局部精修。
  - 在缩放过程中同步更新 `contentInset`，保证内容在宽度较小时居中显示，减少横向飘移感。

- 渲染输出合成逻辑：
  - 点击“完成”(`doneTapped`) 时，将 `displaySize` 坐标系中的 `PKDrawing` 通过等比缩放映射回 `originalImage.size` 的像素坐标系。
  - 创建 `UIGraphicsImageRenderer`，使用 `originalImage.size` 和原始图片的 `scale` 以保证清晰度不降低。
  - 先绘制 `originalImage`，再绘制缩放后的 `drawingImage`，得到最终输出图。

- 取舍：
  - 这次重构先解决“可缩放精修 + 精准对齐”。
  - 暂不引入 `PKDrawing` 的持久化恢复，避免把本次变更范围扩大到主页状态模型。
