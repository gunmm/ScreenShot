# Design: 编辑方式列表项统一高度

## 现状（As-is）

- MarkupEntryViewController 当前使用 UITableView.automaticDimension。
- 由于副标题字数不同，不同入口项的 cell 高度不一致。

## 方案（To-be）

- **总体思路**：
  - 将 tableView.rowHeight 改为固定值。
  - 将副标题显示限制为单行，必要时尾部截断。
  - 保持每项单独 section 的分组间距结构不变。

## 数据流

1. table view 继续按 section 渲染入口项。
2. 每个 cell 采用统一固定高度展示。
3. 点击 cell 后进入对应编辑页。

## 接口/数据结构变更

- 无新增数据结构。
- 仅调整 UITableView 和 UIListContentConfiguration 的展示参数。

## 关键算法/阈值

- 固定高度采用单一常量，确保所有入口项一致。

## 兼容性与迁移

- 不涉及数据迁移。

## 可观测性

- 不新增日志。

## 回滚策略

- 恢复 automaticDimension 与多行副标题设置。
