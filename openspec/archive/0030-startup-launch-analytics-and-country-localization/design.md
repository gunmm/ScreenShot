# Design: 启动埋点与国家语言适配

## 现状（As-is）

- `AppDelegate` 当前未在启动阶段执行任何 CloudKit 记录写入。
- `CloudKitManager` 只支持 `UserFeedback` 与 `AutoLogUpload` 两类记录，不包含独立的启动埋点模型。
- 多语言资源只有 `en.lproj` 和 `zh-Hans.lproj`，且 `TipViewController`、`PurchaseManager` 等页面仍存在直接写死的中文用户文案。
- 当前 `NSLocalizedString` 依赖系统首选语言，无法按国家地区码强制映射到美国、日本、韩国、中国四种语言策略。

## 方案（To-be）

- **总体思路**：
  - 在 `didFinishLaunchingWithOptions` 中先安装地区语言选择逻辑，再异步触发一次启动记录上传。
  - 为 CloudKit 增加独立 `AppLaunchEvent` 记录类型，用专门的 record builder 写入启动字段。
  - 新增 `AppLanguageManager`，按地区码选择语言 bundle，并通过 `Bundle` 本地化入口拦截让现有 `NSLocalizedString` 自动走选定语言。
  - 将仍写死的核心用户文案迁移到 `Localizable.strings`，补齐 `ja.lproj` 与 `ko.lproj`。

- **模块与职责**：
  - `AppDelegate`：安装语言覆盖逻辑，触发启动记录上传。
  - `AppLanguageManager`：解析地区码、选择支持语言、安装 bundle 本地化拦截。
  - `CloudKitManager`：构建并保存 `AppLaunchEvent` 记录。
  - `PurchaseManager` / `TipViewController` / `SettingsViewController`：把硬编码文案改为本地化 key。

- **数据流**：
  1. App 启动进入 `didFinishLaunchingWithOptions`。
  2. `AppLanguageManager.install()` 读取 `Locale.current.region` 并确定语言代码。
  3. 主 bundle 后续通过拦截逻辑优先从选定语言 bundle 返回本地化文案。
  4. `CloudKitManager.uploadLaunchEvent()` 异步读取 `identifierForVendor`、版本号、付费状态、地区码、当前时间。
  5. 生成 `CKRecord(recordType: "AppLaunchEvent")` 并写入 Public Database。
  6. 失败只记录 `AppLogger`，不反馈到 UI。

## 接口/数据结构变更

- `CloudKitManager`
  - 新增 `uploadLaunchEvent()`。
  - 新增 `makeLaunchEventRecord()`，字段：
    - `userId: String`
    - `appVersion: String`
    - `isPaid: Int64` 或 `NSNumber(Bool)`
    - `regionCode: String`
    - `launchedAt: Date`
- `AppLanguageManager`
  - 新增 `install()`。
  - 新增地区到语言的映射规则：`US -> en`、`JP -> ja`、`KR -> ko`、`CN -> zh-Hans`。
  - 非映射地区回退到 `Bundle.main.preferredLocalizations.first`，若不在支持列表则回退 `en`。

## 关键算法/阈值

- 语言选择优先级：显式地区映射 > 系统首选语言中已支持语言 > 英文兜底。
- 记录上传使用现有 `workQueue` 异步执行，不增加重试和持久化队列。

## 兼容性与迁移

- 老版本不会生成 `AppLaunchEvent`，无需迁移旧数据。
- 新增 `ja.lproj`、`ko.lproj` 后需确保项目 `knownRegions` 包含对应语言，避免 Xcode 资源识别不完整。

## 可观测性

- 启动埋点上传前后记录本地日志，包括调度、成功、失败原因与地区码。
- 语言安装时记录选中的语言代码与地区码，便于定位用户反馈中的语言异常。

## 回滚策略

- 删除 `AppLaunchEvent` 相关入口与记录构建。
- 移除 `AppLanguageManager` 安装逻辑，恢复系统默认语言选择。
- 保留新增语言资源文件不影响运行，但可随回滚一并移除。
