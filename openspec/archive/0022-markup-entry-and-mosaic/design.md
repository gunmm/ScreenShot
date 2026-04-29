# Design: 编辑方式中间页与马赛克页骨架

## 现状（As-is）

- 主页在 ViewController.markupResult() 中直接创建 MarkupViewController，并通过 UINavigationController 全屏 present。
- MarkupViewController 默认把自己视为模态页根控制器，左上角固定显示“取消”，完成时直接 dismiss 当前模态流程。
- 当前项目没有马赛克编辑器，也没有在“涂抹”和“马赛克”之间分流的中间交互节点。

## 方案（To-be）

- **总体思路**：
  - 将主页原本直连 MarkupViewController 的入口改为直连 MarkupEntryViewController。
  - MarkupEntryViewController 作为模态导航栈根页，负责展示编辑方式选择，并 push 到具体编辑器。
  - MarkupViewController 保持输出接口不变，但在被 push 进入时改为使用系统返回而非固定“取消”。
  - MosaicViewController 先提供与后续真实能力兼容的控制器骨架：接收图片、展示预览、提供说明，不进行图像修改。

- **模块与职责**：
  - ViewController：只负责拉起编辑流程、接收最终图片并刷新主页预览。
  - MarkupEntryViewController：中间选择页，展示入口按钮并负责 push 到具体编辑器。
  - MarkupViewController：继续负责 PencilKit 涂抹与合成导出；若位于导航栈次级页面，左侧改为系统返回。
  - MosaicViewController：马赛克能力骨架页，承载原图预览和后续真实马赛克能力的扩展点。

## 数据流

1. 主页点击“涂抹/打码”。
2. ViewController 用原始拼接图初始化 MarkupEntryViewController，并注入统一的 onConfirm 回调。
3. 中间页点击“涂抹”后 push MarkupViewController；点击“马赛克”后 push MosaicViewController。
4. MarkupViewController 完成时把新图通过 onConfirm 回传给主页，并 dismiss 整个模态导航流程。
5. MosaicViewController 当前仅展示骨架，不回传结果图。

## 接口/数据结构变更

- 新增 MarkupEntryViewController.init(image: UIImage)
- 新增 MarkupEntryViewController.onConfirm: ((UIImage) -> Void)?
- 新增 MosaicViewController.init(image: UIImage)
- 新增 MosaicViewController.onConfirm: ((UIImage) -> Void)?
- 调整 MarkupViewController 导航栏左侧按钮策略：
  - 作为模态根页时显示“取消”并 dismiss。
  - 作为 push 子页时不自定义左按钮，使用导航控制器默认返回。

## 关键算法/阈值

- 本次不涉及马赛克算法实现。
- 中间页仅调整导航流，不改变已有图片合成比例、缩放阈值和水印策略。

## 兼容性与迁移

- 不涉及历史数据迁移。
- 主页结果图状态、已涂抹标记和保存链路保持原逻辑。

## 可观测性

- 本次不新增日志；延续当前“不在 Markup 编辑页保留调试日志”的约束。

## 回滚策略

- 恢复 ViewController 直接 present MarkupViewController。
- 删除 MarkupEntryViewController 和 MosaicViewController。
