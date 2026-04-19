# 设置页（SettingsViewController）

## 布局

- 导航栏：标题「设置」，左侧关闭。
- 中央竖排（自上而下）：好评（跳转 App Store 评价）、打赏（`TipViewController`）、反馈与求助（`FeedbackViewController`）、**使用演示**（在系统浏览器中打开配置的演示视频页，如哔哩哔哩短链）。
- 左下角：恢复购买、放弃免费试用（红色）。

## 使用演示

- 入口文案经本地化（如中文「🎬 使用演示」）。
- 演示地址为代码内可替换的 HTTPS 链接；点击使用 `UIApplication.shared.open`。
