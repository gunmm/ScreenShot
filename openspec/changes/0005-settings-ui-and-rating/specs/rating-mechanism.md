# App Rating and Settings UI

## 用户故事
作为应用用户，我希望在设置页面明确且清晰地看到所有可以互动的核心选项，例如给开发者打分、打赏以及提交反馈。我也不希望被重要性较低的购票恢复入口干扰视线。此外，作为开发者，我希望在用户成功获取关键价值（保存长截图）后适时地邀请用户评价，如果用户评价过则不应该再打扰。

## 规格与边界条件
1. **设置页面布局更新 (SettingsViewController)**
   - “恢复购买” 和 “放弃免费使用时间” (Premium/Restore buttons) 的布局约束应独立于中心组件。将其从居中布局改为页面左下角对齐。
   - 新增三个主要操作组：“好评”、“打赏”、“反馈”。这三个组件应该使用 StackView 或单独的等间距布局排列在屏幕居中的适当位置，符合常规的 iOS 页面层级结构。
2. **打赏跳转 (TipViewController)**
   - 应用内部需要提供原生的 TipViewController 触发路径，通过以 NavigationController push 或是 present 方式将其调起。
3. **好评链接跳转**
   - 必须通过 `UIApplication.shared.open` 进行外部 App Store 跳转。URL为 `https://apps.apple.com/app/id6759634662?action=write-review`。
4. **弹窗好评逻辑 (ViewController)**
   - 在用户点击 `保存记录` 到相册并且成功后，会看到保存成功弹窗。
   - 捕捉这一个 UIAlertController 的 OK Action 执行闭包。
   - 判断 `UserDefaults.standard.bool(forKey: "hasReviewed")`，如果为 false，则新弹出一个评分邀请 UIAlertController。
   - 邀请包含两个 Action: 以后再说（不写入 hasReviewed 状态或稍后再问）；去好评（跳转 App Store，并将 hasReviewed 置为 true 以防再次弹出）。

## 交互验收
- “恢复购买”和“重置过期”按键能够成功点按，且位于屏幕左下角区域。
- 其它3个主按钮垂直排列，居中显示，具有辨识度（可重用 `systemFont`, `tintColor` 但增加适当 size 或图标区分）。
- 保存图像成功弹窗消失后，如果满足未评价条件，出现新的评价提示。
