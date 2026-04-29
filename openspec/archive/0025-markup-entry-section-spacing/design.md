# Design: 编辑方式列表项增加分组间距

## 现状（As-is）

- MarkupEntryViewController 当前使用 UITableView 的单 section 多 row 结构。
- 在 insetGrouped 风格下，同一 section 内的 row 会连成一组显示，因此各入口项贴在一起。

## 方案（To-be）

- **总体思路**：
  - 保持 UITableView 列表方案不变。
  - 将数据源从“单 section 多 row”调整为“多 section 单 row”。
  - 借助 insetGrouped 的分组间距，自然拉开每个入口项之间的垂直距离。

## 数据流

1. table view 的 section 数量等于入口项数量。
2. 每个 section 只渲染一个入口 cell。
3. 点击某个 section 的 cell 后，进入对应编辑页。

## 接口/数据结构变更

- 无需新增数据结构。
- 仅调整 UITableViewDataSource 的 section/row 映射方式。

## 关键算法/阈值

- 不涉及算法。

## 兼容性与迁移

- 不涉及数据迁移。

## 可观测性

- 不新增日志。

## 回滚策略

- 恢复 numberOfSections / numberOfRowsInSection 为单 section 模式。
