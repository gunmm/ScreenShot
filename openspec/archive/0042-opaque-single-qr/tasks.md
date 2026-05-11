# Tasks: 单个二维码入口改为直接展示

> 规则：任务必须**可执行、可验证、可按顺序完成**。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（`openspec/changes/.../specs/`）
- [x] 更新技术方案（`design.md`）
- [x] 实现代码（`LongScreenShot/ViewController.swift` 调整二维码底板为不透明）
- [ ] 自测（手工步骤 + 预期结果）
- [x] 同步主规格（`openspec/specs/`）
- [x] 归档（移动到 `openspec/archive/`）

## 已执行验证

- [x] `get_errors` 检查 `LongScreenShot/ViewController.swift`，无新增 Swift 诊断错误
- [x] `xcodebuild -project LongScreenShot.xcodeproj -scheme LongScreenShot -sdk iphoneos CODE_SIGNING_ALLOWED=NO build` 通过

## 自测步骤（手工）

- [ ] Step 1: 非 Pro 生成长图，确认文字仍然斜向平铺。
- [ ] Step 2: 确认图中二维码位于右下角且不再是半透明底板。
