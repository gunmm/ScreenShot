# 任务拆解：重构相册手动裁剪编辑为滑块交互

- [ ] 1. **重构 `EditViewController` 的 UI层级**
  - [ ] 1.1 移除原有的 `UIView` 卡片与 `UISlider` 结构列表。
  - [ ] 1.2 建立纯粹的“上下拼接滑动视图”模式：将每个分片根据现存的 `validRanges` 动态组装成一整张看似无缝的长图（利用 `UIStackView` 或者原生的 `ScrollView` y点相加布局）。
  - [ ] 1.3 为参与拼接显示的每个图像增加顶部控制块和底部控制块。
- [ ] 2. **实现 `Draggable Handle` 及更新视觉范围**
  - [ ] 2.1 创建 `UIPanGestureRecognizer` 添加于每张图的高亮控制块上。
  - [ ] 2.2 当触控拖动上边框的控制块时，实时计算 Y 轴位移转换成新的 `targetRange.start`。
  - [ ] 2.3 当拖动下边框时，实时更新 `targetRange.end`。
  - [ ] 2.4 在 `UIPanGestureRecognizer.State.changed` 之中，立即改变当前 `UIImageView` 所在的父视图的高度（剪辑）来制造连贯变短/变长的效果，进而挤压下方所有的图像视图（StackView 会自动向上吸附）。
- [ ] 3. **保留原有的回传逻辑**
  - [ ] 3.1 退出编辑页时（Done 打击后），读取并回调最新状态的 `currentRanges` 给主页即可。
