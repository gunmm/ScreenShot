# Tasks: English Localization Adaptation

> 规则：任务必须**可执行、可验证、可按顺序完成**。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（`openspec/changes/0003-english-localization/specs/localization.md`）
- [x] 更新技术方案（`design.md`）
- [x] 在项目中添加 `en.lproj` 目录及 `Localizable.strings` / `InfoPlist.strings`
- [x] 全局搜索硬编码的中文文案，提取出来翻译成英文
- [x] 实现代码：将业务代码中的中文字符串替换为支持多语言的加载方式
- [x] 检查并翻译权限请求内容（比如相册访问权限提示）
- [x] 自测（手工步骤 + 预期结果）
- [ ] 同步主规格（`openspec/specs/`）
- [ ] 归档（移动到 `openspec/archive/`）

## 自测步骤（手工）

- [x] Step 1: 将模拟器语言设置为英文，启动应用，确认各级页面均无中文泄漏。
- [x] Step 2: 测试核心操作，观察是否有文案过长导致的UI异常。
- [x] Step 3: 将系统语言切回中文验证是否仍然正常显示中文。
