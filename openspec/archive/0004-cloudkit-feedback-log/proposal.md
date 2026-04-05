# Proposal: 侧云结合的用户反馈支持

## 背景 / 动机

- 我们遭遇了线上用户端突发的各种错误，且无自己的后端进行日志记录和回放。
- 通过集成 Apple 提供的 CloudKit，搭配本地文件日志收集功能，可以在零后端架构下支持详尽的用户排障报告并进行云端追踪。

## 目标（Goals）

- G1: 用户可在设置中自发上报带文字问题的反馈。
- G2: App 能在本地悄无声息地记录重要生命周期或异常信息，随反馈一并由 CloudKit 上传至 Public DB。

## 范围（Scope）

- **会改的部分**：
  - 新增 `AppLogger`
  - 新增 `CloudKitManager`
  - 接入 `FeedbackViewController` 并在 `SettingsViewController` 露出入口
- **不会改的部分**：
  - CloudKit 未成功前不会重写长截图主流程的异常流。

## 验收标准（Acceptance Criteria）

- AC1: 日志系统不仅能在 Xcode 控制台打印信息，也要在本地写文件。
- AC2: 在 CloudKit 的 Public Database 中成功看到上传到的信息与 Log `CKAsset`。
