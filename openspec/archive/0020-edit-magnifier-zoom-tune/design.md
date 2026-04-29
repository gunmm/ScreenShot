# Design: 微调编辑放大镜放大倍数

## 现状（As-is）

- 当前放大镜尺寸为 160 x 160。
- 真实 seam 预览逻辑已经稳定，放大倍数由 ChunkContainer 中的 magnifierZoomScale 常量控制，当前值为 2.75。

## 方案（To-be）

- 总体思路：
  - 仅上调 magnifierZoomScale 常量。
  - 不改 seam 预览生成逻辑和 UI 布局。
- 模块与职责：
  - ChunkContainer：继续通过 magnifierZoomScale 控制采样窗口大小。
- 数据流：
  1. 拖动时仍请求真实 seam 预览。
  2. 更高的 zoomScale 使采样窗口略微缩小。
  3. 放大镜展示的 seam 内容因此更大。

## 接口/数据结构变更

- 无接口变更。
- 仅修改内部常量。

## 关键算法/阈值

- 将 magnifierZoomScale 从 2.75 小幅上调到 3.1。
- 这是一次保守调整，优先保证 seam 上下文仍然足够。

## 兼容性与迁移

- 无数据迁移。
- 仅影响编辑页放大镜视觉比例。

## 可观测性

- 通过手工拖动接缝观察放大镜细节大小变化。

## 回滚策略

- 将 magnifierZoomScale 改回 2.75 即可。
