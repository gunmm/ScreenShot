# Design: 修复开始录制按钮布局

## 方案设计

- `recordContainer` 的宽度约束从 `equalToConstant: 160` 改为 `greaterThanOrEqualToConstant: 160`。
- 添加 `recordingLabel` 的 trailing 约束与 `recordContainer` 绑定：`recordingLabel.trailingAnchor.constraint(equalTo: recordContainer.trailingAnchor, constant: -16)`。

通过使用大于等于的约束，保证了录制按钮有一个友好的最小点击区域；而当文本内容需要空间时，它会自动扩展其宽度。

## 回滚方案
如果该约束改变导致其他意外的排版问题，可通过撤销针对 `recordContainer` 宽度及 `recordingLabel` 右边距约束的这次修改进行回滚。
