# Tasks: 语言跟随设备当前偏好

> 规则：任务必须**可执行、可验证、可按顺序完成**。完成一项打勾一项。

## 实施清单

- [ ] 更新/新增规格（`openspec/changes/.../specs/localization.md`）
- [ ] 更新技术方案（`design.md`）
- [ ] 修改 `AppLanguageManager.swift`，将语言选择改为设备语言优先
- [ ] 文件级错误检查
- [ ] 设备 SDK 编译校验
- [ ] 同步主规格（`openspec/specs/localization.md`）
- [ ] 归档（移动到 `openspec/archive/`）

## 自测步骤（手工）

- [ ] Step 1: 保持地区为中国，仅将设备语言切为日语，确认 App 显示日语。
- [ ] Step 2: 保持地区不变，分别切到韩语、英语、简体中文，确认 App 跟随变化。
- [ ] Step 3: 将设备语言切为未支持语种，确认 App 安全回退。
