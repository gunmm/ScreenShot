# Design: 保存成功后的自动日志上传

## 现状（As-is）

- `ViewController.image(_:didFinishSavingWithError:contextInfo:)` 是保存成功后的唯一主回调。
- `CloudKitManager.uploadFeedback` 当前固定写入 `UserFeedback` 记录，并附带 `AppLogger` 的当前日志文件。
- 项目尚无针对自动日志上传的限流状态，也没有独立的自动上传 record type。

## 方案（To-be）

- **总体思路**：
  - 在保存成功回调里新增一个 fire-and-forget 调用，仅在成功分支触发。
  - 由 `CloudKitManager` 统一封装自动上传逻辑，包括 24 小时限流判断、日志快照生成和 `AutoLogUpload` 记录保存。
  - 保持用户反馈上传逻辑不变，但抽出公共字段组装和记录保存能力，避免两套字段定义漂移。

- **模块与职责**：
  - `ViewController`
    - 在保存成功后触发自动上传检查。
    - 不等待上传结果，不展示上传 UI。
  - `CloudKitManager`
    - 提供自动上传入口。
    - 负责读取和更新“上次自动上传时间”。
    - 复用统一字段组装逻辑，生成 `AutoLogUpload` 记录。
    - 为上传创建日志快照文件，避免直接引用正在写入的原始日志文件。
  - `UserDefaults`
    - 持久化上次自动上传时间戳，用于 24 小时限流。

## 数据流

1. 用户保存长截图成功。
2. `ViewController` 记录保存成功日志并展示现有成功提示。
3. 同时触发 `CloudKitManager` 自动上传检查。
4. `CloudKitManager` 读取本地上次自动上传时间；若未满 24 小时则直接返回。
5. 若满足条件，复制当前日志文件为临时快照文件。
6. 以 `AutoLogUpload` 为 record type，组装与 `UserFeedback` 一致的字段并上传。
7. 上传成功后刷新本地上次自动上传时间；失败则只写本地日志。
8. 上传完成后清理临时日志快照文件。

## 接口/数据结构变更

- `CloudKitManager` 新增：
  - 自动上传入口，例如 `uploadAutoLogIfNeeded()`。
  - 公共记录构造辅助方法，用于复用反馈上传和自动上传字段。
  - 本地限流键，例如 `lastAutoLogUploadAt`。
- 新增 CloudKit record type：`AutoLogUpload`。
- `message` 固定写入自动事件标识，例如 `save_success_auto_upload`，用于和手动反馈区分。

## 关键算法/阈值

- 限流阈值固定为 24 小时。
- 仅在上传成功后更新“上次自动上传时间”，避免失败导致长时间静默。
- 日志文件使用快照副本上传，避免与 `AppLogger` 写句柄并发冲突。

## 兼容性与迁移

- 老版本没有 `lastAutoLogUploadAt` 时，首次保存成功将允许上传。
- 不需要迁移现有 `UserFeedback` 数据结构。

## 可观测性

- 本地日志新增自动上传触发、跳过、成功、失败和快照清理结果，便于排查限流和上传问题。

## 回滚策略

- 若自动上传引发云端成本或稳定性问题，可删除保存成功回调中的调用入口，并移除 `AutoLogUpload` 上传逻辑。