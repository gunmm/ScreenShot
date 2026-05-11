# Tasks: 降低平铺二维码视觉存在感

> 规则：任务必须**可执行、可验证、可按顺序完成**。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（`openspec/changes/.../specs/`）
- [x] 更新技术方案（`design.md`）
- [x] 实现代码（`LongScreenShot/ViewController.swift` 调整二维码尺寸与容器样式）
- [ ] 自测（手工步骤 + 预期结果）
- [x] 同步主规格（`openspec/specs/`）
- [x] 归档（移动到 `openspec/archive/`）

## 已执行验证

- [x] `get_errors` 检查 `LongScreenShot/ViewController.swift`，无新增 Swift 诊断错误
- [x] `xcodebuild -project LongScreenShot.xcodeproj -scheme LongScreenShot -sdk iphoneos CODE_SIGNING_ALLOWED=NO build` 通过

## 自测步骤（手工）

- [ ] Step 1: 非 Pro 生成长图，确认二维码较上一版更不显眼。
- [ ] Step 2: 尝试扫码，确认二维码仍可识别。
