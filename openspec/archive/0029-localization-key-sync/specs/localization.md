# Specs: 同步本地化 key 并清理废弃翻译

## 场景
当项目新增或删除本地化 UI 文案时，资源文件必须和当前代码中的 NSLocalizedString key 保持一致，避免英文环境回退中文，也避免保留已经无效的翻译项。

## 需求
1. 当前代码里实际使用的 NSLocalizedString key，必须同时存在于 Base.lproj、zh-Hans.lproj、en.lproj 的 Localizable.strings 中。
2. 新增的主页入口、导出、反馈、评分、打赏、马赛克编辑相关 key，必须具备英文翻译。
3. 已经不再被代码引用的旧 key，必须从 shipped 的 Localizable.strings 中删除。
4. 新旧 key 同步时，不得改变现有功能逻辑或页面结构。

## 边界
1. 本次仅覆盖已经接入 NSLocalizedString 的文案，不要求把所有历史硬编码字符串一并抽取。
2. Base.lproj 与 zh-Hans.lproj 当前都承载中文值，本次保持现状，不调整开发语言结构。
3. 多行提示文案允许继续使用源码字符串作为 key，但 strings 文件中的 key 必须与运行时字面量一致。