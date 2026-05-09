# Tasks: 拒绝评分邀请后不再重复弹窗

> 规则：任务必须**可执行、可验证、可按顺序完成**。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（`openspec/changes/.../specs/`）
- [x] 更新技术方案（`design.md`）
- [x] 实现代码（`ViewController.swift` 与本地化文案）
- [ ] 自测（手工步骤 + 预期结果）
- [x] 同步主规格（`openspec/specs/`）
- [x] 归档（移动到 `openspec/archive/`）

## 自测步骤（手工）

- [ ] Step 1: 清理本地 `hasReviewed` 与 `hasDismissedReviewPrompt`，完成一次保存，确认弹出评分邀请。
- [ ] Step 2: 点击“不再提示”，再次完成保存，确认不再弹出评分邀请。
- [ ] Step 3: 清理状态后再次完成保存，点击“去给好评”，确认跳转 App Store 且后续不再弹出。
