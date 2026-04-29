# Proposal: 同步本地化 key 并清理废弃翻译

## 背景 / 动机

- 当前代码里已经新增了主页导出、编辑入口、反馈、评分、打赏、马赛克编辑等多处本地化 key，但三份 Localizable.strings 没有同步更新。
- 现有 strings 文件里仍保留了旧版付费与编辑流程的 key，例如“编辑”“去解锁”“放弃免费使用时间”等，和当前 UI 已经脱节。
- 这会导致英文环境下部分新入口直接回退成中文，也会让本地化资源持续堆积无效条目。

## 目标（Goals）

- G1: 当前代码中实际使用的 NSLocalizedString key 在 Base、zh-Hans、en 三份 Localizable.strings 中都存在映射。
- G2: 已被 UI 和代码移除的废弃 key 从 strings 文件中删除，避免继续维护死数据。
- G3: 英文文案覆盖新增入口、导出、评分、反馈、打赏和马赛克编辑场景。

## 非目标（Non-goals）

- NG1: 本次不把当前仍为硬编码的中文文案整体改造成 NSLocalizedString。
- NG2: 本次不调整支付、反馈、编辑等功能本身的业务逻辑。
- NG3: 本次不修改 InfoPlist.strings 或其他非 Localizable.strings 资源。

## 范围（Scope）

- 会改的部分：
  - 文件/模块：三份 Localizable.strings、OpenSpec 变更文档、主本地化规格。
  - 行为变化：英文环境下新增 UI 文案能够正确显示英文；旧 key 不再继续残留在资源文件中。
- 不会改的部分：
  - Swift 代码里的业务逻辑与页面结构。
  - 仍未接入 NSLocalizedString 的历史硬编码文案。

## 需求概要

- 项目当前实际使用的本地化 key 必须在所有已发货语言包中齐备。
- 主页新增的“视频演示”“拼接调整”“涂抹/打码”“去水印”等入口需要有英文翻译。
- 导出、反馈、评分、打赏、马赛克页的新增提示和按钮文案需要有英文翻译。
- 已经不再被代码引用的旧 key 需要从 strings 文件删除。

## 验收标准（Acceptance Criteria）

- AC1: 代码中当前使用的新增 key 均能在 Base、zh-Hans、en 的 Localizable.strings 中找到对应条目。
- AC2: 旧版未使用 key（如“编辑”“去解锁”“放弃免费使用时间”等）不再出现在三份 strings 文件中。
- AC3: 英文环境下，主页新增入口、反馈提交、导出格式选择、评分提示、马赛克控制项可显示英文文案。

## 风险与回滚

- 风险：若 key 文本与代码字面量不完全一致，运行时仍会回退到源码字符串。
- 回滚方案：恢复三份 Localizable.strings 与主规格到变更前版本，并移除本次 OpenSpec 变更目录。