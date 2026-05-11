# Design: 恢复平铺文字后随二维码水印

## 现状（As-is）

- 当前 `makePresentationImage(from:)` 在非 Pro 情况下调用 `addFullScreenWatermark(to:)`。
- `addFullScreenWatermark(to:)` 只生成纯文字 tile，再以固定角度和步距平铺到整张截图上。

## 方案（To-be）

- **总体思路**：
  - 继续保留单一水印入口 `addFullScreenWatermark(to:)`。
  - 在 tile 生成阶段，把品牌文字扩展为“文字 + 白底二维码容器”。
- **模块与职责**：
  - `addFullScreenWatermark(to:)`：负责生成并平铺新的 tile。
  - `makeQRCodeImage(from:sideLength:)`：根据 App Store URL 生成二维码位图。
- **数据流**（步骤描述）：
  1. 非 Pro 导出或预览时进入 `addFullScreenWatermark(to:)`。
  2. 先绘制原图。
  3. 在离屏 tile 画布中绘制品牌文字和尾随二维码。
  4. 将 tile 旋转后全图平铺。

## 接口/数据结构变更

- 新增二维码生成辅助函数。
- 新增固定 App Store URL 常量。
- 不新增公开接口。

## 关键算法/阈值

- 二维码边长接近文字高度并带白底内边距，保证在 tile 内可见。
- 平铺步距随 tile 实际宽高计算，避免二维码加入后与相邻 tile 重叠。

## 兼容性与迁移

- 不涉及历史数据迁移。

## 可观测性

- 不新增埋点。
- 二维码生成失败时自动降级为纯文字 tile。

## 回滚策略

- 恢复纯文字 tile 实现。
