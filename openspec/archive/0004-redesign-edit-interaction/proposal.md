# 提案：重构长截图编辑页面为拖拽调整交互

## Motivations（动机）
当前 `EditViewController` 使用每一张源图片独立配对两个 `UISlider` 的方式让用户调整裁剪点（Top Cut / Bottom Cut），但这有很多问题：
- 视觉与交互分离：用户是通过滑竿盲选，不如直接在界面上“拖动被裁剪的边缘”来得直观。
- 难以总览拼图效果：现在的试图只是每张原图的独立展示与蒙蔽，并非“拼贴后”的真实叠加结果。
- 用户要求：“直接在整体拼图的上下部分加两个可以拖动的按钮来调节，拖动然后实时就在编辑页展示调整后的结果页面”。

## Scope（范围）
- 彻底重构 `EditViewController.swift`。
- 新的交互模式下，使用 `UIScrollView` 将图片按最初始始的 `validRanges` 先叠接拼装好（可以使用多个 `UIImageView` 垂直堆叠，并依靠改变 constraint 动态叠加）。
- 在相邻的两张图片（或两端）之间绘制可以随着手指拖拽（`UIPanGestureRecognizer`）移动的自定义 `CropHandleView` 或拖拽线条。
- 拖拽的同时，实时修改相邻图像的内容裁剪区域以及它们在这个大 ScrollView 里的垂直位置，达到真正的“WYSIWYG（所见即所得）”编辑体验。
- 重置长图高度，保持整体拼图效果的连续性。

## Non-goals（非目标）
- 暂不支持原图缩放，保留现有的宽度等比例自适应。
- 对底层 `ImageStitcher` 方法的参数定义不变，只需从 UI 获取正确的 `validRanges` 下标对应的新数值回传即可。

## Acceptance Criteria（验收标准）
1. 打开 EditViewController，看到的面貌应该接近合成完成的长截图，而不是分裂开的每个原图框。
2. 每张图的衔接处或者自身，有明显的可以触摸拖拽的 UI 元素。
3. 按住手柄上下拖动时，图片本身可视范围即时截断，下方的图片跟着实时吸附、位移滑动。
4. 丝滑不卡顿：不能通过不停调用 `UIGraphicsBeginImageContext` 进行全尺寸重绘来做实施效果，必须依靠类似 Constraint/Frame 改变结合 `mask`。
5. 完成编辑后点 Done，应用准确拼接最终结果返回。

## Risks & Mitigations（风险与对策）
- **性能问题**：动态拼贴多张 UIImageView 并在拖动时批量刷新 Frame 可能会导致掉帧。
  - **对策**：使用重叠布局（Overlapping Constraints）或者简单的 Frame 计算体系，只更新受修改影响的两张图片的遮罩（mask）或高度。
