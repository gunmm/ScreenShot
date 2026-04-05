# 用户反馈与云端排障 (Feedback & Logging)

## 业务场景

这套零后端机制支持向 CloudKit Public Database 直接进行文本和文件投递，以方便开发者进行云端溯源。包含：
1. **本地日志埋点打底** (`AppLogger`)。
2. **文字附日志云端上报** (`CloudKitManager`)。

## 架构组成

### 1. 本地落盘机制 (`AppLogger.swift`)
替代原有直接向 Console 输入 `print`，使用支持多线程非阻塞队列写入文本的日志单例。
日志上限通过基础生命周期设限为大概 **1MB**，防止由于时间久远胀破沙盒用户磁盘。 
生成的所在目录为：`Documents/app_activity.log`。

### 2. 云端结构 (`CloudKitManager.swift`)
依托 Apple iCloud 默认机制配置了 Public Database，应用侧将创建 `CKRecord` `(UserFeedback)`：
- `message (String)`：用户反馈的具体需求（必填）。
- `deviceModel (String)`：抓取的 `UIDevice` 实体型号。
- `systemVersion (String)`：如 `iOS 17.1`，便于复现设备异常。
- `logFile (CKAsset)`：封装 `AppLogger` 输出文件的 URL，将几十KB至兆级信息一次性高速上抛。

#### 注意事项
在开发者机器使用此功能及首次打包给用户前，`必须在 Xcode 的 Signing & Capability 中配置 CloudKit Container`，否则 CloudKitManager 将直接保存失败。

### 3. 用户交互 (`FeedbackViewController` -> `SettingsViewController`)
`Settings` 底部展示了“用户反馈与求助”入口，该窗口包含标准的 `UITextView` 及提交拦截判断，不强制要求特殊授权。所有提交基于隐式的系统网络代理及 iCloud Token 支持。

#### 提交失败重试（0006）
上传失败后，错误 Alert 包含两个选项：
- **重试**：直接再次触发提交逻辑，重新发起 CloudKit 上传。
- **取消**：关闭 Alert，用户停留在反馈页，输入内容保留，可随时再次点击"提交"。
