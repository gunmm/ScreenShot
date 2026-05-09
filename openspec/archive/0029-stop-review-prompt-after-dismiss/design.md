# Design: 拒绝评分邀请后不再重复弹窗

## 现状（As-is）

- `ViewController.showReviewPromptIfNeeded()` 仅检查 `hasReviewed`。
- 用户点击“去给好评”时会写入 `hasReviewed = true`。
- 用户点击取消动作时不会写入任何状态，因此每次保存成功后都会再次进入评分邀请。

## 方案（To-be）

- **总体思路**：
  - 为评分邀请增加一个单独的拒绝状态 `hasDismissedReviewPrompt`。
  - 只要用户已经评价或已经明确拒绝，保存成功后都不再展示评分邀请。
  - 将取消按钮文案改为“不再提示”，使行为与文案一致。
- **模块与职责**：
  - `ViewController.swift`：统一读取和写入评分邀请状态，并更新弹窗按钮逻辑。
  - `Localizable.strings`：同步更新中文与英文按钮文案。
- **数据流**（步骤描述）：
  1. 保存成功后，点击成功弹窗“确定”。
  2. `showReviewPromptIfNeeded()` 读取 `hasReviewed` 与 `hasDismissedReviewPrompt`。
  3. 若任一状态为 `true`，直接返回，不展示评分邀请。
  4. 若都为 `false`，展示评分邀请。
  5. 用户点击“不再提示”时写入 `hasDismissedReviewPrompt = true`。
  6. 用户点击“去给好评”时写入 `hasReviewed = true`，然后跳转 App Store。

## 接口/数据结构变更

- 新增 `UserDefaults` 键：`hasDismissedReviewPrompt`
- 新增评分邀请状态辅助判断，避免散落的硬编码 key。

## 关键算法/阈值

- 无新增算法与阈值；本次只做布尔状态扩展。

## 兼容性与迁移

- 老版本已存在的 `hasReviewed` 状态继续生效。
- 新增的 `hasDismissedReviewPrompt` 默认值为 `false`，无数据迁移成本。

## 可观测性

- 暂不新增日志；该逻辑足够局部，可通过手工保存流程验证。

## 回滚策略

- 删除 `hasDismissedReviewPrompt` 的判断与写入，并恢复原按钮文案即可。
