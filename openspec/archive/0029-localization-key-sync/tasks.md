# Tasks: 同步本地化 key 并清理废弃翻译

> 规则：任务必须可执行、可验证、可按顺序完成。完成一项打勾一项。

## 实施清单

- [x] 更新/新增规格（openspec/changes/0029-localization-key-sync/specs/）
- [x] 更新技术方案（design.md）
- [x] 实现资源修改（同步 Base、zh-Hans、en 的 Localizable.strings）
- [x] 自测（strings 文件格式检查 + 聚焦差异校验）
- [x] 同步主规格（openspec/specs/）
- [x] 归档（移动到 openspec/archive/）

## 自测步骤（手工）

- [x] Step 1: 检查三份 Localizable.strings 没有新增格式错误。
- [x] Step 2: 核对新增 key 已进入 Base、zh-Hans、en 三份文件。
- [x] Step 3: 核对废弃 key 已从三份文件删除。