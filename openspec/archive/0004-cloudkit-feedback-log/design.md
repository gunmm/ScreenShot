# Design: CloudKit 反馈与日志上传系统

## 架构说明

1. **日志拦截与文件持久化**：
   - 现存的所有 `print` 指令存在阅后即焚问题。我们设计单例 `AppLogger`，在其 `log(_ msg: String)` 接口中，获取应用的 Document 目录，以 Append 模式将信息写入 `app_activity.log` 中。
   - 文件写入时将带上基础时间戳。

2. **CloudKit 存储数据结构**：
   - CloudKit 是基于 Schema-on-read 的机制。开发环境 (Development Sandbox) 中可以直接上传任意新建字典结构的 `CKRecord`。
   - `RecordType`: `"UserFeedback"`。
   - `Fields`:
     - `message` (String 型) - 来自 TextBox。
     - `deviceModel` (String 型) - 用于区分设别。
     - `logFile` (CKAsset 型) - 指向本地的 `app_activity.log` URL 包装对象自动实现大文件上传。

3. **同步性与主界面集成**：
   - UI：在 `SettingsViewController` 中加入按钮弹出反馈窗口使用 UIKit `UITextView` 绘制基本框。提交过程中锁死 UI 并转菊花，等待 `CloudKitManager` Callback。

## 风险

- **风险**：如果 iCloud 长期未开启，或由于没网会导致无上传。我们在反馈页面处理上传失败，并给用户弹框。
