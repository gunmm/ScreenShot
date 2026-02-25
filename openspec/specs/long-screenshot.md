# 长截图端到端规格（包含编辑功能）

## 1. 业务场景
该模块是一个允许用户从系统级的屏幕录制（ReplayKit / Broadcast Upload Extension）中连续捕获屏幕滚动帧，并在录制结束后将所有帧无缝拼接成一张长图的工具方案。

### 新增功能（编辑）
拼接完成后，由于 OpenCV 特征匹配有时会因为滚动速度不均或出现大量相同色彩导致拼接瑕疵，用户可以点击“Edit / 编辑”进入手动裁剪模式，通过滑块分别调整相邻每张切片的上下裁剪位置，达到完美无缝拼接。

## 2. 核心架构与数据流

### 2.1 录制与分片收集
- **`SampleHandler`**: 接收 ReplayKit 发送的视频帧 (`CMSampleBuffer`)。
- **`FrameProcessor`**: 对每一帧进行对比计算，只有出现滚动特征时（与上一帧差异足够大），才将其视作有效的分片（Chunk）。
- **持久化**: 分片以 JPEG 格式存入 App Group 的共享目录中。

### 2.2 自动拼接（Stitching）
由主 App 中的 `ViewController` 触发。
- **读取分片**：从共享目录读出所有图片，按编号排序。
- **计算裁剪区间 (`calculateValidRanges`)**：
  1. 遍历相邻图片对 $(Img_i, Img_{i+1})$。
  2. 交由 `OpenCVWrapper` 使用特征点匹配技术，查找 $Img_{i+1}$ 顶部在 $Img_i$ 底部匹配的位置及位移(`offsetY`)。
  3. 计算得到每张图片要截取的有效范围：`validRanges[(start, end)]`。
- **绘图 (`stitch(withRanges:)`)**：
  1. 根据 `validRanges` 累加出长截屏的总高度。
  2. 创建 `UIGraphicsImageContext`。
  3. 遍历图片，将每张图片在 `validRanges` 确定的部分按顺序通过 `CoreGraphics` 裁剪后画入上下文中。

### 2.3 手动编辑（Edit）
由用户观察拼接结果后主动触发。
- **`EditViewController`** (互动大更)：
  1. 接收 `images: [UIImage]` 和 `initialRanges: [(start: Int, end: Int)]`。
  2. 使用 `UIStackView` 在 `UIScrollView` 内将所有分片连贯堆叠，**模拟最终成品的无缝拼贴**。
  3. 各张片的 `ChunkContainer` 配置上下两根可供拖拽操作的 Handle (横线区)，拦截 `UIPanGestureRecognizer` 手势指令。
  4. 拖拽期间：利用 `currentRanges` 的改变实时作用在内部图片的位置偏移（TopConstraint offset）和视图窗的高（HeightConstraint）限制上，以达成**所见即所得、滑动自动缝合**的互动效果。
  5. 点击 Done 回传调整好的 `newRanges`。
- **重新拼接与应用**：
  1. `ViewController` 收到 `newRanges`，后台线程重新调用 `ImageStitcher.stitch(withRanges:)`。
  2. 更新覆盖主界面的展示大图。

## 3. 边界条件与容错处理
1. **录片不足**：至少需要 >=2 个分片才能触发拼接，否则提示录制时间过短。
2. **OpenCV 匹配失败**：如果两个图片找不到明显的重叠特征点（置信度过低），会采用 Full Appending （不裁剪直接叠加）作为安全降级方案，以免丢失内联容错数据。用户可通过 Edit 修正。
3. **负高度或负重叠**：如果用户或者 OpenCV 将上一图的底部切在下一图的顶部还要靠上的位置，会通过高度传播算法（Debt Propagation）使得负重叠被前方分片“吸收”，避免在画布上绘制出负坐标的画面。
4. **编辑界面无效输入**：保证 Top Slider 的值不会大于 Bottom Slider。
