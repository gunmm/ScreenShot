# Design: 缓存水印文字 tile 与二维码图

## 现状（As-is）

- `addFullScreenWatermark(to:)` 每次都会重新创建文字 tile。
- `makeQRCodeImage(from:sideLength:)` 每次都会重新创建 Core Image filter、输出图和渲染图片。

## 方案（To-be）

- **总体思路**：
  - 在 `ViewController` 内部增加两类轻量缓存：
    - 文字 tile 缓存
    - 二维码图片缓存
- **模块与职责**：
  - 文字 tile helper：按 `text + font size + scale` 生成缓存 key。
  - 二维码 helper：按 `url + sideLength` 生成缓存 key。
  - `CIContext` 作为长期属性复用，避免每次重新创建。

## 接口/数据结构变更

- 新增若干私有缓存属性。
- 新增私有 helper，用于返回缓存命中或新建图片。

## 关键算法/阈值

- 缓存 key 使用稳定字符串，尺寸使用格式化后的浮点值以避免不必要抖动。
- 缓存仅保存最近一次生成结果，控制复杂度和内存占用。

## 兼容性与迁移

- 无数据迁移。

## 可观测性

- 无新增埋点。

## 回滚策略

- 删除缓存属性与 helper，恢复现算逻辑。
