# Design: 同步本地化 key 并清理废弃翻译

## 现状（As-is）

- 项目使用基于源码字符串的 NSLocalizedString 方案，Base、zh-Hans、en 三份 Localizable.strings 负责提供映射。
- 最近多次功能迭代在 ViewController、SettingsViewController、FeedbackViewController、MarkupEntryViewController、MosaicViewController 等位置新增了 UI 文案。
- strings 文件没有跟随迭代同步，导致新增 key 缺失、旧 key 残留。

## 方案（To-be）

- 总体思路：
  - 以当前 Swift 代码里实际使用的 NSLocalizedString key 为唯一真相来源。
  - 统一重写三份 Localizable.strings，保留当前仍在使用的 key，补齐缺失映射，删除废弃项。
  - 同步主规格，明确“已使用 key 必须覆盖，废弃 key 应清理”的维护规则。
- 模块与职责：
  - Localizable.strings：承载 Base、简体中文、英文三套映射。
  - openspec/specs/localization.md：沉淀本地化资源维护约束。
- 数据流：
  1. 从 Swift 代码提取当前使用的 NSLocalizedString key。
  2. 与现有 strings 文件对比，识别缺失和废弃条目。
  3. 更新三份 strings 文件，保证每个在用 key 都有值。
  4. 更新主规格，要求后续功能迭代同步维护本地化 key 集。

## 接口/数据结构变更

- 无接口变更。
- 仅更新资源映射表内容。

## 关键算法/阈值

- 无算法变更。
- 保持源码字符串作为 key，不引入新的枚举或集中常量层。

## 兼容性与迁移

- 不涉及持久化数据迁移。
- 已发货语言包继续沿用 Base、zh-Hans、en 的结构。

## 可观测性

- 本次不新增日志。
- 验证方式以 strings 文件差集检查和文件级诊断为主。

## 回滚策略

- 若发现 key 对不上或英文文案存在问题，可整体回退三份 strings 文件和本次规格更新。