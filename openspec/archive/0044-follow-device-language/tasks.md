# Tasks: 跟随设备语言而非地区码切换本地化

## 实施清单

- [x] 更新变更规格（`specs/localization.md`）
- [x] 删除启动阶段的自定义语言安装逻辑
- [x] 删除 `AppLanguageManager.swift` 并调整 `CloudKitManager` 的 `regionCode` 来源
- [x] 同步主规格（`openspec/specs/localization.md`）
- [x] 文件级校验与设备 SDK 编译验证
- [x] 归档变更

## 自测步骤（手工）

- [ ] Step 1: 将手机语言切换为日语，确认 App 文案切到日语。
- [ ] Step 2: 保持非日本地区，确认仍然按手机语言显示日语。
- [ ] Step 3: 启动 App，确认 CloudKit 启动记录仍有 `regionCode` 字段。
