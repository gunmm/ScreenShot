# 技术方案：长截图手动裁剪编辑功能

## System Architecture / 模块划分

### 1. `ImageStitcher` (现有 + 扩展)
- **增加新的接口**：`static func stitch(images: [UIImage], withRanges validRanges: [(start: Int, end: Int)]) -> UIImage?`。
- **拆分逻辑**：当前的 `stitch(images:)` 先通过 OpenCV 计算出 `validRanges`，然后进入绘制流程。我们可以将其重构为两步：
  1. `func calculateValidRanges(for images: [UIImage]) -> [(start: Int, end: Int)]`
  2. `func stitch(images: [UIImage], withRanges: [(start: Int, end: Int)]) -> UIImage?`
- 这将允许我们在进入编辑模式时，先传入自动计算的初始 `validRanges`，用户在此基础上进行修改。最后调用新的拼接接口应用修改。

### 2. `EditViewController` (新增 UI 模块)
- **输入参数**：
  - `images: [UIImage]`（原始分片）
  - `initialRanges: [(start: Int, end: Int)]`（通过自动拼接计算得到的裁剪点）
- **功能描述**：
  - 用 `UIScrollView` 展示各个分片。考虑到接缝编辑是一个精细过程，我们可以用 `UITableView` 或自定义的 `UIScrollview` 来垂直排列这些分片，并在相交处提供拖动手柄（或者是分别调整每张图的 Top/Bottom Offset 滑块）。
  - **交互方案**：使用一个专门重绘拼图的预览区域，结合控件让用户调整：
    - `Img1 Bottom`
    - `Img2 Top`
  - 用户拖动时，实时调用轻量级的合并预览。
- **输出回调**：`onConfirm(modifiedRanges: [(start: Int, end: Int)])`

### 3. `ViewController` (主页面修改)
- 增加一个 `editButton`，状态随当前是否拼接完成而变（`.generated` 时启用）。
- 保持 `generateLongScreenshot` 的现有逻辑，但记录下其生成的 `images` 数组和对应的 `validRanges`，作为 `EditViewController` 的上下文。
- 当 `EditViewController` 返回新的 `ranges` 时，调用 `ImageStitcher.stitch(images:withRanges:)` 更新结果，并将状态修改回 `.generated`。

## Data Flow / 数据流向
1. `ViewController` -> `ImageStitcher.calculateValidRanges` -> `ranges`
2. `ImageStitcher.stitch(withRanges)` -> 生成初始拼接图 -> 展现到主页
3. 用户点击编辑 -> 将 `images` 和 `ranges` 传入 `EditViewController`
4. 用户在 `EditViewController` 调整 -> 生成新 `ranges'`
5. 用户点击确认 -> `EditViewController` 调用 callback 传回 `ranges'`
6. `ViewController` 收到 `ranges'` -> `ImageStitcher.stitch(withRanges: ranges')` -> 更新结果

## Fallback / 回滚方案
如果编辑功能引入不可预知的崩溃问题，则：
- 隐藏 `editButton`，不影响默认的自动拼接逻辑即可恢复。
