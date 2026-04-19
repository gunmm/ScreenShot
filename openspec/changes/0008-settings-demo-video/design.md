# Design: 设置页「使用演示」

## 方案

- 在 `SettingsViewController` 中新增 `demoVideoButton`（`UIButton`，`.system`），样式与「⭐️ 好评」「❤️ 打赏」「💬 反馈与求助」一致（18pt medium）。
- 将 `UIStackView` 的 `arrangedSubviews` 从 `[reviewButton, tipButton, feedbackButton]` 扩展为包含 `demoVideoButton`，保证顺序为反馈在上、演示在下。
- 点击处理：`guard let url = URL(string: …) else { return }; UIApplication.shared.open(url)`，与 `reviewButtonTapped` 模式一致。
- MP4 地址：类内 `private static let usageDemoVideoURLString`，便于替换为产品 CDN；首版可使用公开可访问的短样片 URL 保证联调可播放，发布前替换为正式链接（在 `proposal.md` 已说明风险）。

## 本地化

- 使用 `NSLocalizedString("🎬 使用演示", comment: …)`（或不含 emoji 的纯文案键，与现有「⭐️ 好评」风格一致），在 `zh-Hans` / `en` / `Base` 的 `Localizable.strings` 中补充条目。

## 回滚

- 移除按钮、stack 子视图、URL 常量及相关 `.strings` 键。
