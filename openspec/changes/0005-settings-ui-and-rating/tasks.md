# Tasks

- [ ] 在 `SettingsViewController.swift` 中重新布置 `setupUI` 与视图约束：
  - [ ] 将 `premiumButton` 和 `restoreButton` 设置为根据 `safeAreaLayoutGuide.bottomAnchor` 和 `safeAreaLayoutGuide.leadingAnchor` 布局的相对位置。
  - [ ] 新建 `reviewButton` 配置（点击调用 `UIApplication.shared.open` 访问 `https://apps.apple.com/app/id6759634662?action=write-review`）。
  - [ ] 新建 `tipButton` 配置（点击打开 `TipViewController()`）。
  - [ ] 创建中心内容 `UIStackView`，从上到下按顺序添入：`reviewButton`, `tipButton`, `feedbackButton`。
  - [ ] 更新相应的 NSLayoutConstraints 以呈现新布局。
- [ ] 在 `ViewController.swift` 中拦截相册保存成功的回调：
  - [ ] 找到 `self.present(alert, animated: true)` 中的 “确定” 按钮逻辑。
  - [ ] 利用处理回调判断 `hasReviewed`，按需展示 `showReviewPromptIfNeeded()`。
  - [ ] 实现 `showReviewPromptIfNeeded()`，添加 "给个好评" 与 "以后再说" 两项逻辑。如果用户去了好评，写入 `hasReviewed=true` 到 `UserDefaults` 并跳转外部链接。
