# 多语言本地化规格

## 核心规则
1. App 必须提供对应多语言的显式本地化包（如 `zh-Hans.lproj`, `en.lproj`），而不能单独依赖 `Base.lproj` 存放某种特定语言导致回退逻辑异常。
2. 基础开发语言（Development Language）与项目结构需保持一致，若开发默认定为英文，则必须提供明确的中文资源包，供中文环境的系统正确匹配。
3. 当前代码里实际使用的 `NSLocalizedString` key 必须在所有 shipped 的 `Localizable.strings` 中存在映射，不能只补某一个语言包。
4. 当 UI 或流程删除旧文案后，对应的废弃 key 应从 shipped 的 `Localizable.strings` 中清理，避免资源与实现长期背离。

## 适用系统
- iOS / iPadOS
