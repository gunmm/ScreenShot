# Design: 语言跟随设备当前偏好

## 现状（As-is）

- `AppLanguageManager` 当前先读取地区码，再根据 `US/JP/KR/CN` 映射语言。
- 当用户只修改系统语言、不修改地区时，地区码映射会覆盖用户真实语言偏好。
- 这会导致例如“地区=CN，语言=ja”时，App 仍显示简体中文。

## 方案（To-be）

- **总体思路**：
  - 移除 UI 语言对地区码的依赖。
  - 优先读取设备语言偏好列表，选出应用支持的首个语言。
  - 若设备语言列表中无支持项，再回退到 bundle 推荐结果，最终兜底英文。

- **模块与职责**：
  - `AppLanguageManager`：负责解析设备语言偏好、匹配支持语言并安装 bundle 覆盖逻辑。
  - `CloudKitManager`：继续使用地区码作为埋点字段，不参与 UI 语言决策。

- **数据流**：
  1. App 启动进入 `didFinishLaunchingWithOptions`。
  2. `AppLanguageManager.install()` 读取 `Locale.preferredLanguages` 与 `Bundle.main.preferredLocalizations`。
  3. 从中匹配 `en`、`ja`、`ko`、`zh-Hans` 之一。
  4. 将对应 lproj bundle 关联到 `Bundle.main`，后续 `NSLocalizedString` 读取该 bundle。

## 接口/数据结构变更

- `AppLanguageManager`
  - `resolvedLanguageCode` 改为不依赖地区码输入。
  - 新增或调整对设备语言偏好列表的解析。

## 关键算法/阈值

- 选择优先级：
  1. `Locale.preferredLanguages`
  2. `Bundle.main.preferredLocalizations`
  3. 英文兜底
- 语言归一化规则保持不变：`zh* -> zh-Hans`、`ja* -> ja`、`ko* -> ko`、`en* -> en`。

## 兼容性与迁移

- 不需要迁移旧数据。
- 已有 `ja/ko/en/zh-Hans` 资源可直接复用。

## 可观测性

- 启动日志中记录设备语言列表、选中语言和地区码，便于排查语言选择问题。

## 回滚策略

- 恢复地区码优先的映射逻辑。
- 恢复本地化规格中对地区码优先的描述。
