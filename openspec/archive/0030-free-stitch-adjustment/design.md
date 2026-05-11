# Design: 拼接调整改为免费能力

## 现状（As-is）

- `ViewController.handleEditCompletion(...)` 在拼接调整完成后会检查 Pro 状态。
- 未购买用户点击完成时会触发 `presentProPaywall(... gate: .applyStitchAdjustment ...)`，只有购买成功后才应用新的裁剪结果。
- 主页“拼接调整”按钮带有 Pro 角标，统一 Pro 权益列表也包含“拼接调整”。

## 方案（To-be）

- **总体思路**：
  - 将拼接调整视为免费基础能力，移除“完成应用结果”阶段的 Pro 校验。
  - 同时移除主页入口和统一会员权益列表中的拼接调整 Pro 表达，保持策略与文案一致。
- **模块与职责**：
  - `ViewController`
    - 主页拼接调整入口不再显示 Pro 角标。
    - 拼接调整完成后直接关闭编辑页并应用新的裁剪结果。
  - `ProAccessCoordinator`
    - 删除拼接调整对应的付费场景和权益列表文案。
  - `ProPaywallViewController`
    - 权益列表中不再渲染“拼接调整”。
- **数据流**：
  1. 用户进入拼接调整页并调整裁剪区间。
  2. 点击完成后，主页直接 dismiss 编辑页。
  3. 主页后台重新拼接并更新结果图。
  4. 其他 Pro 场景继续沿用现有弹窗与购买续流逻辑。

## 接口/数据结构变更

- 删除 `ProFeatureGate.applyStitchAdjustment`。
- `ViewController.handleEditCompletion(...)` 不再依赖 Pro 状态分支，统一直接应用结果。

## 关键算法/阈值

- 无算法变更，仅调整权限判断分支。

## 兼容性与迁移

- 不涉及数据持久化或用户迁移。
- 已购买用户行为保持不变；未购买用户只是少一道付费拦截。

## 可观测性

- 保留拼接调整完成的日志，但不再记录对应的 Pro gate。

## 回滚策略

- 恢复 `ProFeatureGate.applyStitchAdjustment`、主页角标和完成时的付费校验即可。