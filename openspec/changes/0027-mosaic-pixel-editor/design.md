# Design: 马赛克页接入真实像素化编辑

## 现状（As-is）

- MarkupEntryViewController 已经能把用户分流到涂抹页或马赛克页。
- MarkupViewController 负责长图缩放、滚动和最终图片回传，但其编辑能力依赖 PencilKit，只适合自由笔迹遮挡。
- MosaicViewController 目前只有导航、预览和占位文案，没有任何真实编辑能力。

## 方案（To-be）

- **总体思路**：
  - 沿用 MarkupViewController 的长图显示与导出模型，但不复用 PencilKit。
  - MosaicViewController 内部改为一个 UIScrollView + 内容容器 + 自定义绘制画布的结构。
  - 先为原图生成一张完整的像素化版本；用户的每一笔只是在“原图”和“像素化图”之间建立一个局部混合区域。
- **模块与职责**：
  - MosaicViewController：负责页面布局、缩放、参数控制、历史栈和最终导出。
  - MosaicCanvasView：负责根据笔划集合实时绘制预览。
  - MosaicStroke：记录每一笔的点集、粗细和透明度，用于预览与导出复用。
- **数据流**：
  1. 控制器接收原始长图并计算适配屏幕宽度的 displaySize。
  2. 页面生成两份图像：底层原图预览、上层像素化预览图。
  3. 用户单指拖动时，控制器把触点从显示坐标映射回原图坐标，并生成一条 MosaicStroke。
  4. MosaicCanvasView 按笔划路径裁剪像素化预览图，实现实时局部马赛克显示。
  5. 点击完成时，控制器按同一组笔划把原图与全分辨率像素化图合成为最终长图并回传。

## 接口/数据结构变更

- MosaicViewController 继续保留：
  - init(image: UIImage)
  - onConfirm: ((UIImage) -> Void)?
- 新增内部数据结构：
  - MosaicStroke(points: [CGPoint], lineWidth: CGFloat, opacity: CGFloat)
- 新增内部视图：
  - MosaicCanvasView(previewImage: UIImage, strokes: [MosaicStroke])

## 关键算法/阈值

- 像素化算法：使用 Core Image 的 CIPixellate 生成完整像素化图。
- 默认像素块大小：18pt（基于原图坐标系），保证马赛克纹理足够明显但不过度糊成大块。
- 笔刷粗细：提供 10pt 到 100pt 的调节范围（基于适配宽度后的显示坐标），录入时再换算回原图坐标。
- 透明度：提供 0.2 到 1.0 的调节范围，默认值为 1.0，用于控制像素化图层和原图的混合强度。
- 缩放：复用 Markup 页的最小/最大缩放策略，默认适配宽度并允许局部放大精修。
- 滚动手势：单指绘制，双指滚动/拖拽，双击在适配宽度和局部放大之间切换。

## 兼容性与迁移

- 不涉及历史数据迁移。
- 输入输出接口保持不变，主页无需改动即可接收马赛克结果图。

## 可观测性

- 本次不新增长期调试日志，避免再次把编辑页诊断输出留在运行时。

## 回滚策略

- 若性能或坐标映射存在不可接受问题，可直接恢复到占位页版本。
- 入口与主页回调无需回滚，仍然保持 MarkupEntryViewController 作为中间页。