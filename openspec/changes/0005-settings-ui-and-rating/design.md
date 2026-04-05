# 设计方案 (Design)

## 变更模块
1. `SettingsViewController.swift`
   - 重构 `setupUI()` 和 `addPremiumButton()` 的约束。
   - 添加 `reviewButton`。
   - 添加 `tipButton` 并修改它的 action 跳转 `TipViewController()`。
   - 优化 LayoutConstraints，使次要操作位于左下角，主要操作居中垂直排列。
2. `ViewController.swift`
   - 在 `image(_:didFinishSavingWithError:contextInfo:)` 函数中成功后的弹窗完成闭包里，插入好评判断逻辑。
   - 提供一个 `showReviewPromptIfNeeded()` 私有辅助函数以确保代码清晰。

## 核心实现
**Settings UI 布局更新**:
```swift
// 左下角按钮的布局
NSLayoutConstraint.activate([
    premiumButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
    premiumButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

    restoreButton.leadingAnchor.constraint(equalTo: premiumButton.leadingAnchor),
    restoreButton.bottomAnchor.constraint(equalTo: premiumButton.topAnchor, constant: -16),
])
```
可以引入 `UIStackView` 在 `view.centerXAnchor` 居中展示：好评、打赏、反馈，设置合适的 `spacing`。

**弹窗逻辑更新**:
为了避免在前面的弹窗没完全 dismiss 时直接 present 报错（比如虽然是按钮 handler 但有时动画未完），比较安全的做法是在 UIAlertAction 内部确保进行异步展示。如果在前一个 alert 消失完毕后再弹：
```swift
alert.addAction(UIAlertAction(title: NSLocalizedString("确定", comment: "OK action"), style: .default, handler: { [weak self] _ in
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        self?.showReviewPromptIfNeeded()
    }
}))
```

**好评URL**:
`URL(string: "https://apps.apple.com/app/id6759634662?action=write-review")` 可以在 App Store App 中直接调出该应用的评价弹窗。

## 数据流管理
状态标志：使用 `UserDefaults.standard` 中的 `hasReviewed` key 进行本地持久化，没有服务端同步需求。一旦设置为 `true`，设备全生命周期内不再弹出（或直到重装）。

## 回滚方案
如果好评跳转链接失效，更新 App 版本的常量字符串即可或者暂时由远程配置决定。目前暂直接写死，若有需要则采用 PR 回退该特性。
