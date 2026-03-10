# 修复购买无响应的设计方案

## 模块变更
修改 `ViewController.swift` 的 `requestPurchaseAndSave()` 方法。

## 接口变更
无外部接口变更。

## 数据流/执行逻辑变更
**原逻辑**：
```swift
present(loadingAlert, animated: true) {
    PurchaseManager.shared.requestPurchase { ... }
}
```
当该方法在另一个 `UIAlertController` (即点击“去解锁”）的 action block 内部调用时，当前的视图控制器（`self`）仍可能处于 `dismiss` 其他 controller 的状态。此状态下 `present` 调用有极大可能被忽略或报警告 `Warning: Attempt to present ... on ... whose view is not in the window hierarchy!` 等。由于 `present` 没有真正成功，其 `completion` 回调也不会执行，从而导致支付请求死锁，毫无反应。

**新逻辑**：
解耦 UI 展示与实际的业务逻辑请求：
```swift
PurchaseManager.shared.requestPurchase { ... }
present(loadingAlert, animated: true, completion: nil)
```
或者，使用 `DispatchQueue.main.async` 延后执行以保证动画完全完成（这里更推荐把业务逻辑提到 completion block 外）。由于 `PurchaseManager` 是单例且维护独立的状态请求，提前调用完全没问题。

## 回滚方案
恢复 `ViewController.swift` 中 `present` 与 block 的嵌套结构即可。
