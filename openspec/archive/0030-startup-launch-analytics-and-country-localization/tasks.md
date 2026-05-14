# Tasks: 启动埋点与国家语言适配

> 规则：任务必须**可执行、可验证、可按顺序完成**。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（`openspec/changes/.../specs/feedback-log.md`、`openspec/changes/.../specs/localization.md`）
- [x] 更新技术方案（`design.md`）
- [x] 实现启动 CloudKit 记录上传（`AppDelegate.swift`、`CloudKitManager.swift`）
- [x] 实现地区码语言切换逻辑（新增 `AppLanguageManager.swift`）
- [x] 将核心硬编码文案迁移到本地化资源（设置、打赏、支付相关页面）
- [x] 补齐 `ja.lproj`、`ko.lproj` 语言资源，并更新工程语言区域
- [x] 自测（文件级错误检查 + 设备 SDK 编译）
- [x] 同步主规格（`openspec/specs/feedback-log.md`、`openspec/specs/localization.md`）
- [x] 归档（移动到 `openspec/archive/`）

## 自测步骤（手工）

- [ ] Step 1: 将设备/模拟器地区分别切换到美国、日本、韩国、中国，确认设置页与打赏/购买相关核心文案切到对应语言。
- [ ] Step 2: 启动 App，检查 CloudKit Public Database 中生成一条 `AppLaunchEvent` 记录，字段完整。
- [ ] Step 3: 关闭网络或故意让 CloudKit 失败，确认 App 仍能正常进入主界面且无弹窗错误。
