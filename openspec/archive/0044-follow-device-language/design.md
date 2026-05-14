# Design: 跟随设备语言而非地区码切换本地化

## 现状（As-is）

- `AppDelegate` 在启动时调用 `AppLanguageManager.install()`。
- `AppLanguageManager` 会替换 `Bundle.main` 的本地化读取逻辑，并按地区码强制选择语言包。
- 这会覆盖 iOS 默认的按用户首选语言选本地化行为。

## 方案（To-be）

- 删除 `AppLanguageManager` 的调用与实现。
- 恢复系统默认的 `NSLocalizedString` 解析流程，由 iOS 根据当前设备语言和已提供的 `lproj` 自动选择。
- 启动埋点中的 `regionCode` 改为在 `CloudKitManager` 内直接读取 `Locale.current`，不再依赖已删除的语言管理器。

## 接口/数据结构变更

- 删除 `AppLanguageManager.install()` 启动调用。
- 删除 `AppLanguageManager.swift`。
- `CloudKitManager` 新增本地 `currentRegionCode` 计算属性，继续提供 `regionCode` 埋点值。

## 兼容性与迁移

- 已存在的多语言资源保持不变。
- 无数据迁移需求。

## 可观测性

- 启动埋点日志继续记录 `regionCode`。

## 回滚策略

- 恢复 `AppLanguageManager.swift` 与启动调用即可回滚到地区码强制选择逻辑。
