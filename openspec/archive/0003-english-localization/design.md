# Design: English Localization Adaptation

## 现状（As-is）

- 现有项目可能硬编码了中文字符串或者仅有 Base 语言配置，未提供完整的英文多语言适配。

## 方案（To-be）

- **总体思路**：利用 iOS 的官方多语言机制进行适配。
- **模块与职责**：
  - 各个 View/ViewController 职责不变，仅将直接赋值的中文字符串变更为 `NSLocalizedString` (或 SwiftUI 下的等效机制)。
  - 新增/配置 `Localizable.strings` 文件，维护具体的英文翻译映射。
- **数据流**：UI 加载时，iOS 底层根据系统环境自动映射对应的英文资源。

## 接口/数据结构变更

- 变更为使用资源 key。例如：`"保存"` -> `NSLocalizedString("Save", comment: "")` 或包装的方法。

## 兼容性与迁移

- 老用户不受影响（维持中文），新/海外用户自动适配环境语言。无需数据迁移。

## 可观测性

- 注意开发阶段英文过长导致的UI截断，必要时开启自动换行或调整字号。

## 回滚策略

- 通过代码版本控制系统直接回滚语言文件和代码替换相关的 commits。
