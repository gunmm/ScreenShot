# Design: 编辑放大镜显示真实接缝内容

## 现状（As-is）

- 当前放大镜为 160 方形，固定在编辑区域左上角或右上角。
- 采样来源已切换为原图像素，解决了界面截图抖动问题。
- 但当前只裁切单张图像素，导致放大镜无法同时展示接缝上下两侧内容，与用户实际要观察的 seam 不一致。

## 方案（To-be）

- 总体思路：
  - 将放大镜内容改为离屏合成的 seam preview。
  - 对于每个 handle，分别取接缝上侧和下侧对应分片的局部区域，再拼成一张完整的 160 方形图。
- 模块与职责：
  - EditViewController：持有所有原始图片和 currentRanges，负责生成真实 seam preview。
  - ChunkContainer：只负责请求放大镜内容并展示，不再自行决定 seam 预览来源。
- 数据流：
  1. ChunkContainer 在拖动时根据当前 handle 请求 magnifier image。
  2. EditViewController 根据 index 和 handle 找到 seam 上下两侧对应的图片与边界像素。
  3. 从两张原图中各裁一块局部区域。
  4. 离屏绘制为同一张预览图后回传给 ChunkContainer。

## 接口/数据结构变更

- ChunkContainerDelegate 新增一个用于生成放大镜图像的方法。
- 不修改原有 didUpdateRange 与 selection 协议。

## 关键算法/阈值

- 方形预览分为上下两个半区，每个半区分别绘制 seam 上方和下方内容。
- 顶部 handle：上半区取上一分片底部，下半区取当前分片顶部。
- 底部 handle：上半区取当前分片底部，下半区取下一分片顶部。
- 无相邻分片时，退化为同一张图在 seam 上下两侧的局部预览。

## 兼容性与迁移

- 无数据迁移。
- 仅修正编辑页拖动时放大镜内容语义。

## 可观测性

- 通过手工拖动对比放大镜与真实接缝位置是否一致。

## 回滚策略

- 回退到上一版单图裁切的 magnifier image 生成逻辑即可。
