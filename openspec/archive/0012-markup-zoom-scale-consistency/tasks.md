# Tasks: Markup 缩放边界一致性修复

## 实施清单

- [x] 更新/新增规格（`openspec/changes/.../specs/`）
- [x] 更新技术方案（`design.md`）
- [x] 实现代码（统一 `MarkupViewController.swift` 的缩放边界来源）
- [x] 文件级校验（`get_errors` 检查 `MarkupViewController.swift`）
- [ ] 自测（手工步骤 + 预期结果）
- [x] 同步主规格（`openspec/specs/`）
- [x] 归档（移动到 `openspec/archive/`）

## 自测步骤（手工）

- [ ] Step 1: 打开一张长图进入“涂鸦/打码”，连续缩小到最小值并确认底图与笔迹层边界一致。
- [ ] Step 2: 连续放大到最大值并确认底图与笔迹层边界一致。
- [ ] Step 3: 触发布局刷新后重复缩放，确认边界未漂移。