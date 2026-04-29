# Design: 编辑方式中间页列表化与滑动操作

## 现状（As-is）

- MarkupEntryViewController 使用两个硬编码 UIButton 作为入口。
- 页面布局围绕静态按钮设计，不具备列表扩展能力。
- 当前没有任何数据结构承载“编辑方式入口”本身，也没有滑动操作。

## 方案（To-be）

- **总体思路**：
  - 用 UITableView 替换静态按钮栈，把编辑方式入口抽象成数据模型数组。
  - 每个入口项包含标题、副标题、图标、强调色和目标页面类型。
  - 页面从顶部向下展示列表，点击 cell 进入对应编辑页。
  - 通过 table view 的 leading/trailing swipe actions 暴露编辑与删除入口。

- **模块与职责**：
  - MarkupEntryViewController：维护入口数组、渲染列表、处理点击与滑动操作。
  - Entry 数据模型：描述单个入口项的展示信息和目标页面。
  - UITableViewCell：使用系统列表内容配置，避免手工堆复杂按钮视图。

## 数据流

1. 页面加载时，MarkupEntryViewController 初始化默认入口数组（涂抹、马赛克）。
2. table view 根据入口数组渲染列表。
3. 点击某一项时，根据目标类型 push 对应控制器。
4. 滑动“编辑”时弹出 alert，允许修改标题和副标题，并刷新对应行。
5. 滑动“删除”时从入口数组中移除该项并刷新列表；若数组为空则显示空状态。

## 接口/数据结构变更

- MarkupEntryViewController 新增私有 Entry 结构：
  - id
  - title
  - subtitle
  - iconName
  - accentColor
  - destination
- 新增空状态 label 或 background view，用于无条目时提示。

## 关键算法/阈值

- 本次不涉及复杂算法。
- 列表项高度使用 UITableView.automaticDimension，避免再次出现副标题被裁切问题。

## 兼容性与迁移

- 当前列表项编辑和删除仅在运行时生效，不做持久化迁移。
- 未来新增入口时，只需增加一条数据模型配置。

## 可观测性

- 本次不新增调试日志。

## 回滚策略

- 恢复旧版 UIButton 栈布局。
- 移除 Entry 数据模型和 swipe actions。
