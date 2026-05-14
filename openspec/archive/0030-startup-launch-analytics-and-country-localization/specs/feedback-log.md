# Spec Delta: 用户反馈与云端排障

## 新增需求：启动记录上报

### 用户故事
作为开发者，我希望应用每次启动时都能向 CloudKit 写入一条轻量启动记录，以便了解安装分布和基础运行状态。

### 验收规则
1. 系统必须在应用启动阶段异步创建一条新的 CloudKit 记录，record type 为 `AppLaunchEvent`。
2. `AppLaunchEvent` 至少包含以下字段：
   - `userId (String)`
   - `appVersion (String)`
   - `isPaid (Int64/NSNumber Bool)`
   - `regionCode (String)`
   - `launchedAt (Date)`
3. 系统可以额外携带 `buildVersion`、`systemVersion`、`deviceModel` 等辅助字段，但不得缺少上述必填字段。
4. 启动记录上传必须在后台异步执行，不得阻塞首屏展示。
5. 启动记录上传失败时，系统只允许写本地日志，不得对用户展示失败提示。

### 边界条件
- 当 `identifierForVendor` 为空时，`userId` 使用 `Unknown` 兜底。
- 当地区码无法识别时，`regionCode` 使用 `UNSPECIFIED` 或当前系统可获取值的安全兜底字符串。
- 当 CloudKit 容器未配置或网络失败时，记录写入失败不得导致应用崩溃。
