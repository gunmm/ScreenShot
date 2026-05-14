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
依托 Apple iCloud 默认机制配置了 Public Database，应用侧将创建两类 `CKRecord`：
- `UserFeedback`：用户主动提交反馈时写入。
- `AutoLogUpload`：用户保存长截图成功后，满足限流条件时静默写入。
- `AppLaunchEvent`：应用每次启动时异步写入的轻量启动记录。

两类记录共享以下字段：
- `message (String)`：用户反馈的具体需求（必填）。
- `deviceModel (String)`：抓取的 `UIDevice` 实体型号。
- `systemVersion (String)`：如 `iOS 17.1`，便于复现设备异常。
- `appVersion (String)`：应用版本号。
- `buildVersion (String)`：构建号。
- `userId (String)`：当前设备的 `identifierForVendor`。
- `logFile (CKAsset)`：封装 `AppLogger` 输出文件的 URL，将几十KB至兆级信息一次性高速上抛。

#### 启动埋点记录（0030）
应用在 `didFinishLaunchingWithOptions` 阶段必须异步写入一条 `AppLaunchEvent` 记录，用于补充启动维度的基础运行样本。该记录至少包含：
- `userId (String)`
- `appVersion (String)`
- `isPaid (Bool/NSNumber)`
- `regionCode (String)`
- `launchedAt (Date)`

实现上可以额外附带 `buildVersion`、`systemVersion`、`deviceModel`，但启动记录失败时只允许写本地日志，不得阻塞应用启动或向用户弹错。

#### 自动上传限流（0029）
保存成功后可触发一次静默自动日志上传，但系统必须使用本地持久化时间戳限流：**距离上次成功自动上传时间大于等于 24 小时** 才允许再次写入 `AutoLogUpload`。自动上传失败不得影响用户看到的保存成功提示。

#### 日志快照上传（0029）
自动上传不得直接引用正在写入中的原始日志文件，而应先复制出一份临时日志快照，再以该快照创建 `CKAsset`，上传完成后清理临时文件。

#### 注意事项
在开发者机器使用此功能及首次打包给用户前，`必须在 Xcode 的 Signing & Capability 中配置 CloudKit Container`，否则 CloudKitManager 将直接保存失败。

### 3. 用户交互 (`FeedbackViewController` -> `SettingsViewController`)
`Settings` 底部展示了“用户反馈与求助”入口，该窗口包含标准的 `UITextView` 及提交拦截判断，不强制要求特殊授权。所有提交基于隐式的系统网络代理及 iCloud Token 支持。

#### 提交失败重试（0006）
上传失败后，错误 Alert 包含两个选项：
- **重试**：直接再次触发提交逻辑，重新发起 CloudKit 上传。
- **取消**：关闭 Alert，用户停留在反馈页，输入内容保留，可随时再次点击"提交"。
