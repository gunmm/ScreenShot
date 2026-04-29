# Design: Markup 缩放边界禁用回弹

## 现状（As-is）

- `MarkupViewController` 使用只读底图滚动层叠加 `PKCanvasView`。
- 底图层配置为 `bouncesZoom = false`，而 `PKCanvasView` 当前为 `bouncesZoom = true`。
- 因此在最小/最大缩放边界继续双指捏合时，只有笔迹层会出现弹性回弹。

## 方案（To-be）

- **总体思路**：
  - 将 `PKCanvasView` 的缩放回弹关闭，使其与底图层保持一致。
- **模块与职责**：
  - `MarkupViewController`: 统一两层滚动视图的缩放边界反馈行为。
- **数据流**（步骤描述）：
  1. 用户双指缩放 `PKCanvasView`。
  2. 当达到 `minimumZoomScale` 或 `maximumZoomScale` 时，`PKCanvasView` 不再继续进入弹性区。
  3. 背景层继续只做几何同步，不再出现交互反馈差异。

## 接口/数据结构变更

- 无新增接口。
- 仅修改 `PKCanvasView` 的滚动配置。

## 关键算法/阈值

- 不修改现有最小/最大缩放系数，只修改边界交互行为。

## 兼容性与迁移

- 不涉及数据迁移。

## 可观测性

- 继续复用现有几何日志，无需新增指标。

## 回滚策略

- 若用户反馈缩放边界手感不可接受，可恢复 `bouncesZoom = true`。