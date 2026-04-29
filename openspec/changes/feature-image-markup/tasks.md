# Tasks: 涂鸦打码功能

- [x] 1. 创建 `MarkupViewController.swift` 文件并实现 `PKCanvasView` 和 `PKToolPicker` 相关的涂鸦编辑功能。
- [x] 2. 在 `MarkupViewController.swift` 中实现“完成”事件时的画布合成（原图+涂鸦）逻辑。
- [x] 3. 在 `ViewController.swift` 中修改底部工具栏：将原有“编辑”按钮改名为“拼接调整”，并新增“涂抹打码”按钮。
- [x] 4. 在 `ViewController.swift` 中实现进入和接收 `MarkupViewController` 结果的逻辑，并应用到主页中更新图片视图。
- [x] 5. 将 `MarkupViewController` 从双层滚动结构重构为单一内容坐标系，确保缩放精修时底图与笔迹稳定对齐。
- [x] 6. 开放长图缩放能力，并在缩放时保持内容居中显示。
- [x] 7. 将本次交互和几何约束同步回主规格 `openspec/specs/long-screenshot.md`。
