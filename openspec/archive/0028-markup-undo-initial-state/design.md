# Design: Markup 撤销按钮初始状态修复

## 现状（As-is）

- MarkupViewController 在 setupNavigationBar 中直接创建撤销、重做按钮，并挂到 navigationItem.rightBarButtonItems。
- 当前实现没有保存按钮引用，也没有在 viewDidLoad、viewDidAppear 或绘制变化回调里同步按钮状态。
- canvasViewDrawingDidChange 目前为空实现，因此 PencilKit 画布状态变化不会反馈到导航按钮。

## 方案（To-be）

- 总体思路：
  - 为撤销、重做按钮保留实例引用。
  - 新增一个集中方法，根据 canvasView.undoManager 的 canUndo/canRedo 刷新按钮状态。
  - 在页面初始化完成后执行首次刷新，并在绘制变化、撤销、重做操作后再次刷新。
- 模块与职责：
  - MarkupViewController：负责读取 PencilKit 撤销栈能力并驱动导航按钮启用状态。
- 数据流：
  1. 页面加载完成，创建按钮并立即调用状态同步。
  2. 用户绘制后，PencilKit 触发 canvasViewDrawingDidChange，控制器刷新按钮状态。
  3. 用户点击撤销或重做，执行 undo/redo 后再次刷新按钮状态。

## 接口/数据结构变更

- MarkupViewController 新增私有属性：undoItem、redoItem。
- MarkupViewController 新增私有方法：updateActionItems()。

## 关键算法/阈值

- 无新增算法；直接使用系统 undoManager 的 canUndo、canRedo 作为单一真相来源。

## 兼容性与迁移

- 无数据迁移。
- 与现有 PencilKit 画布数据结构兼容。

## 可观测性

- 不新增日志；状态变更由 UI 行为直接可观察。

## 回滚策略

- 删除 updateActionItems 及其调用点，恢复为现状实现。
