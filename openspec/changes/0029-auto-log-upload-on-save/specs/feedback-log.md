# Specs: feedback-log

## 变更主题：保存成功后的自动日志上传

### 场景

当前系统只支持用户主动提交反馈时上传日志，缺少针对保存成功链路的低频自动排障样本。产品希望在不打扰用户的前提下，为保存成功事件增加静默日志上传能力，同时控制 CloudKit 上传频率。

### 要求

- 系统必须在用户成功保存长截图后异步检查是否需要自动上传日志。
- 自动上传不得影响现有保存成功提示、评分弹窗和主线程交互。
- 自动上传必须写入新的 CloudKit record type：`AutoLogUpload`。
- `AutoLogUpload` 的字段必须与 `UserFeedback` 一致，至少包含 `message`、`deviceModel`、`systemVersion`、`appVersion`、`buildVersion`、`userId`、`logFile`。
- 系统必须使用本地持久化时间戳限制自动上传频率：距离上次成功自动上传时间未满 24 小时，则跳过本次上传。
- 自动上传必须使用日志文件快照，而不是直接引用正在写入的原始日志文件。
- 自动上传失败时，系统只允许记录本地日志，不得向用户弹错或打断保存结果确认。

### 验收

- 首次满足条件的保存成功后，CloudKit Public Database 中会新增一条 `AutoLogUpload` 记录。
- 同一设备在 24 小时内连续多次保存成功时，最多只会新增一条 `AutoLogUpload` 记录。
- `AutoLogUpload` 和 `UserFeedback` 的字段集合保持一致，能够使用相同维度进行排障检索。
- 自动上传失败不会改变用户看到的保存成功体验。