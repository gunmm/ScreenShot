# 修复 iOS 购买流程在弹出层后无响应的问题

## 动机
在 `ViewController.swift` 中，点击试用过期提示的“去解锁”按钮后，App 在某些设备（如 iPad Air M3）上停留在当前页面，没有任何响应，没有触发苹果的支付流程。

## 范围
- 修复 `ViewController.swift` 中 `requestPurchaseAndSave` 方法。
- 确保调用 `PurchaseManager.shared.requestPurchase` 不会因为 `UIAlertController` 的展示逻辑而被阻塞或忽略。

## 非目标
- 不修改 `PurchaseManager` 的核心逻辑。
- 不修改其他支付页面（如 `SettingsViewController`）。

## 验收标准
- 点击“去解锁”后，必须能够弹出请求支付的 loading 提示（如果适用），并可靠地调起 Apple 的支付弹窗（或失败提示）。
- 测试：在真实的 iPad 设备上可以触发购买流程。

## 风险
- `UIAlertController` 的展示/消失过程可能引起界面层级混乱，需要使用 `DispatchQueue.main.async` 或调整 `present` 的完成块来避免。
