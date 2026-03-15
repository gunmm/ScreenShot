# Tasks: 修复中文系统下显示英文的本地化回退问题

> 规则：任务必须**可执行、可验证、可按顺序完成**。完成一项打勾一项。

## 实施清单

- [ ] 1. 更新/新增规格：建立 `openspec/changes/0003-fix-localization/specs/localization.md`
- [ ] 2. 确认技术方案：完成设计与任务的书写，并交由审查
- [ ] 3. 准备执行文件拷贝：
  - 创建 `LongScreenShot/zh-Hans.lproj`
  - 拷贝 `Localizable.strings` 从 Base 到 zh-Hans
- [ ] 4. 修改 Xcode 项目配置：使用脚本或者直接修改以注册新的 `zh-Hans` 语言。
- [ ] 5. 自测验证：在模拟器/真机切换中/英文检查显示情况。
- [ ] 6. 同步主规格与归档。

## 自测步骤（手工）

- [ ] Step 1: 将测试系统语言设置为简体中文，启动 App，检查主界面按钮是否为中文("开始录制")。
- [ ] Step 2: 将系统语言设置回英文，启动 App，检查是否正常显示为英文("Start Recording")。
