# Design: 编辑放大镜稳定性修正

## 现状（As-is）

- 当前放大镜每次更新都对 superview.layer 做截图，再截取接缝附近的矩形区域。
- 由于拖动时当前分片的高度、边框、手柄可见状态都在变化，截图结果会携带这些动态 UI 元素，造成抖动感。
- 当前方形放大镜尺寸为 144。

## 方案（To-be）

- 总体思路：
  - 放大镜采样来源改为 originalImage 的像素内容。
  - 根据当前 handle 对应的 seam 像素位置，直接从原图中裁切一个稳定的方形区域显示到放大镜。
  - 放大镜边长调整为 160。
- 模块与职责：
  - ChunkContainer：负责将当前 top/bottom seam 映射到原图像素坐标，并生成裁切图像。
  - SeamMagnifierView：继续负责承载方形预览内容，不再依赖视图截图。
- 数据流：
  1. 手柄拖动更新 currentRange。
  2. 根据 handle 类型读取当前 seam 对应的像素 Y 坐标。
  3. 从 originalImage.cgImage 直接裁切方形区域。
  4. 将裁切结果显示到固定角落放大镜。

## 接口/数据结构变更

- 仅修改 ChunkContainer 内部放大镜私有方法。
- 不修改外部协议和公共接口。

## 关键算法/阈值

- seamPixelY 对顶部手柄取 currentRange.start，对底部手柄取 currentRange.end。
- 采样窗口尺寸由 magnifierSize 和 magnifierZoomScale 反推，并以原图像素为单位计算。
- 采样窗口需要在原图边界内做夹紧，避免越界裁切。

## 兼容性与迁移

- 无数据迁移。
- 仅影响编辑页拖动中的视觉反馈。

## 可观测性

- 通过手工拖动观察预览稳定性和 seam 对齐情况。

## 回滚策略

- 如需回退，恢复 superview 截图采样方法即可。
