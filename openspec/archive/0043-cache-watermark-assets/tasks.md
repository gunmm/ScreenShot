# Tasks: 缓存水印文字 tile 与二维码图

> 规则：任务必须**可执行、可验证、可按顺序完成**。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（`openspec/changes/.../specs/`）
- [x] 更新技术方案（`design.md`）
- [x] 实现代码（`LongScreenShot/ViewController.swift` 增加 tile/二维码缓存）
- [ ] 自测（手工步骤 + 预期结果）
- [x] 同步主规格（`openspec/specs/`）
- [x] 归档（移动到 `openspec/archive/`）

## 已执行验证

- [x] `get_errors` 检查 `LongScreenShot/ViewController.swift`，无新增 Swift 诊断错误
- [x] `xcodebuild -project LongScreenShot.xcodeproj -scheme LongScreenShot -sdk iphoneos CODE_SIGNING_ALLOWED=NO build` 通过

## 自测步骤（手工）

- [ ] Step 1: 非 Pro 重复生成同一张长图，确认表现不变。
- [ ] Step 2: 保存图片到相册，确认文字平铺与二维码仍正确显示。
