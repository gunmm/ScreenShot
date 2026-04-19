# Proposal: 设置页「使用演示」入口

## 背景 / 动机

- 新用户不清楚长截图录制与生成流程，需要一段可在外部浏览器/Safari 中直接播放的 MP4 演示视频降低学习成本。
- 设置页已有「反馈与求助」，在其下增加「使用演示」可集中承载帮助类入口。

## 目标（Goals）

- G1：在 `SettingsViewController` 中「反馈与求助」按钮下方增加「使用演示」按钮。
- G2：点击后使用系统方式打开配置的 HTTPS MP4 直链（`UIApplication.shared.open`），由系统浏览器或播放器处理。

## 非目标（Non-goals）

- 不在 App 内嵌全屏视频播放器或离线缓存演示视频。
- 不改变打赏、恢复购买、好评、反馈的既有逻辑。

## 范围（Scope）

- **会改的部分**：
  - 文件：`LongScreenShot/SettingsViewController.swift`、各语言 `Localizable.strings`。
  - 行为：新增按钮与打开 URL。
- **不会改的部分**：拼接、录制、购买、反馈提交等模块。

## 验收标准（Acceptance Criteria）

- AC1：设置页中央竖排按钮顺序为：好评 → 打赏 → 反馈与求助 → **使用演示**（最后一项在反馈下方）。
- AC2：点击「使用演示」后调用 `UIApplication.shared.open` 打开可配置的 MP4 HTTPS 地址；若 URL 无效则静默失败或不做崩溃（与现有好评按钮一致的可选校验）。

## 风险与回滚

- **风险**：演示直链失效或域名变更时需改代码或后续改为可配置。
- **回滚**：删除新增按钮、本地化键与 OpenSpec 条目即可。
