# Tasks: Markup 缩放边界禁用回弹

## 实施清单

- [x] 更新/新增规格（`openspec/changes/.../specs/`）
- [x] 更新技术方案（`design.md`）
- [x] 实现代码（关闭 `MarkupViewController.swift` 的缩放回弹）
- [x] 文件级校验（`get_errors` 检查 `MarkupViewController.swift`）
- [x] 同步主规格（`openspec/specs/`）
- [ ] 自测（手工步骤 + 预期结果）
- [x] 归档（移动到 `openspec/archive/`）

## 自测步骤（手工）

- [ ] Step 1: 进入“涂鸦/打码”页，缩小到最小值后继续双指缩小，确认无回弹。
- [ ] Step 2: 放大到最大值后继续双指放大，确认无回弹。
- [ ] Step 3: 观察底图与笔迹层在边界处的反馈是否一致。