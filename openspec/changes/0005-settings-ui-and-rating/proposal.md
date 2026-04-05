# Settings UI Refresh and Rating Mechanism

## 动机 (Motivation)
目前 `SettingsViewController` 中的按钮排布不够清晰，重要操作聚集在一起可能导致误触。同时，应用缺少吸引用户给好评的机制，不利于应用在 App Store 上的表现。

## 范围 (Scope)
1. 调整 `SettingsViewController` 页面布局，将“恢复购买”和“放弃免费使用时间”按钮移至页面左下角。
2. 在 `SettingsViewController` 页面中央部分，从上到下依次展示三个按钮：
   - 给个好评（跳转 App Store，Apple ID: 6759634662）
   - 打赏（跳转至 `TipViewController`）
   - 用户反馈与求助（保持跳转 `FeedbackViewController`不变）
3. 在 `ViewController` 中的长截图保存成功回调弹窗的“确认”部分，增加一个评分弹窗拦截逻辑。如果用户此前未评价，则在点击确认后弹出求好评的提示，点击好评会跳转至同样的 App Store 链接，并记录已评价标记以防打扰。

## 非目标 (Non-Goals)
- 更改现有打赏业务逻辑或页面UI。
- 修改长截图生成或拼接核心算法。

## 验收标准 (Acceptance Criteria)
1. **界面布局**：进入“设置”页面后，底角有原有红蓝管理按钮，中间有排列整齐的“好评”、“打赏”、“反馈”按钮。
2. **打赏跳转**：点击“打赏”能够展示打赏详情页 `TipViewController`。
3. **好评跳转**：点击“给个好评”能够调用 `UIApplication.shared.open` 打开正确包含 `id6759634662` 的 App Store 链接。
4. **保存结束评分**：在保存相册成功，点击成功弹窗里的“确定”后，如果用户是首次评价，则弹窗询问是否给好评；去好评或拒绝均记录至 `UserDefaults` 避免重复弹窗。

## 风险 (Risks)
- 在 UIAlertController 回调里立即弹出另一个 UIAlertController，可能会遇到 UI 视图层级或展示不及时的问题（需使用 DispatchQueue.main.async 延时或在 dismiss completion 中弹窗）。
