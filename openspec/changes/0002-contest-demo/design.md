# Design: 初赛 Demo 最小闭环（产品化增强）

## 现状（As-is）

- 主流程存在但偏“按钮堆叠”，缺少清晰引导与可分享闭环：
  - 开始录制依赖系统 `RPSystemBroadcastPickerView`
  - 生成长图后仅支持保存相册
  - 失败与降级提示偏技术化

## 方案（To-be）

### 1) 信息架构（最小新增）

- 主界面分为 3 个阶段（状态驱动）：
  1. **录制前**：展示“如何录制”的引导卡片 + 开始录制入口
  2. **录制中/录制后**：提示“去目标 App 滚动，完成后回到本 App 点生成”
  3. **生成后**：预览结果 + 行为按钮（分享 / 保存 / 重新生成）

> 实现方式：在 `ViewController` 中引入显式状态枚举（例如 `Idle/Recording/ReadyToGenerate/Generating/Generated/Failed`），集中管理按钮 enable 与文案。

### 2) 分享导出（Share Sheet）

- 生成成功后提供“分享”按钮：
  - 使用 `UIActivityViewController` 分享图片
  - 分享数据源使用临时文件（写入 `NSTemporaryDirectory()`）或直接传 `UIImage`
  - 成功/取消无需提示，失败需提示（例如无法写临时文件）

### 3) 结果“惊艳”策略（后续变更）

本次初赛 Demo 先聚焦“主流程顺滑 + 一键分享”，不引入裁边/编辑能力，避免误裁导致演示翻车。
后续可考虑：

- 结果历史（最近 3 次）
- 基础编辑（裁边、马赛克等）

### 4) 失败/降级提示（可诊断）

统一错误类型：

- **NoChunks**：未录到任何 chunk
- **StitchFailed**：拼接返回 nil
- **PermissionDenied**：相册权限拒绝
- **Degraded**：检测到某些相邻匹配失败，采取安全回退（可能出现重复）

在 UI 上表现为：

- 状态 label 显示“可行动建议”（例如：重新录制、滚动更连续、避免动态内容）
- Debug 入口保留（Preview Chunks）方便自测

## 需要修改/新增的模块（预计）

- `LongScreenShot/ViewController.swift`
  - 引入状态机、分享按钮、引导 UI
- `LongScreenShot/Main/ChunksPreviewViewController.swift`
  - 可选：增加“从生成页跳转预览”入口或自动刷新

## 回滚策略

- 分享按钮为可选 UI：出现问题可直接隐藏入口并恢复旧流程
- 不改变 App Group 与 chunk 文件格式，确保回滚不会破坏已录制数据

