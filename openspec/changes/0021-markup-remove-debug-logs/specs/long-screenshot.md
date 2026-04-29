# Specs: long-screenshot

## 新增需求：移除 Markup 编辑页调试日志

### 场景
Markup 编辑页的底图与画布几何同步已经稳定，开发期用于观察缩放与滚动状态的 [Markup] 调试日志不再需要继续保留。

### 要求

- Markup 编辑页不应继续输出带有 [Markup] 前缀的调试日志。
- 仅用于这些日志的内部辅助方法、计数器和调用语句应一并清理。
- 删除日志后，Markup 编辑页的缩放、滚动、双击放大和导出行为必须保持不变。

### 验收

- 在代码中搜索 [Markup] 时，不应再命中 MarkupViewController 的日志输出。
- MarkupViewController 不应保留只为日志存在的遗留辅助代码。
